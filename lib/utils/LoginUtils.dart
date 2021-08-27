import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';


class Authentication {
  static Future<FirebaseApp> initializeFirebase({BuildContext context}) async {
    FirebaseApp firebaseApp = await Firebase.initializeApp();
    return firebaseApp;
  }
}
