import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/screens/MatchDetails.dart';
import 'package:nutmeg/utils/LocationUtils.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/AppBar.dart';
import 'package:provider/provider.dart';
import 'package:week_of_year/week_of_year.dart';
import "package:collection/collection.dart";

enum FilterOption { ALL, GOING }

// main widget (stateful)
class AvailableMatches extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => AvailableMatchesState();
}

class AvailableMatchesState extends State<AvailableMatches> {
  bool allFilterIsOn = true;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Container(
      decoration: new BoxDecoration(color: Colors.grey.shade400),
      child: Scaffold(
          backgroundColor: Palette.green,
          appBar: CustomAppBar(),
          body: Scaffold(
            backgroundColor: Palette.lightGrey,
            body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                      decoration: topBoxDecoration,
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Find football matches near",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400)),
                            SizedBox(height: 10),
                            Text("Amsterdam",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 42,
                                    fontWeight: FontWeight.w800)),
                            SizedBox(height: 10),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FilterButton(
                                      filterOption: FilterOption.ALL,
                                      isLeft: true),
                                  FilterButton(
                                      filterOption: FilterOption.GOING,
                                      isLeft: false),
                                ])
                          ],
                        ),
                      )),
                  Expanded(child: RefreshIndicatorStateful()),
                ]),
          )),
    ));
  }
}

// widget for all/going filter button + change notifier
class FilterButton extends StatelessWidget {
  final FilterOption filterOption;
  final isLeft;

  static var onTextStyle = TextStyle(
      color: Colors.green.shade700, fontSize: 18, fontWeight: FontWeight.w300);
  static var offTextStyle =
      TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w300);

  const FilterButton({Key key, this.isLeft, this.filterOption})
      : super(key: key);

  getBorderRadius() => (isLeft)
      ? BorderRadius.only(
          topLeft: Radius.circular(10.0), bottomLeft: Radius.circular(10.0))
      : BorderRadius.only(
          topRight: Radius.circular(10.0), bottomRight: Radius.circular(10.0));

  getOnStyle() => TextButton.styleFrom(
      backgroundColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 55.0),
      shape: RoundedRectangleBorder(
          side: BorderSide(width: 1.0, color: Colors.white),
          borderRadius: getBorderRadius()));

  getOffStyle() => TextButton.styleFrom(
      backgroundColor: Colors.transparent,
      padding: EdgeInsets.symmetric(horizontal: 55.0),
      shape: RoundedRectangleBorder(
          side: BorderSide(width: 1.0, color: Colors.white),
          borderRadius: getBorderRadius()));

  @override
  Widget build(BuildContext context) {
    // fixme make the size fixed and not depending on text of the button otherwise GOING is bigger
    return TextButton(
        onPressed: () =>
            context.read<FilterButtonState>().changeTo(filterOption),
        child: Text(filterOption.toString().split('.').last,
            style: context.watch<FilterButtonState>().selectedOption ==
                    filterOption
                ? onTextStyle
                : offTextStyle),
        style: context.watch<FilterButtonState>().selectedOption == filterOption
            ? getOnStyle()
            : getOffStyle());
  }
}

class FilterButtonState with ChangeNotifier {
  FilterOption selectedOption;

  FilterButtonState(this.selectedOption);

  changeTo(FilterOption f) {
    selectedOption = f;
    notifyListeners();
  }
}

// widget with list of matches
class RefreshIndicatorStateful extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => RefreshIndicatorState();
}

class RefreshIndicatorState extends State<RefreshIndicatorStateful>
    with WidgetsBindingObserver {
  static var dateFormat = new DateFormat("MMMM dd");

  // creates widgets splitting by week
  _getMatchesWidget(List<Match> matches, LocationData locationData) {
    var currentWeek = DateTime.now().weekOfYear;
    var groups = matches.groupListsBy((m) => m.dateTime.weekOfYear);

    var weekTitles = {
      currentWeek: "This week",
      currentWeek + 1: "Next week",
    };

    var widgets = [];
    for (var week in groups.keys.toList()..sort()) {
      widgets.add(Padding(
        padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        child: Text(weekTitles[week] ?? "More than two weeks",
            style: TextStyle(
                color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w400)),
      ));
      widgets.add(new MatchInfoGroup(
          matches: groups[week]
              .map((e) => MatchInfo.withLocation(e, locationData))
              .toList()));
    }

    return List<Widget>.from(widgets);
  }

  AppLifecycleState _appLifecycleState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    setState(() {
      _appLifecycleState = state;
    });
    if (_appLifecycleState == AppLifecycleState.resumed) {
      // fixme when resuming refresh list of matches
      context.read<MatchesChangeNotifier>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    var matches = context.watch<MatchesChangeNotifier>().getMatches();
    var filterOption = context.watch<FilterButtonState>().selectedOption;

    var mainWidget = (filterOption == FilterOption.GOING &&
            !context.read<UserChangeNotifier>().isLoggedIn())
        ? Center(
            child: Text("Login to join matches",
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 24,
                    fontWeight: FontWeight.w400)),
          )
        : RefreshIndicator(
            onRefresh: () async {
              await context.read<MatchesChangeNotifier>().refresh();
              await context.read<LocationChangeNotifier>().refresh();
            },
            child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(8),
                children: _getMatchesWidget(
                    (filterOption == FilterOption.GOING)
                        ? matches
                            .where((m) => m.isUserGoing(context
                                .read<UserChangeNotifier>()
                                .getUserDetails()))
                            .toList()
                        : matches,
                    context.read<LocationChangeNotifier>().locationData)));
    // todo animate it
    return mainWidget;
  }
}

// single match info widgets
class MatchInfoGroup extends StatelessWidget {
  final List<MatchInfo> matches;

  const MatchInfoGroup({Key key, this.matches}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(10),
      decoration: infoMatchDecoration,
      child: Column(
        children: matches,
      ),
    );
  }
}

class MatchInfo extends StatelessWidget {
  static var formatCurrency = NumberFormat.simpleCurrency(name: "EUR");
  static var monthDayFormat = DateFormat('HH:mm');

  Match match;
  LocationData locationData;

  MatchInfo(this.match);

  MatchInfo.withLocation(this.match, this.locationData);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Text(monthDayFormat.format(match.dateTime),
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w400))
                ],
              ),
              SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(match.sport.getDisplayTitle(),
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  SizedBox(height: 10),
                  Text(
                      context
                          .read<SportCentersChangeNotifier>()
                          .getSportCenter(match.sportCenter)
                          .name,
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w500)),
                  SizedBox(height: 10),
                  Text(formatCurrency.format(match.getPrice()),
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 18,
                          fontWeight: FontWeight.w500)),
                ],
              ),
              Spacer(),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                    decoration: new BoxDecoration(
                      color: Colors.red.shade300,
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      border: new Border.all(
                        color: Colors.white70,
                        width: 0.5,
                      ),
                    ),
                    child: Padding(
                        padding: EdgeInsets.all(5),
                        child: Text(
                            match.numPlayersGoing().toString() +
                                "/" +
                                match.maxPlayers.toString(),
                            style: TextStyle(
                                color: Colors.grey.shade50,
                                fontSize: 12,
                                fontWeight: FontWeight.w400))),
                  ),
                  SizedBox(height: 40),
                  if (locationData != null)
                    FutureBuilder<String>(
                        future: LocationUtils.getDistanceInKm(
                            locationData.latitude,
                            locationData.longitude,
                            match.sportCenter),
                        builder: (BuildContext context,
                            AsyncSnapshot<String> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            return Text(snapshot.data,
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500));
                          }
                          return Text("");
                        })
                ],
              )
            ],
          ),
        ),
      ),
      onTap: () async {
        // fixme why it doesn't rebuild here?
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => MatchDetails(context
                    .watch<MatchesChangeNotifier>()
                    .getMatch(match.documentId))));
        await context.read<MatchesChangeNotifier>().refresh();
      },
      splashColor: Colors.white,
    );
  }
}
