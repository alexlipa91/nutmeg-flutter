enum MatchStatus { open, played, canceled }

enum Sport { fiveAsideFootball }

class Match {
  DateTime dateTime;
  SportCenter sportCenter;
  Sport sport;
  double pricePerPerson;
  List<String> joining;
  int maxPlayers;
  MatchStatus status;

  Match(this.dateTime, this.sportCenter, this.sport, this.maxPlayers,
      this.joining, this.pricePerPerson, this.status);

  toJson() {
    return {
      "datetime": dateTime,
      "sportCenter": sportCenter
    };
  }
}

class SportCenter {
  String placeId;

  SportCenter(this.placeId);

  String getName() {
    return "namePlaceholder";
  }
}