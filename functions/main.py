from firebase_functions.firestore_fn import (
    Change,
    DocumentSnapshot,
    Event,
    on_document_written,
)
from firebase_functions.logger import info
from google.api_core.exceptions import NotFound
from google.cloud import tasks_v2
from google.protobuf import timestamp_pb2
from datetime import datetime, timedelta, timezone

PROJECT_ID = "nutmeg-9099c"
LOCATION_ID = "europe-west1"
QUEUE_ID = "match-notifications"
BASE_URL = "https://nutmeg-9099c.ew.r.appspot.com"


def _schedule_app_engine_call(
    task_name: str,
    endpoint: str,
    date_time_to_execute: datetime,
    method: tasks_v2.HttpMethod = tasks_v2.HttpMethod.GET,
) -> None:
    client = tasks_v2.CloudTasksClient()
    parent = client.queue_path(PROJECT_ID, LOCATION_ID, QUEUE_ID)

    schedule_time = timestamp_pb2.Timestamp()
    schedule_time.FromDatetime(date_time_to_execute)

    task = {
        "http_request": {
            "http_method": method,
            "url": f"{BASE_URL}/{endpoint}",
            "headers": {"Content-type": "application/json"},
        },
        "schedule_time": schedule_time,
        "name": client.task_path(PROJECT_ID, LOCATION_ID, QUEUE_ID, task_name),
    }
    client.create_task(request={"parent": parent, "task": task})


def _schedule_match_tasks(
    match_id: str,
    match_data: dict,
    is_test: bool,
) -> list[str]:
    tasks_scheduled: list[str] = []
    current_epoch_str = str(int(datetime.now(tz=timezone.utc).timestamp()))
    qs = "?is_test=true" if is_test else ""
    date_time = match_data.get("dateTime")
    duration = int(match_data.get("duration", 0))

    if not isinstance(date_time, datetime):
        raise ValueError("dateTime missing or invalid on match document")

    cancel_hours_before = match_data.get("cancelHoursBefore")
    if isinstance(cancel_hours_before, (int, float)):
        cancellation_time = date_time - timedelta(hours=cancel_hours_before)

        task_name = f"cancel_or_confirm_match_{match_id}_{current_epoch_str}"
        _schedule_app_engine_call(
            task_name=task_name,
            endpoint=f"matches/{match_id}/confirm{qs}",
            date_time_to_execute=cancellation_time,
        )
        tasks_scheduled.append(task_name)

        task_name = (
            f"send_pre_cancellation_organizer_notification_{match_id}_{current_epoch_str}"
        )
        _schedule_app_engine_call(
            task_name=task_name,
            endpoint=f"matches/{match_id}/tasks/precancellation{qs}",
            date_time_to_execute=cancellation_time - timedelta(hours=1),
        )
        tasks_scheduled.append(task_name)

    task_name = f"close_rating_round_{match_id}_{current_epoch_str}"
    _schedule_app_engine_call(
        task_name=task_name,
        endpoint=f"matches/{match_id}/stats/freeze{qs}",
        method=tasks_v2.HttpMethod.POST,
        date_time_to_execute=date_time + timedelta(minutes=duration) + timedelta(days=1),
    )
    tasks_scheduled.append(task_name)

    task_name = f"send_prematch_notification_{match_id}_{current_epoch_str}"
    _schedule_app_engine_call(
        task_name=task_name,
        endpoint=f"matches/{match_id}/tasks/prematch{qs}",
        date_time_to_execute=date_time - timedelta(hours=1),
    )
    tasks_scheduled.append(task_name)

    task_name = f"run_post_match_tasks_{match_id}_{current_epoch_str}"
    _schedule_app_engine_call(
        task_name=task_name,
        endpoint=f"matches/{match_id}/tasks/postmatch{qs}",
        date_time_to_execute=date_time + timedelta(minutes=duration) + timedelta(hours=1),
    )
    tasks_scheduled.append(task_name)

    price_data = match_data.get("price")
    is_manual_payment = bool(match_data.get("isManualPayment"))
    if isinstance(price_data, dict) and not is_manual_payment:
        task_name = f"release_match_money_{match_id}_{current_epoch_str}"
        _schedule_app_engine_call(
            task_name=task_name,
            endpoint=f"matches/{match_id}/tasks/release{qs}",
            date_time_to_execute=date_time
            + timedelta(minutes=duration)
            + timedelta(hours=24),
        )
        tasks_scheduled.append(task_name)

    return tasks_scheduled


def _schedule_tasks_for_created_match(
    snapshot: DocumentSnapshot | None,
    match_id: str | None,
    is_test: bool,
) -> None:
    if snapshot is None or not match_id:
        return

    match_data = snapshot.to_dict() or {}
    if match_data.get("tasksScheduled"):
        return

    tasks_scheduled = _schedule_match_tasks(match_id, match_data, is_test)
    snapshot.reference.update({"tasksScheduled": tasks_scheduled})
    info(
        "Scheduled Cloud Tasks for new match",
        {
            "matchId": match_id,
            "collection": "matches_test" if is_test else "matches",
            "tasksCount": len(tasks_scheduled),
        },
    )


def _delete_scheduled_tasks(snapshot: DocumentSnapshot | None, match_id: str | None) -> None:
    if snapshot is None:
        return

    match_data = snapshot.to_dict() or {}
    raw_tasks = match_data.get("tasksScheduled", [])
    if not isinstance(raw_tasks, list) or not raw_tasks:
        info(
            "No scheduled tasks to delete for match",
            {
                "matchId": match_id,
            },
        )
        return

    client = tasks_v2.CloudTasksClient()
    deleted_count = 0

    for task_name in raw_tasks:
        if not isinstance(task_name, str) or not task_name:
            continue

        # `tasksScheduled` stores task IDs, but accept full task paths too.
        task_path = (
            task_name
            if task_name.startswith("projects/")
            else client.task_path(PROJECT_ID, LOCATION_ID, QUEUE_ID, task_name)
        )

        try:
            client.delete_task(name=task_path)
            deleted_count += 1
        except NotFound:
            # Task may have already run or been removed.
            info(
                "Task already missing while cleaning up",
                {"matchId": match_id, "task": task_name},
            )
        except Exception as exc:
            info(
                "Failed deleting scheduled task",
                {"matchId": match_id, "task": task_name, "error": str(exc)},
            )

    info(
        "Finished scheduled task cleanup for deleted match",
        {"matchId": match_id, "deletedCount": deleted_count, "totalTasks": len(raw_tasks)},
    )


def _handle_match_document_written(
    event: Event[Change[DocumentSnapshot | None]],
    collection: str,
) -> None:
    match_id = event.params.get("matchId")
    before = event.data.before
    after = event.data.after

    operation = "update"
    if before is None and after is not None:
        operation = "create"
        _schedule_tasks_for_created_match(
            after,
            match_id,
            is_test=(collection == "matches_test"),
        )
    elif before is not None and after is None:
        operation = "delete"
        _delete_scheduled_tasks(before, match_id)

    info(
        "Match document trigger fired",
        {
            "collection": collection,
            "matchId": match_id,
            "operation": operation,
        },
    )


@on_document_written(document="matches/{matchId}")
def on_match_document_written(
    event: Event[Change[DocumentSnapshot | None]],
) -> None:
    _handle_match_document_written(event, "matches")


@on_document_written(document="matches_test/{matchId}")
def on_match_test_document_written(
    event: Event[Change[DocumentSnapshot | None]],
) -> None:
    _handle_match_document_written(event, "matches_test")

