class Match {
  int id;
  DateTime dateTime;
  SportCenter sportCenter;
  String sport;
  double price;
  List<String> joining;
  int total;

  Match(this.id, this.dateTime, this.sportCenter, this.sport, this.total, this.joining, this.price);
}

class SportCenter {
  String name;
  double lat;
  double long;

  SportCenter(this.name, this.lat, this.long);
}

class User {
  String email;
  String password;

  User(this.email, this.password);
}