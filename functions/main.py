from firebase_functions.firestore_fn import (
    Change,
    DocumentSnapshot,
    Event,
    on_document_written,
)
from firebase_functions.logger import info
from google.api_core.exceptions import NotFound
from google.cloud import tasks_v2

PROJECT_ID = "nutmeg-9099c"
LOCATION_ID = "europe-west1"
QUEUE_ID = "match-notifications"


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


@on_document_written(document="matches/{matchId}")
def on_match_document_written(
    event: Event[Change[DocumentSnapshot | None]],
) -> None:
    match_id = event.params.get("matchId")
    before = event.data.before
    after = event.data.after

    operation = "update"
    if before is None and after is not None:
        operation = "create"
    elif before is not None and after is None:
        operation = "delete"
        _delete_scheduled_tasks(before, match_id)

    info(
        "Match document trigger fired",
        {
            "matchId": match_id,
            "operation": operation,
        },
    )
