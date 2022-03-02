import 'package:flutter/material.dart';
import 'package:nutmeg/utils/UiUtils.dart';

import '../model/UserDetails.dart';
import 'Avatar.dart';

class PlayerBottomModal extends StatelessWidget {
  static String getDisplayName(UserDetails ud) {
    if (ud == null) return "Player";
    if (ud.name != null) return ud.name;
    if (ud.email != null) return ud.email;
    return "Player";
  }

  PlayerBottomModal(this.userDetails, this.content);

  final UserDetails userDetails;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Wrap(
        children: [
          Stack(
              alignment: AlignmentDirectional.bottomStart,
              clipBehavior: Clip.none,
              children: [
                Container(
                    decoration: BoxDecoration(
                      color: Palette.white,
                      borderRadius:  BorderRadius.all(Radius.circular(10))
                    ),
                    width: double.infinity,
                    child: content),
                Positioned(
                    top: -30,
                    left: 0,
                    right: 0,
                    child: UserAvatarWithBorder(userDetails)),
              ]),
        ],
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
      width: 70,
      child: Column(children: [
        Text(stat, style: TextPalette.h1Default),
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
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            SizedBox(height: 70),
            Text(PlayerBottomModal.getDisplayName(userDetails),
                style: TextPalette.h2),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                StatEntry(stat: userDetails.joinedMatches.length.toString(),
                  description: "Matches",),
                Expanded(
                  child: StatEntry(stat: userDetails.getScoreMatches().toStringAsFixed(2),
                    description: "Avg. score",),
                ),
                StatEntry(stat: userDetails.getNumManOfTheMatch().toString(),
                  description: "POTM",),
              ],
            ),
            SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}
