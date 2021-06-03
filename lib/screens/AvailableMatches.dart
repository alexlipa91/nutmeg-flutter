import 'package:flutter/material.dart';
import 'package:nutmeg/models/Model.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/models/MatchesModel.dart';
import 'package:nutmeg/models/UserModel.dart';
import 'package:nutmeg/screens/MatchDetails.dart';
import 'package:provider/provider.dart';

import '../Utils.dart';

class AvailableMatches extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => AvailableMatchesState();
}

class AvailableMatchesState extends State<AvailableMatches> {
  bool allFilterIsOn = true;

  @override
  Widget build(BuildContext context) {
    print("Building " + this.runtimeType.toString());

    return SafeArea(
        child: Container(
      decoration: new BoxDecoration(color: Colors.grey.shade400),
      child: Scaffold(
          backgroundColor: Palette.green,
          appBar: getAppBar(context),
          body: Scaffold(
            backgroundColor: Palette.lightGrey,
            body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20)),
                      ),
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
                            ChangeNotifierProvider(
                              create: (_) =>
                                  new FilterButtonState(FilterOption.ALL),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FilterButton(
                                        filterOption: FilterOption.ALL,
                                        isLeft: true),
                                    FilterButton(
                                        filterOption: FilterOption.GOING,
                                        isLeft: false),
                                  ]),
                            )
                          ],
                        ),
                      )),
                  Expanded(child: RefreshIndicatorStateful()),
                ]),
          )),
    ));
  }
}

enum FilterOption { ALL, GOING }

class FilterButtonState with ChangeNotifier {
  FilterOption selectedOption;

  FilterButtonState(this.selectedOption);

  changeTo(FilterOption f) {
    selectedOption = f;
    notifyListeners();
  }
}

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

class RefreshIndicatorStateful extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => RefreshIndicatorState();
}

class RefreshIndicatorState extends State<RefreshIndicatorStateful>
    with WidgetsBindingObserver {
  static var dateFormat = new DateFormat("MMMM dd");

  _getMatchesWidget(Map<String, Match> matches) {
    var groupedByDay = Map<DateTime, List<String>>.fromEntries([]);
    for (var m in matches.entries) {
      var day = DateTime(
          m.value.dateTime.year, m.value.dateTime.month, m.value.dateTime.day);

      var current = [];
      if (groupedByDay.containsKey(day)) {
        current = groupedByDay[day];
      }
      current.add(m.key);
      groupedByDay[day] = List<String>.from(current);
    }

    var widgets = [];
    for (var day in groupedByDay.keys.toList()..sort()) {
      widgets.add(Padding(
        padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        child: Text(dateFormat.format(day),
            style: TextStyle(
                color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w400)),
      ));
      widgets.add(new MatchInfoGroup(
          matches: groupedByDay[day].map((e) => MatchInfo(e)).toList()));
    }

    return List<Widget>.from(widgets);
  }

  AppLifecycleState _appLifecycleState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _appLifecycleState = state;
    });
    if (_appLifecycleState == AppLifecycleState.resumed) {
      refresh();
    }
  }

  Future<void> refresh() async {
    try {
      await context.read<MatchesModel>().pull();
    } on Exception catch (err) {
      print("Caught in refresh " + err.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
        onRefresh: () async => await refresh(),
        child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(8),
            children:
                _getMatchesWidget(context.watch<MatchesModel>().getMatches())));
  }
}

class MatchInfoGroup extends StatelessWidget {
  final List<MatchInfo> matches;

  const MatchInfoGroup({Key key, this.matches}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.transparent),
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Column(
        children: matches,
      ),
    );
  }
}

class MatchInfo extends StatelessWidget {
  static var formatCurrency = new NumberFormat.simpleCurrency(name: "EUR");

  String matchId;

  MatchInfo(this.matchId);

  @override
  Widget build(BuildContext context) {
    Match match = context.watch<MatchesModel>().getMatch(matchId);

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
                  Text(DateFormat('HH:mm').format(match.dateTime),
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
                  Text(match.sportCenter.name,
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w500)),
                  SizedBox(height: 10),
                  Text(formatCurrency.format(match.pricePerPerson),
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 18,
                          fontWeight: FontWeight.w500))
                ],
              ),
              Spacer(),
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
                        match.joining.length.toString() +
                            "/" +
                            match.maxPlayers.toString(),
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w400))),
              ),
            ],
          ),
        ),
      ),
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => MatchDetails(matchId)));
      },
      splashColor: Colors.white,
    );
  }
}
