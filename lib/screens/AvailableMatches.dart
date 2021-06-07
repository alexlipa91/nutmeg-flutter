import 'package:flutter/material.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/models/Model.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/models/MatchesModel.dart';
import 'package:nutmeg/models/SubscriptionsModel.dart';
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
    print(context.read<FilterButtonState>().selectedOption);

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
                  Expanded(
                      child: RefreshIndicatorStateful()),
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

class RefreshIndicatorStateful extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => RefreshIndicatorState();
}

class RefreshIndicatorState extends State<RefreshIndicatorStateful>
    with WidgetsBindingObserver {
  static var dateFormat = new DateFormat("MMMM dd");

  _getMatchesWidget(Iterable<Match> matches) {
    var groupedByDay = Map<DateTime, List<Match>>.fromEntries([]);
    for (var m in matches) {
      var day = DateTime(
          m.dateTime.year, m.dateTime.month, m.dateTime.day);

      var current = [];
      if (groupedByDay.containsKey(day)) {
        current = groupedByDay[day];
      }
      current.add(m);
      groupedByDay[day] = List<Match>.from(current);
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
      await context.read<MatchesModel>().update();
    } on Exception catch (err) {
      print("Caught in refresh " + err.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Building " + this.runtimeType.toString());

    var filterOption = context.watch<FilterButtonState>().selectedOption;

    var matches = context.watch<MatchesModel>().getMatches();
    var user = context.watch<UserModel>().getUser();
    var subs = context.watch<SubscriptionsBloc>().getSubscriptions();

    var mainWidget = (filterOption == FilterOption.GOING &&
            !context.read<UserModel>().isLoggedIn())
        ? Center(
          child: Text("Login to join matches", style: TextStyle(
              color: Colors.grey, fontSize: 24, fontWeight: FontWeight.w400)),
        )
        : RefreshIndicator(
            onRefresh: () async => await refresh(),
            child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(8),
                children: _getMatchesWidget((filterOption == FilterOption.GOING)
                    ? MatchesController.getUserMatches(matches, subs, user)
                    : matches)));

    // todo animate it
    return mainWidget;
  }
}

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

  MatchInfo(this.match);

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
                            color: Colors.grey.shade50,
                            fontSize: 12,
                            fontWeight: FontWeight.w400))),
              )
            ],
          ),
        ),
      ),
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => MatchDetails(match.id)));
      },
      splashColor: Colors.white,
    );
  }
}
