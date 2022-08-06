import 'package:cloud_firestore/cloud_firestore.dart';


class MiscFirestore {

  static var _ref = FirebaseFirestore.instance.collection('misc');

  static Future<Map<String, dynamic>?> getDocument(String id) async {
    var ds = await _ref.doc(id).get();
    return ds.data();
  }
}
