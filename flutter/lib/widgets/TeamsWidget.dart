import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/state/MatchState.dart';
import 'package:nutmeg/state/UsersState.dart';
import 'package:provider/provider.dart';
import 'package:nutmeg/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

import '../screens/CreateMatch.dart';
import '../screens/MatchDetails.dart';
import '../state/MatchesState.dart';
import '../utils/LocationUtils.dart';
import '../utils/share_utils.dart';
import '../utils/UiUtils.dart';
import '../utils/Utils.dart';
import 'Avatar.dart';
import 'ButtonsWithLoader.dart';
import 'Containers.dart';
import 'ModalBottomSheet.dart';
import 'PlayerBottomModal.dart';

class TeamsWidget extends StatefulWidget {
  final String matchId;
  final bool shareableVersion;

  const TeamsWidget(
      {Key? key, required this.matchId, this.shareableVersion = false})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => TeamsWidgetState();
}

enum TeamsWidgetScoreState { add, edit, submit }

class TeamsWidgetState extends State<TeamsWidget> {
  final _scoreFormKey = GlobalKey<FormState>();
  final GlobalKey _teamsContainerKey = GlobalKey();
  final GlobalKey _shareableTeamsContainerKey = GlobalKey();

  late bool isOrganizerView;
  late bool manualSplit;
  bool loader = false;
  bool? movingItemFromLeft;
  bool isEditing = false;
  bool hasMovedAnyPlayer = false;

  List<List<String>> manualTeams = [];
  final Set<String> _loggedMissingUsers = {};

  List<FocusNode> focusNodes = [FocusNode(), FocusNode()];

  Widget _buildTeamsCaptureContainer(
    BuildContext context, {
    required Match? match,
    required List<List<String>>? teams,
    required UsersState usersState,
    required bool showShareDecorations,
    required bool showOrganizerStrength,
    required String? matchHeader,
  }) {
    final lateralPadding = showShareDecorations ? 14.0 : 0.0;
    return Container(
      color: showShareDecorations ? Colors.white : Colors.transparent,
      padding: EdgeInsets.fromLTRB(lateralPadding, 14, lateralPadding, 10),
      child: Column(
        children: [
          if (showShareDecorations) ...[
            Image.asset(
              "assets/nutmeg_white.png",
              height: 22,
              color: Palette.primary,
              filterQuality: FilterQuality.high,
              isAntiAlias: true,
            ),
            if (matchHeader != null) ...[
              const SizedBox(height: 8),
              Text(
                matchHeader,
                textAlign: TextAlign.center,
                style: TextPalette.bodyText,
              ),
            ],
            const SizedBox(height: 12),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.teamNameLabelText("A"),
                  style: TextPalette.h2,
                  textAlign: TextAlign.left,
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    match?.score == null
                        ? Container()
                        : Text(match?.score![0].toString() ?? "",
                            textAlign: TextAlign.end,
                            style: TextPalette.getStats(Palette.black)),
                    Text("  vs  ", style: TextPalette.bodyText),
                    match?.score == null
                        ? Container()
                        : Text(match?.score![1].toString() ?? "",
                            textAlign: TextAlign.end,
                            style: TextPalette.getStats(Palette.black))
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.teamNameLabelText("B"),
                  style: TextPalette.h2,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: getTeamColumn(
                        context, MainAxisAlignment.start, teams ?? [], 0)),
                NutmegDivider(horizontal: false),
                Expanded(
                    child: getTeamColumn(
                        context, MainAxisAlignment.end, teams ?? [], 1)),
              ],
            ),
          ),
          if (showOrganizerStrength)
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    teams![0]
                        .map((u) =>
                            usersState.getUserDetail(u)?.averageScore ?? 3)
                        .fold<double>(0, (a, b) => a + b)
                        .toStringAsFixed(2),
                    style: TextPalette.bodyText,
                  ),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.teamStrenghtLabel,
                      textAlign: TextAlign.center,
                      style: TextPalette.bodyText,
                    ),
                  ),
                  Text(
                    teams[1]
                        .map((u) =>
                            usersState.getUserDetail(u)?.averageScore ?? 3)
                        .fold<double>(0, (a, b) => a + b)
                        .toStringAsFixed(2),
                    style: TextPalette.bodyText,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _captureAndShareTeams(BuildContext context) async {
    try {
      final boundary = _shareableTeamsContainerKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final devicePixelRatio = View.of(context).devicePixelRatio;
      final capturePixelRatio =
          (devicePixelRatio * 2).clamp(2.5, 5.0).toDouble();
      final image = await boundary.toImage(pixelRatio: capturePixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      await shareWithOrigin(
        context,
        text: "Teams",
        files: [
          XFile.fromData(
            byteData.buffer.asUint8List(),
            name: 'teams_${widget.matchId}.png',
            mimeType: 'image/png',
          ),
        ],
      );
    } catch (e) {
      print('Error sharing teams: $e');
    }
  }

  @override
  void initState() {
    super.initState();

    var state = context.read<MatchState>();

    var match = state.match;
    manualTeams = match?.manualTeams ?? [];
    manualSplit = manualTeams.isNotEmpty;
    isOrganizerView = state.isLoggedUserOrganizer();
  }

  getTeamColumn(BuildContext context, MainAxisAlignment alignment,
      List<List<String>> teams, int index) {
    var state = context.watch<MatchState>();

    var match = state.match;
    isOrganizerView = state.isLoggedUserOrganizer();

    var draggable = isEditing &&
        manualSplit &&
        match?.status != MatchStatus.rated &&
        isOrganizerView;

    var isLeftColumn = MainAxisAlignment.start == alignment;
    var playersWidgets = interleave(
        teams[index].map((e) {
          var ud = context.watch<UsersState>().getUserDetail(e);
          if (ud == null) {
            // Team rows may include users that were not prefetched yet
            // (e.g. newly added guest users). Trigger a fetch so skeletons resolve.
            context.read<UsersState>().fetchUserDetails(e);
            if (!_loggedMissingUsers.contains(e)) {
              _loggedMissingUsers.add(e);
              debugPrint("TeamsWidget unresolved user details for id=$e");
            }
          } else {
            _loggedMissingUsers.remove(e);
          }

          var avatar = UserAvatar(24, ud);
          var name = UserNameWidget(
            userDetails: ud,
            textAlign: isLeftColumn ? TextAlign.start : TextAlign.end,
          );
          var userRow = SizedBox(
            height: 48,
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
                          Expanded(child: name),
                        ])
                  : Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Expanded(child: name),
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
        if (manualSplit) {
          setState(() {
            hasMovedAnyPlayer = true;
            if (isLeftColumn) {
              manualTeams[0].add(item);
              manualTeams[1].remove(item);
            } else {
              manualTeams[1].add(item);
              manualTeams[0].remove(item);
            }
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var state = context.watch<MatchState>();
    var match = state.match;
    var usersState = context.watch<UsersState>();

    var teams = manualSplit ? manualTeams : match?.computedTeams;
    final showStrengthRow = !widget.shareableVersion;
    final showOrganizerShareAction =
        isOrganizerView && !widget.shareableVersion;
    final showShareDecorations = widget.shareableVersion;
    final formattedDate = match == null
        ? null
        : DateFormat("EEEE, MMM dd yyyy",
                getLanguageLocaleWatch(context).languageCode)
            .format(match.getLocalizedTime());
    final matchHeader = match == null
        ? null
        : "$formattedDate - ${match.sportCenter?.getName() ?? ''}";

    var content = Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Center(
          child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              RepaintBoundary(
                key: _teamsContainerKey,
                child: _buildTeamsCaptureContainer(
                  context,
                  match: match,
                  teams: teams,
                  usersState: usersState,
                  showShareDecorations: showShareDecorations,
                  showOrganizerStrength: showStrengthRow,
                  matchHeader: matchHeader,
                ),
              ),
              if (showOrganizerShareAction)
                Positioned(
                  left: -10000,
                  top: 0,
                  child: IgnorePointer(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width - 48,
                      child: RepaintBoundary(
                        key: _shareableTeamsContainerKey,
                        child: _buildTeamsCaptureContainer(
                          context,
                          match: match,
                          teams: teams,
                          usersState: usersState,
                          showShareDecorations: true,
                          showOrganizerStrength: showStrengthRow,
                          matchHeader: matchHeader,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (showOrganizerShareAction)
            Padding(
              padding: EdgeInsets.only(top: 4),
              child: Center(
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 20,
                  constraints: const BoxConstraints(),
                  onPressed: () => _captureAndShareTeams(context),
                  icon: const Icon(Icons.share),
                  tooltip: AppLocalizations.of(context)!.shareAction,
                ),
              ),
            ),
          if (state.isLoggedUserOrganizer() &&
              match?.status != MatchStatus.rated)
            Padding(
              padding: EdgeInsets.only(top: 8),
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
                            onChanged: isEditing
                                ? (v) async {
                                    setState(() {
                                      manualSplit = v;
                                      if (manualSplit) {
                                        // copy over the computed teams
                                        manualTeams = List.from(teams ?? []);
                                      }
                                    });
                                  }
                                : null),
                        SizedBox(width: 8),
                        Text(
                            AppLocalizations.of(context)!
                                .manualSplitTeamCheckBoxLabel,
                            style: TextPalette.h3.copyWith(
                              color: isEditing ? null : Palette.greyLight,
                            )),
                        Spacer(),
                        GenericButtonWithLoader(
                          isEditing
                              ? AppLocalizations.of(context)!.doneButtonText
                              : AppLocalizations.of(context)!.modifyButtonText,
                          (BuildContext context) {
                            setState(() {
                              isEditing = !isEditing;
                              if (isEditing) {
                                hasMovedAnyPlayer = false;
                              }
                            });
                            if (manualSplit && hasMovedAnyPlayer) {
                              context.read<MatchState>().saveManualTeams(
                                    manualTeams,
                                  );
                            }
                            if (!manualSplit) {
                              context.read<MatchState>().eraseManualTeams();
                            }
                          },
                          isEditing ? Secondary() : Primary(),
                        ),
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
          if (isOrganizerView && match?.status == MatchStatus.to_rate)
            Padding(
                padding: EdgeInsets.only(top: 8),
                child: NutmegDivider(horizontal: true)),
          if (isOrganizerView && match?.status == MatchStatus.to_rate)
            Padding(
                padding: EdgeInsets.only(top: 8),
                child: EditScoreWidget(matchId: widget.matchId))
        ],
      )),
    );

    return Form(
      key: _scoreFormKey,
      child: InfoContainer(child: content),
    );
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
    var state = context.read<MatchState>();
    isSubmitMode = state.match?.score == null;
    var score = state.match?.score;
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
        decoration: CreateMatchState.getTextFormDecoration(null,
            hintText: "0", hintStyle: TextPalette.getStats(Palette.greyLight)),
      );

  @override
  Widget build(BuildContext context) {
    var state = context.watch<MatchState>();

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
                              .getMatch(widget.matchId)
                              .editMatch({"score": score});
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
              if (isSubmitMode && state.match?.score != null)
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
