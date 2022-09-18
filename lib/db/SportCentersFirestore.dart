import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/SportCenter.dart';


class SportCentersFirestore {

  static Future<List<SavedSportCenter>> getSportCenters() async {
    var subscriptionsRef = await FirebaseFirestore.instance
        .collection('sport_centers')
        .withConverter<SavedSportCenter>(
          fromFirestore: (snapshot, _) =>
              SavedSportCenter.fromJson(snapshot.data(), snapshot.id),
          toFirestore: (sub, _) => {},
        )
        .get();

    return subscriptionsRef.docs.map((e) => e.data()).toList();
  }
}
