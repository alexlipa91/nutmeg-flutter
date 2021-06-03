import 'package:intl/intl.dart';
import '../Utils.dart';

enum MatchStatus { open, played, canceled }

enum SportCenterTags { indoor, outdoor }

enum Sport { fiveAsideFootball }

extension SportExtension on Sport {
  String getDisplayTitle() {
    switch (this) {
      case Sport.fiveAsideFootball:
        return "5-aside-football";
      default:
        return "";
    }
  }
}

class Match {
  static var serializationDateFormat = new DateFormat("yyyy/MM/dd:HH:mm");
  static var uiDateFormat = new DateFormat("yyyy-MM-dd");
  static var uiHourFormat = new DateFormat("HH:mm");

  DateTime dateTime;
  SportCenter sportCenter;
  Sport sport;
  double pricePerPerson;
  List<String> joining;
  int maxPlayers;
  MatchStatus status;

  Match(this.dateTime, this.sportCenter, this.sport, this.maxPlayers,
      this.joining, this.pricePerPerson, this.status);

  Match.fromJson(Map<String, dynamic> json)
      : dateTime = serializationDateFormat.parse(json['dateTime']),
        sportCenter = SportCenter.fromJson(json['sportCenter']),
        sport = Sport.values[json['sport']],
        pricePerPerson = json['pricePerPerson'],
        joining = List<String>.from(json['joining']),
        maxPlayers = json['maxPlayers'],
        status = MatchStatus.values[json['status']];

  Map<String, dynamic> toJson() => {
        'dateTime': serializationDateFormat.format(dateTime),
        'sportCenter': sportCenter.toJson(),
        'sport': sport.index,
        'pricePerPerson': pricePerPerson,
        'joining': joining,
        'maxPlayers': maxPlayers,
        'status': status.index
      };

  String getFormattedDate() {
    return (isSameDay(DateTime.now(), dateTime)
            ? "Today"
            : uiDateFormat.format(dateTime)) +
        " at " +
        uiHourFormat.format(dateTime);
  }

  int getSpotsLeft() => maxPlayers - joining.length;
}

class SportCenter {
  // todo store them in the db
  static List<SportCenter> getSportCenters() {
    return [
      SportCenter(
          "ChIJ3zv5cYsJxkcRAr4WnAOlCT4",
          "Sportcentrum De Pijp",
          "Lizzy Ansinghstraat 88, 1072 RD Amsterdam",
          [SportCenterTags.indoor]),
      SportCenter("ChIJM6a0ddoJxkcRsw7w54kvDD8", "Het Marnix",
          "Marnixplein 1, 1015 ZN Amsterdam", [SportCenterTags.indoor]),
      SportCenter("ChIJYVFYYbrTxUcRMSYDU4GLg5k", "Sportcentrum Zuidplas", null,
          [SportCenterTags.indoor])
    ];
  }

  String placeId;
  String name;
  String address;
  List<SportCenterTags> tags;

  SportCenter(this.placeId, this.name, this.address, this.tags);

  SportCenter.fromId(String id) {
    var toFind =
        SportCenter.getSportCenters().where((element) => element.placeId == id);
    if (toFind.isEmpty) {
      throw Exception("Sport center with id " + id + " not found");
    }
    var sportCenterObject = toFind.first;

    this.placeId = sportCenterObject.placeId;
    this.name = sportCenterObject.name;
  }

  Map<String, dynamic> toJson() => {'placeId': placeId, 'name': name};

  SportCenter.fromJson(Map<String, dynamic> json)
      : placeId = json['placeId'],
        name = json['name'];

  String getTags() => (tags == null)
      ? null
      : tags.map((e) => e.toString().split('.').last).join(", ");

  String getName() => name;

  bool operator ==(dynamic other) =>
      other != null && other is SportCenter && this.placeId == other.placeId;

  @override
  int get hashCode => super.hashCode;
}

class UserDetails {
  bool isAdmin;
  String image;
  String name;

  UserDetails(this.isAdmin, this.image, this.name);

  UserDetails.fromJson(Map<String, dynamic> json)
      : isAdmin = json["isAdmin"] ?? false,
        image = json["image"],
        name = json["name"];

  Map<String, dynamic> toJson() => {'isAdmin': isAdmin, 'image': image, 'name': name};
}
