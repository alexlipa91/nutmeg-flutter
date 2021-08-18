from google.cloud import firestore
import os

cred = "/Users/alessandrol/workspace/nutmeg-flutter/data-upload-utils/nutmeg-9099c-firebase-adminsdk-ozsy6-a5d6c6d538.json"
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = cred

db = firestore.Client(
    project="nutmeg-9099c",
)

# fields
name = 'name'
neigh = 'neighbourhood'
address = 'address'
tags = 'tags'

sportCenters = {
    "ChIJ3zv5cYsJxkcRAr4WnAOlCT4": {
        name: 'Sportcentrum De Pijp',
        neigh: 'De Pijp',
        address: 'Lizzy Ansinghstraat 88, 1072 RD Amsterdam',
        tags: ['indoor']
    },
    "ChIJM6a0ddoJxkcRsw7w54kvDD8": {
        name: 'Het Marnix',
        neigh: 'West',
        address: 'Marnixplein 1, 1015 ZN Amsterdam',
        tags: ['indoor']
    }}

for k, v in sportCenters.items():
    # Add a new document
    doc_ref = db.collection(u'sport_centers').document(k)
    doc_ref.set(v)
