import 'package:nutmeg/Model.dart';

var users = [
  new User("rob.doeg@gmail.com", "rob123")
];

class _Authentication {

  String user;

  static var _auth = new _Authentication();

  static String getLoggedInUser() {
    return _auth.user;
  }

  static bool login(String email, String password) {
    var exists = users.where((e) => e.email == email && e.password == password).isNotEmpty;
    _auth.user = email;
    return exists;
  }
}

