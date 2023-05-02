import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../screens/CreateMatch.dart';
import '../screens/MatchDetails.dart';
import '../state/MatchesState.dart';
import '../state/UserState.dart';
import '../utils/UiUtils.dart';
import '../utils/Utils.dart';
import 'Avatar.dart';
import 'ButtonsWithLoader.dart';
import 'Containers.dart';
import 'ModalBottomSheet.dart';
import 'PlayerBottomModal.dart';

class TeamsWidget extends StatefulWidget {
  final String matchId;

  const TeamsWidget({Key? key, required this.matchId}) : super(key: key);

  @override
  State<StatefulWidget> createState() => TeamsWidgetState();
}

enum TeamsWidgetScoreState { add, edit, submit }

class TeamsWidgetState extends State<TeamsWidget> {
  final _scoreFormKey = GlobalKey<FormState>();

  late bool isOrganizerView;
  late bool manualSplit;
  bool loader = false;
  bool? movingItemFromLeft;

  List<FocusNode> focusNodes = [FocusNode(), FocusNode()];

  @override
  void initState() {
    super.initState();
    var match = context.read<MatchesState>().getMatch(widget.matchId);
    manualSplit = match?.hasManualTeams ?? false;
    isOrganizerView = context.read<UserState>().isLoggedIn() &&
        context.read<UserState>().currentUserId ==
            context.read<MatchesState>().getMatch(widget.matchId)?.organizerId;
  }

  getTeamColumn(BuildContext context, MainAxisAlignment alignment,
      List<List<String>> teams, int index) {
    var draggable = manualSplit &&
        context
            .watch<MatchesState>()
            .getMatch(widget.matchId)!
            .canUserModifyTeams(context.read<UserState>().currentUserId);

    var isLeftColumn = MainAxisAlignment.start == alignment;
    var playersWidgets = interleave(
        teams[index].map((e) {
          var ud = context.watch<UserState>().getUserDetail(e);

          var avatar = UserAvatar(16, ud);
          var name = UserNameWidget(userDetails: ud);
          var userRow = SizedBox(
            height: 32,
            child: LayoutBuilder(builder: (context, constraints) {
              return isLeftColumn
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                          if (draggable)
                            Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(Icons.drag_indicator_outlined,
                                    color: Palette.greyLighter)),
                          avatar,
                          SizedBox(width: 12),
                          name,
                        ])
                  : Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      name,
                      SizedBox(width: 12),
                      avatar,
                      if (draggable)
                        Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.drag_indicator_outlined,
                                color: Palette.greyLighter)),
                    ]);
            }),
          );

          return InkWell(
              onTap: ud == null
                  ? null
                  : () => ModalBottomSheet.showNutmegModalBottomSheet(
                      context, JoinedPlayerBottomModal(ud)),
              child: draggable
                  ? Draggable<String>(
                      child: userRow,
                      feedback: Material(
                        color: Palette.white,
                        borderRadius: InfoContainer.borderRadius,
                        elevation: 1,
                        child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: userRow),
                      ),
                      childWhenDragging: Opacity(
                        child: userRow,
                        opacity: 0.2,
                      ),
                      onDragStarted: () {
                        setState(() {
                          movingItemFromLeft = isLeftColumn;
                        });
                      },
                      onDragEnd: (details) {
                        setState(() {
                          movingItemFromLeft = null;
                        });
                      },
                      data: ud?.documentId)
                  : userRow);
        }).toList(),
        SizedBox(height: 16));

    List<Widget> childrenWidgets = [];
    childrenWidgets.addAll(playersWidgets);

    return DragTarget<String>(
      builder: (context, candidateItems, rejectedItems) {
        var isHighlighted =
            movingItemFromLeft != null && movingItemFromLeft != isLeftColumn;

        return Container(
          decoration: BoxDecoration(
            borderRadius: InfoContainer.borderRadius,
            color: isHighlighted ? Palette.greyLighter : Colors.transparent,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Column(children: childrenWidgets),
          ),
        );
      },
      onWillAccept: (item) {
        var isInFirstTeam = teams[0].contains(item);
        var interested = (isLeftColumn && !isInFirstTeam) ||
            (!isLeftColumn && isInFirstTeam);
        return interested;
      },
      onAccept: (item) {
        context
            .read<MatchesState>()
            .movePlayerToTeam(widget.matchId, item, isLeftColumn ? 0 : 1);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var match = context.watch<MatchesState>().getMatch(widget.matchId)!;

    var teams = (match.hasManualTeams ?? false)
        ? match.manualTeams
        : match.computedTeams;

    var content = Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Center(
          child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Team A",
                style: TextPalette.h2,
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    match.score == null
                        ? Container()
                        : Text(match.score![0].toString(),
                            textAlign: TextAlign.end,
                            style: TextPalette.getStats(Palette.black)),
                    Text("  vs  ", style: TextPalette.bodyText),
                    match.score == null
                        ? Container()
                        : Text(match.score![1].toString(),
                            textAlign: TextAlign.end,
                            style: TextPalette.getStats(Palette.black))
                  ],
                ),
              ),
              Text(
                "Team B",
                style: TextPalette.h2,
              ),
            ],
          ),
          SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: getTeamColumn(
                        context, MainAxisAlignment.start, teams, 0)),
                NutmegDivider(horizontal: false),
                Expanded(
                    child: getTeamColumn(
                        context, MainAxisAlignment.end, teams, 1)),
              ],
            ),
          ),
          if (isOrganizerView)
            Padding(
              padding: EdgeInsets.only(top: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    teams[0].map((u) => context.watch<UserState>()
                        .getUserDetail(u)?.averageScore ?? 3)
                        .fold<double>(0, (a, b) => a + b).toStringAsFixed(2),
                    style: TextPalette.bodyText,
                  ),
                  Expanded(
                    child: Text("Team strength",
                        textAlign: TextAlign.center,
                        style: TextPalette.bodyText),
                  ),
                  Text(
                    teams[1].map((u) => context.watch<UserState>()
                        .getUserDetail(u)?.averageScore ?? 3)
                        .fold<double>(0, (a, b) => a + b).toStringAsFixed(2),
                    style: TextPalette.bodyText,
                  ),
                ],
              ),
            ),
          if (isOrganizerView && match.status != MatchStatus.rated)
            Padding(
              padding: EdgeInsets.only(top: 24),
              child: Column(
                children: [
                  NutmegDivider(horizontal: true),
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Switch(
                            value: manualSplit,
                            activeColor: Palette.primary,
                            onChanged: (v) async {
                              setState(() {
                                manualSplit = v;
                              });
                              await context.read<MatchesState>().editMatch(
                                  widget.matchId,
                                  {"hasManualTeams": manualSplit});
                              if (manualSplit) {
                                await context
                                    .read<MatchesState>()
                                    .storeManualTeams(
                                        widget.matchId,
                                        context
                                            .read<MatchesState>()
                                            .getMatch(widget.matchId)!
                                            .computedTeams);
                              }
                            }),
                        SizedBox(width: 8),
                        Text(
                            AppLocalizations.of(context)!
                                .manualSplitTeamCheckBoxLabel,
                            style: TextPalette.h3),
                        Spacer(),
                        if (loader)
                          CupertinoActivityIndicator(
                            color: Palette.primary,
                          )
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.manualSplitTeamInfo,
                      style: TextPalette.bodyText)
                ],
              ),
            ),
          if (isOrganizerView && match.status == MatchStatus.to_rate)
            Padding(
                padding: EdgeInsets.only(top: 8),
                child: NutmegDivider(horizontal: true)
            ),
          if (isOrganizerView && match.status == MatchStatus.to_rate)
            Padding(
                padding: EdgeInsets.only(top: 8),
                child: EditScoreWidget(matchId: widget.matchId))
        ],
      )),
    );

    return Form(key: _scoreFormKey, child: InfoContainer(child: content));
  }
}

class EditScoreWidget extends StatefulWidget {
  final String matchId;

  const EditScoreWidget({Key? key, required this.matchId}) : super(key: key);

  @override
  State<StatefulWidget> createState() => EditScoreWidgetState();
}

class EditScoreWidgetState extends State<EditScoreWidget> {
  final _scoreFormKey = GlobalKey<FormState>();
  late bool isSubmitMode;
  final controllers = [TextEditingController(), TextEditingController()];

  @override
  void initState() {
    super.initState();
    isSubmitMode =
        context.read<MatchesState>().getMatch(widget.matchId)!.score == null;
    var score = context.read<MatchesState>().getMatch(widget.matchId)!.score;
    if (score != null) {
      controllers[0].text = score[0].toString();
      controllers[1].text = score[1].toString();
    }
  }

  final focusNodes = [FocusNode(), FocusNode()];

  Widget inputScore(int teamIndex) => TextFormField(
        focusNode: focusNodes[teamIndex],
        keyboardType: TextInputType.number,
        controller: controllers[teamIndex],
        validator: (v) {
          if (int.tryParse(v ?? "") == null) return "Invalid";
          return null;
        },
        style: TextPalette.getStats(Palette.black),
        textAlign: teamIndex == 0 ? TextAlign.end : TextAlign.start,
        decoration: CreateMatchState.getTextFormDecoration(
            null,
            hintText: "0",
            hintStyle: TextPalette.getStats(Palette.greyLight)
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _scoreFormKey,
      child: Column(
        children: [
          if (isSubmitMode)
            Column(
              children: [
                Text(
                  AppLocalizations.of(context)!.finalScoreSubmitText,
                  style: TextPalette.h2,
                ),
                SizedBox(
                  height: 16,
                ),
                Row(
                  children: [
                    Expanded(child: inputScore(0)),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text("  vs  ", style: TextPalette.bodyText)),
                    Expanded(child: inputScore(1))
                  ],
                ),
              ],
            ),
          Column(
            children: [
              if (isSubmitMode)
                Row(children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: GenericButtonWithLoaderAndErrorHandling(
                          AppLocalizations.of(context)!.submitScoreButton,
                          (BuildContext context) async {
                        if (_scoreFormKey.currentState!.validate()) {
                          var score = [
                            int.parse(controllers[0].text),
                            int.parse(controllers[1].text),
                          ];
                          await context
                              .read<MatchesState>()
                              .editMatch(widget.matchId, {"score": score});
                          setState(() {
                            isSubmitMode = false;
                          });
                        }
                      }, Primary()),
                    ),
                  ),
                ]),
              if (!isSubmitMode)
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: GenericButtonWithLoaderAndErrorHandling(
                            AppLocalizations.of(context)!.editScoreButton,
                            (BuildContext context) async {
                          setState(() {
                            isSubmitMode = true;
                          });
                          focusNodes[0].requestFocus();
                        }, Secondary()),
                      ),
                    )
                  ],
                ),
              if (isSubmitMode &&
                  context
                          .watch<MatchesState>()
                          .getMatch(widget.matchId)!
                          .score !=
                      null)
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: GenericButtonWithLoaderAndErrorHandling(
                            AppLocalizations.of(context)!.cancelScoreButton,
                            (BuildContext context) async {
                          setState(() {
                            isSubmitMode = false;
                          });
                        }, Secondary()),
                      ),
                    ),
                  ],
                )
            ],
          ),
        ],
      ),
    );
  }
}
