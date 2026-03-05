from firebase_functions.firestore_fn import (
    Change,
    DocumentSnapshot,
    Event,
    on_document_written,
)
from firebase_functions.logger import info


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

    info(
        "Match document trigger fired",
        {
            "matchId": match_id,
            "operation": operation,
        },
    )
