import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../screens/CreateMatch.dart';
import '../screens/MatchDetails.dart';
import '../state/MatchesState.dart';
import '../state/UserState.dart';
import '../utils/UiUtils.dart';
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

  late TeamsWidgetScoreState userState;
  late bool isOrganizerView;
  bool manualSplit = false;
  bool loader = false;
  bool isItemMoving = false;

  List<FocusNode> focusNodes = [FocusNode(), FocusNode()];

  @override
  void initState() {
    super.initState();
    isOrganizerView = context.read<UserState>().isLoggedIn() &&
        context.read<UserState>().currentUserId ==
            context.read<MatchesState>().getMatch(widget.matchId)?.organizerId;
    if (isOrganizerView) {
      bool hasScore =
          context.read<MatchesState>().getMatch(widget.matchId)!.score != null;
      if (!hasScore) {
        userState = TeamsWidgetScoreState.add;
      } else {
        userState = TeamsWidgetScoreState.edit;
      }
    }
  }

  Widget inputScore(TextEditingController controller, FocusNode focusNode) =>
      Container(
          width: 50,
          child: Center(
            child: TextFormField(
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              controller: controller,
              validator: (v) {
                if (int.tryParse(v ?? "") == null) return "Invalid";
                return null;
              },
              textAlign: TextAlign.center,
              decoration: CreateMatchState.getTextFormDecoration(null),
            ),
          ));

  @override
  Widget build(BuildContext context) {
    var match = context.watch<MatchesState>().getMatch(widget.matchId)!;

    var controllers;
    if (isOrganizerView) {
      controllers = [TextEditingController(), TextEditingController()];
      if (match.score != null) {
        controllers[0].text = match.score![0].toString();
        controllers[1].text = match.score![1].toString();
      }
    }

    var teamAScoreWidget =
        isOrganizerView && userState == TeamsWidgetScoreState.submit
            ? inputScore(controllers[0], focusNodes[0])
            : match.score == null || match.score!.length < 2
                ? Container()
                : Text(match.score![0].toString(),
                    textAlign: TextAlign.end,
                    style: TextPalette.getStats(Palette.black));

    var teamBScoreWidget =
        isOrganizerView && userState == TeamsWidgetScoreState.submit
            ? inputScore(controllers[1], focusNodes[1])
            : match.score == null || match.score!.length < 2
                ? Container()
                : Text(match.score![1].toString(),
                    textAlign: TextAlign.end,
                    style: TextPalette.getStats(Palette.black));

    var content = Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Center(
          child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                  flex: 3,
                  child: Text(
                    "Team A",
                    style: TextPalette.h2,
                  )),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  teamAScoreWidget,
                  Text("  vs  ", style: TextPalette.bodyText),
                  teamBScoreWidget
                ],
              ),
              Flexible(
                  flex: 3,
                  child: Text(
                    "Team B",
                    style: TextPalette.h2,
                  )),
            ],
          ),
          SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            var draggable = manualSplit &&
                match.canUserModifyTeams(
                    context.read<UserState>().currentUserId);
            var singleListWidth = (constraints.maxWidth - 8) / 2;
            var singleRowElementHeight = 44.0;

            return SizedBox(
              height: singleRowElementHeight *
                  (match.teams
                      .map((e) => e.value.length)
                      .reduce((a, b) => a > b ? a : b)),
              child: Material(
                color: Colors.transparent,
                child: DragAndDropLists(
                  itemGhost: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Container(
                      height: singleRowElementHeight,
                      width: singleListWidth,
                      decoration: BoxDecoration(
                        borderRadius: InfoContainer.borderRadius,
                        color: Palette.grey_light
                      ),),
                  ),
                  lastItemTargetHeight: 0,
                  listTarget: Container(),
                  disableScrolling: true,
                  listPadding: EdgeInsets.all(0),
                  itemDragHandle: DragHandle(
                    child: Container(
                      width: singleListWidth,
                      height: singleRowElementHeight,
                      color: Colors.transparent,
                    ),
                  ),
                  listWidth: singleListWidth,
                  listDivider: VerticalDivider(width: 8),
                  listDividerOnLastChild: false,
                  itemDraggingWidth: singleListWidth,
                  children: match.teams
                      .map((team) => DragAndDropList(
                          contentsWhenEmpty: Container(),
                          children: team.value.map((u) {
                            var ud =
                                context.watch<UserState>().getUserDetail(u);
                            var icon = Icon(
                              Icons.drag_indicator_outlined,
                              color: Palette.grey_light,
                            );
                            var avatar = UserAvatar(16, ud);
                            var name = UserNameWidget(userDetails: ud);

                            var rowWidgets;

                            if (team.key == "a") {
                              rowWidgets = Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    if (draggable)
                                      Padding(
                                          padding: EdgeInsets.only(right: 4),
                                          child: icon),
                                    avatar,
                                    SizedBox(width: 16),
                                    name
                                  ]);
                            } else {
                              rowWidgets = Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    name,
                                    SizedBox(width: 16),
                                    avatar,
                                    if (draggable)
                                      Padding(
                                          padding: EdgeInsets.only(left: 4),
                                          child: icon),
                                  ]);
                            }

                            var element = SizedBox(
                              height: singleRowElementHeight,
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: InkWell(
                                    onTap: ud == null
                                        ? null
                                        : () => ModalBottomSheet
                                            .showNutmegModalBottomSheet(context,
                                                JoinedPlayerBottomModal(ud)),
                                    child: rowWidgets),
                              ),
                            );

                            return DragAndDropItem(
                              child:
                              // Container(
                              //     decoration: BoxDecoration(
                              //         border: Border.all(
                              //           color: Palette.white,
                              //         ),
                              //         color: Palette.white,
                              //         borderRadius: BorderRadius.circular(10),
                              //         boxShadow: [
                              //           if (isItemMoving)
                              //             InfoContainer.boxShadow
                              //         ],
                              //     ),
                              //     child:
                                  element,
                              canDrag: draggable,
                            );
                          }).toList()))
                      .toList(),
                  onItemReorder: (int oldItemIndex, int oldListIndex,
                      int newItemIndex, int newListIndex) {
                    print(oldListIndex); print(newListIndex);
                    if (oldListIndex != newListIndex) {
                      context.read<MatchesState>().movePlayerToTeam(
                          widget.matchId,
                          match.teams[oldListIndex].value[oldItemIndex],
                          newListIndex);
                    }
                  },
                  onListReorder: (int oldListIndex, int newListIndex) {},
                  axis: Axis.horizontal,
                ),
              ),
            );
          }),
          if (isOrganizerView && match.isMatchFinished())
            Padding(
              padding: EdgeInsets.only(top: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: GenericButtonWithLoaderAndErrorHandling(
                        userState == TeamsWidgetScoreState.add
                            ? AppLocalizations.of(context)!.addScoreButton
                            : userState == TeamsWidgetScoreState.submit
                                ? AppLocalizations.of(context)!
                                    .submitScoreButton
                                : AppLocalizations.of(context)!.editScoreButton,
                        (BuildContext context) async {
                      var nextState;
                      if (userState == TeamsWidgetScoreState.submit) {
                        var score = [
                          int.parse(controllers[0].text),
                          int.parse(controllers[1].text),
                        ];
                        await context
                            .read<MatchesState>()
                            .editMatch(match.documentId, {"score": score});

                        nextState = TeamsWidgetScoreState.edit;
                      } else {
                        nextState = TeamsWidgetScoreState.submit;
                        focusNodes[0].requestFocus();
                      }
                      setState(() {
                        userState = nextState;
                      });
                    },
                        userState == TeamsWidgetScoreState.edit
                            ? Secondary()
                            : Primary()),
                  )
                ],
              ),
            ),
          if (isOrganizerView)
            Padding(
              padding: EdgeInsets.only(top: 24),
              child: Column(
                children: [
                  Divider(color: Palette.grey_light, height: 0),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Switch(
                          value: manualSplit,
                          activeColor: Palette.primary,
                          onChanged: (v) async {
                            setState(() {
                              manualSplit = v;
                            });
                            if (!manualSplit) {
                              setState(() {
                                loader = true;
                              });
                              await context
                                  .read<MatchesState>()
                                  .shuffleTeams(widget.matchId);
                              setState(() {
                                loader = false;
                              });
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
                  SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.manualSplitTeamInfo,
                      style: TextPalette.bodyText)
                ],
              ),
            )
        ],
      )),
    );

    return Form(key: _scoreFormKey, child: InfoContainer(child: content));
  }
}
