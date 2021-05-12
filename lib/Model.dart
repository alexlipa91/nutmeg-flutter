class Match {
  DateTime dateTime;
  SportCenter sportCenter;
  String sport;
  double price;
  int total;
  int joined;

  Match(this.dateTime, this.sportCenter, this.sport, this.total, this.joined, this.price);
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