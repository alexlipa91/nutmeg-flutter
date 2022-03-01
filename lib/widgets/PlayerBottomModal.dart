import 'package:flutter/material.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:provider/provider.dart';

import '../model/UserDetails.dart';
import '../state/MatchesState.dart';
import 'Avatar.dart';


class PlayerBottomModal extends StatelessWidget {

  static String getDisplayName(UserDetails ud) {
    if (ud == null) return "Player";
    if (ud.name != null) return ud.name;
    if (ud.email != null) return ud.email;
    return "Player";
  }

  const PlayerBottomModal({Key key, this.userDetails}) : super(key: key);

  final UserDetails userDetails;

  @override
  Widget build(BuildContext context) {
    return Stack(
        alignment: AlignmentDirectional.bottomStart,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            height: 200,
            color: Palette.white,
            child: Column(
              children: [
                SizedBox(height: 70),
                Text(getDisplayName(userDetails), style: TextPalette.h2),
                SizedBox(height: 20),
                Builder(builder: (context) {
                  int nPlayed = context
                      .watch<MatchesState>()
                      .getNumPlayedByUser(userDetails.documentId);
                  return Text(
                      nPlayed.toString() +
                          " " +
                          ((nPlayed == 1) ? "match " : "matches ") +
                          "played",
                      style: TextPalette.bodyText);
                })
              ],
            ),
          ),
          Positioned(
              top: -30,
              left: 0,
              right: 0,
              child: UserAvatarWithBorder(userDetails)),
        ]);
  }
}

