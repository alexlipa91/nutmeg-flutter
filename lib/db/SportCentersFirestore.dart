import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/SportCenter.dart';


class SportCentersFirestore {

  static Future<List<SportCenter>> getSportCenters() async {
    var subscriptionsRef = await FirebaseFirestore.instance
        .collection('sport_centers')
        .withConverter<SportCenter>(
          fromFirestore: (snapshot, _) =>
              SportCenter.fromJson(snapshot.data(), snapshot.id),
          // toFirestore: (sub, _) => _,
        )
        .get();

    return subscriptionsRef.docs.map((e) => e.data()).toList();
  }
}
