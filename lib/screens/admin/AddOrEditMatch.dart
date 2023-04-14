import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:provider/provider.dart';

import '../../model/Match.dart';
import '../../state/MatchesState.dart';
import '../PlayerOfTheMatch.dart';

// main widget
class AdminMatchDetails extends StatefulWidget {

  final String matchId;

  const AdminMatchDetails({Key? key, required this.matchId}) : super(key: key);

  @override
  State<StatefulWidget> createState() => AdminMatchDetailsState();
}

class AdminMatchDetailsState extends State<AdminMatchDetails> {

  Future<void> refreshState() async {
    // get details
    var futures = [
      context.read<MatchesState>().fetchMatch(widget.matchId),
      context.read<MatchesState>().fetchRatings(widget.matchId)
    ];

    var result = await Future.wait(futures);

    var m = result[0] as Match;

    // get users details
    m.getGoingUsersByTime().map((e) => context.read<UserState>().fetchUserDetails(e));
  }

  @override
  void initState() {
    super.initState();
    refreshState();
  }

  @override
  Widget build(BuildContext context) {
    Match? match = context.watch<MatchesState>().getMatch(widget.matchId);

    return Scaffold(
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          backgroundColor: Colors.transparent,
          centerTitle: false,
          automaticallyImplyLeading: false,
          leadingWidth: 0,
          elevation: 0,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // SizedBox(width: 16,), // we cannot pad outside
              InkWell(
                  splashColor: Palette.grey_lighter,
                  child: Container(
                    width: 50,
                    height: 50,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(Icons.arrow_back,
                          color: Colors.black, size: 25.0),
                    ),
                  ),
                  onTap: () => Navigator.of(context).pop())
            ],
          ),
        ),
        body: (match == null) ? Container() : Container(
          color: Palette.grey_lightest,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Column(children: [
              Expanded(
                child: AddOrEditMatchForm(match: match),
              )
            ]),
          ),
        ));
  }
}

class AddOrEditMatchForm extends StatefulWidget {
  final Match match;

  const AddOrEditMatchForm({Key? key, required this.match}) : super(key: key);

  @override
  State<StatefulWidget> createState() => AddOrEditMatchFormState();
}

class AddOrEditMatchFormState extends State<AddOrEditMatchForm> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var ratings = context.watch<MatchesState>().getRatings(widget.match.documentId);

    // utility
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          child: ListView(
            scrollDirection: Axis.vertical,
            primary: false,
            shrinkWrap: true,
            children: [
              SelectableText("Match id: " + widget.match.documentId, style: TextPalette.h2),
              SizedBox(height: 16.0),
              Text("Status is: " + widget.match.status.toString().split(".").last,
                  style: TextPalette.h2),
              SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                      child: GenericButtonWithLoader("CANCEL MATCH",
                          (BuildContext context) async {
                    context.read<GenericButtonWithLoaderState>().change(true);
                    var shouldCancel = await CoolAlert.show(
                      context: context,
                      type: CoolAlertType.confirm,
                      text: "This is going to cancel the match with id: \n" +
                          widget.match.documentId +
                          "\nAre you sure?",
                      onConfirmBtnTap: () => Navigator.of(context).pop(true),
                      onCancelBtnTap: () => Navigator.of(context).pop(false),
                    );

                    if (shouldCancel) {
                      try {
                        await MatchesController.cancelMatch(widget.match.documentId);
                        GenericInfoModal(title: "Successfully canceled match")
                            .show(context);
                      } catch (e, stack) {
                        print(e);
                        print(stack);
                        GenericInfoModal(title: "Something went wrong")
                            .show(context);
                      }
                    }
                    context.read<GenericButtonWithLoaderState>().change(false);
                  }, Destructive()))
                ],
              ),
              if (widget.match.status == MatchStatus.rated)
                Column(
                    children: (ratings?.potms ?? [])
                        .map((e) => Row(children: [
                              Builder(builder: (BuildContext context) {
                                var ud =
                                    context.watch<UserState>().getUserDetail(e);
                                if (ud == null) return Container();

                                return Expanded(
                                    child: GenericButtonWithLoader(
                                        "POTM SCREEN: " + (ud.name ??
                                            "PLAYER").toUpperCase(),
                                        (BuildContext context) async {
                                          Navigator.push(context,
                                              MaterialPageRoute(builder: (context) =>
                                              PlayerOfTheMatch(userId: ud.documentId)));
                                        },
                                        Primary()));
                              })
                            ]))
                        .toList()),
              // VoteStats(match: widget.match),
              SizedBox(height: 16),
            ],
          ),
        ));
  }
}

