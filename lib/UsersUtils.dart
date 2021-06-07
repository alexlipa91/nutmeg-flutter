import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutmeg/models/Model.dart';

class UsersUtils {
  static CollectionReference<User> users = FirebaseFirestore.instance.collection('users')
      .withConverter<User>(
      fromFirestore: (snapshot, _) =>
          User.fromJson(snapshot.id, snapshot.data()),
      toFirestore: (user, _) => user.toJson());

  static Future<User> getUser(String uid) =>
      users.doc(uid).get().then((value) => value.data());
}