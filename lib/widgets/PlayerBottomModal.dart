import 'package:flutter/material.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';

import '../model/UserDetails.dart';
import 'Avatar.dart';

class PlayerBottomModal extends StatelessWidget {

  PlayerBottomModal(this.userDetails, this.content, this.title, this.subtitle);

  final UserDetails userDetails;
  final String title;
  final String subtitle;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: EdgeInsets.only(bottom: 16),
      child: Container(
        child: Container(
          decoration: new BoxDecoration(
              color: Palette.white,
              borderRadius: new BorderRadius.only(
                  topLeft: const Radius.circular(20.0),
                  topRight: const Radius.circular(20.0))),
          child: Padding(
            padding: GenericInfoModal.padding,
            child: Container(
              child: Wrap(
                children: [
                  Stack(
                      alignment: AlignmentDirectional.bottomStart,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                            decoration: BoxDecoration(
                              color: Palette.white,
                              borderRadius: GenericInfoModal.modalRadius
                            ),
                            width: double.infinity,
                            child: Column(children: [
                              SizedBox(height: 44),
                              Text(title, style: TextPalette.h2),
                              if (subtitle != null)
                                Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Text(subtitle, style: TextPalette.getBodyText(Palette.grey_dark))),
                              SizedBox(height: 24),
                              content
                            ],)
                        ),
                        Positioned(
                            top: -50,
                            left: 0,
                            right: 0,
                            child: UserAvatarWithBorder(userDetails)),
                      ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StatEntry extends StatelessWidget {

  final String stat;
  final String description;

  const StatEntry({Key key, this.stat, this.description}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(children: [
        Text(stat, style: TextPalette.getStats(Palette.black)),
        SizedBox(height: 4),
        Text(description, style: TextPalette.bodyText)
      ],),
    );
  }
}

class JoinedPlayerBottomModal extends StatelessWidget {
  final UserDetails userDetails;

  JoinedPlayerBottomModal(this.userDetails);

  @override
  Widget build(BuildContext context) {
    return PlayerBottomModal(
      userDetails,
      Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: StatEntry(stat: userDetails.getJoinedMatches().length.toString(),
                  description: "Matches",),
              ),
              Expanded(
                child: StatEntry(stat: (userDetails.getScoreMatches() == -1)
                    ? "-"
                    : userDetails.getScoreMatches().toStringAsFixed(2),
                  description: "Avg. score",),
              ),
              Expanded(
                child: StatEntry(stat: userDetails.getNumManOfTheMatch().toString(),
                  description: "POTM",),
              ),
            ],
          ),
        ],
      ),
      UserDetails.getDisplayName(userDetails),
      null
    );
  }
}
