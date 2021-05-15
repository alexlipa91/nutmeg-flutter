import 'package:flutter/cupertino.dart';
import 'package:nutmeg/Model.dart';

var users = [
  new User("rob.doeg@gmail.com", "rob123"),
  new User("u", "p")
];

class UserModel extends ChangeNotifier {

  String name = null;

  bool login(String email, String password) {
    var exists = users.where((e) => e.email == email && e.password == password).isNotEmpty;
    name = email;
    print("notifying");
    notifyListeners();
    return exists;
  }
}

