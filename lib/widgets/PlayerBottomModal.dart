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

  PlayerBottomModal(this.userDetails, this.content);

  final UserDetails userDetails;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        Stack(
            alignment: AlignmentDirectional.bottomStart,
            clipBehavior: Clip.none,
            children: [
              Container(
                  width: double.infinity, color: Palette.white, child: content),
              Positioned(
                  top: -30,
                  left: 0,
                  right: 0,
                  child: UserAvatarWithBorder(userDetails)),
            ]),
      ],
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
          SizedBox(height: 70),
          Text(PlayerBottomModal.getDisplayName(userDetails),
              style: TextPalette.h2),
          SizedBox(height: 20),
          Builder(builder: (context) {
            int nPlayed = (userDetails == null) ? 1 : context
                .watch<MatchesState>()
                .getNumPlayedByUser(userDetails.documentId);
            return Text(
                nPlayed.toString() +
                    " " +
                    ((nPlayed == 1) ? "match " : "matches ") +
                    "played",
                style: TextPalette.bodyText);
          }),
          SizedBox(height: 70),
        ],
      ),
    );
  }
}
