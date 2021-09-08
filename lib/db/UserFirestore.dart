import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../model/Model.dart';


class UserFirestore {

  static CollectionReference users = FirebaseFirestore.instance.collection('users');
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<UserDetails> getSpecificUserDetails(String uid) async {
    var doc = await users.doc(uid).get();
    Map<String, dynamic> data = doc.data();
    return (data == null) ? null : UserDetails.fromJson(data, uid);
  }

  static Future<void> storeUserDetails(UserDetails userDetails) =>
      users.doc(userDetails.documentId).set(userDetails.toJson());

  static Future<void> logout() async => await _auth.signOut();

  static storeStripeId(String uid, String stripeId) async =>
      await users.doc(uid).update({"stripeId": stripeId});

  static User getCurrentFirestoreUser() => _auth.currentUser;
}
