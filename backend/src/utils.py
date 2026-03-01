import logging
import json
from datetime import datetime

import google.api_core.datetime_helpers
import stripe
from firebase_admin import messaging
from google.cloud import tasks_v2
from google.protobuf import timestamp_pb2

from src.secrets import Secrets

# Nutmeg platform fee in cents charged per player per match
NUTMEG_FEE_CENTS = 50

BASE_URL = "https://app.nutmegplay.com"


def setup_stripe(is_test=False):
    """Set the global Stripe API key for test or live mode."""
    stripe.api_key = Secrets.STRIPE_KEY_TEST_ES if is_test else Secrets.STRIPE_KEY_ES


def _serialize_dates(data):
    for k in data:
        if type(data[k]) == dict:
            data[k] = _serialize_dates(data[k])
        elif type(data[k]) == google.api_core.datetime_helpers.DatetimeWithNanoseconds:
            data[k] = datetime.isoformat(data[k])
    return data


def delete_task(task_name):
    client = tasks_v2.CloudTasksClient()
    project = "nutmeg-9099c"
    location = "europe-west1"
    queue = "match-notifications"
    client.delete_task(name=client.task_path(project, location, queue, task_name))


def schedule_app_engine_call(
    task_name,
    endpoint,
    date_time_to_execute,
    function_payload=None,
    method=tasks_v2.HttpMethod.GET,
):
    # schedule task
    client = tasks_v2.CloudTasksClient()

    project = "nutmeg-9099c"
    queue = "match-notifications"
    location = "europe-west1"
    url = f"https://nutmeg-9099c.ew.r.appspot.com/{endpoint}"

    parent = client.queue_path(project, location, queue)

    # Create Timestamp protobuf.
    timestamp = timestamp_pb2.Timestamp()
    timestamp.FromDatetime(date_time_to_execute)

    # Construct the request body.
    task = {
        "http_request": {  # Specify the type of request.
            "http_method": method,
            "url": url,  # The full url path that the task will be sent to.
            "headers": {"Content-type": "application/json"},
        },
        "schedule_time": timestamp,
        "name": client.task_path(project, location, queue, task_name),
    }
    if function_payload:
        task["http_request"]["body"] = json.dumps({"data": function_payload}).encode()

    # Use the client to build and send the task.
    response = client.create_task(request={"parent": parent, "task": task})
    print(
        f"Created task {response.name} to call {endpoint} with params {function_payload} at {date_time_to_execute}"
    )


def send_notification_to_users(db, title, body, data, users):

    for user_id in users:
        try:
            user_data = (
                db.collection("users")
                .document(user_id)
                .get(field_paths={"tokens"})
                .to_dict()
            )
        except Exception as e:
            logging.error(f"Error fetching user {user_id}: {e}")
            continue

        if not user_data:
            logging.warning(f"User {user_id} not found, skipping")
            continue

        tokens = user_data.get("tokens", [])
        if not tokens:
            continue

        messages = [
            messaging.Message(
                notification=messaging.Notification(title=title, body=body),
                data=data,
                token=t,
            )
            for t in tokens
        ]

        response = messaging.send_each(messages)

        # Clean up stale tokens
        stale_tokens = []
        for i, send_response in enumerate(response.responses):
            if send_response.success:
                logging.info(f"Notification sent to {tokens[i][:20]}...")
            elif isinstance(send_response.exception, (
                messaging.UnregisteredError,
                messaging.SenderIdMismatchError,
            )):
                logging.warning(f"Token {tokens[i][:20]}... is stale, removing")
                stale_tokens.append(tokens[i])
            else:
                logging.error(
                    f"Error sending to {tokens[i][:20]}...: {send_response.exception}"
                )

        if stale_tokens:
            from google.cloud.firestore_v1 import ArrayRemove

            db.collection("users").document(user_id).update(
                {"tokens": ArrayRemove(stale_tokens)}
            )


def update_leaderboard(app, leaderboard_id, match_list, updates_map):
    print(f"updating leaderboard {leaderboard_id}")
    cache_user_data = {u: _get_user_basic_data(app, u) for u in updates_map.keys()}
    app.db_client.collection("leaderboards").document(leaderboard_id).set(
        {
            "entries": updates_map,
            "cache_user_data": cache_user_data,
            "matches": {match_id: True for match_id in match_list},
        },
        merge=True,
    )


def _get_user_basic_data(app, u):
    return (
        app.db_client.collection("users")
        .document(u)
        .get(field_paths={"name", "image"})
        .to_dict()
    )


def send_test_notification(db):
    # send to admin a test notification
    send_notification_to_users(
        db, "test", "test", {}, ["IwrZWBFb4LZl3Kto1V3oUKPnCni1"]
    )


if __name__ == "__main__":
    import sys
    import os
    import firebase_admin
    from firebase_admin import firestore

    sa_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "nutmeg-9099c-firebase-adminsdk.json")
    if os.path.exists(sa_path):
        os.environ.setdefault("GOOGLE_APPLICATION_CREDENTIALS", sa_path)

    firebase_admin.initialize_app()
    db = firestore.client()

    # Default to the admin user, or pass a user ID as argument
    user_id = sys.argv[1] if len(sys.argv) > 1 else "IwrZWBFb4LZl3Kto1V3oUKPnCni1"

    print(f"Sending test notification to user: {user_id}")
    send_notification_to_users(db, "Nutmeg Test", "If you see this, notifications work!", {}, [user_id])
    print("Done!")
