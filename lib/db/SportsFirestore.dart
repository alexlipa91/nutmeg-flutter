import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutmeg/model/Model.dart';


class SportsDb {

  static Future<List<Sport>> getSports() async {
    var sportsRef = await FirebaseFirestore.instance
        .collection('sports')
        .withConverter<Sport>(
      fromFirestore: (snapshot, _) =>
          Sport.fromJson(snapshot.data(), snapshot.id),
      // toFirestore: (sub, _) => _,
    ).get();

    return sportsRef.docs.map((e) => e.data()).toList();
  }
}
