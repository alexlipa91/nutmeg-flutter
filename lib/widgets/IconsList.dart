import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:provider/provider.dart';

import 'Avatar.dart';


class IconsList extends StatelessWidget {
  final Match match;

  const IconsList({Key key, this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var isLoggedInAndGoing = context.watch<UserState>().isLoggedIn() &&
        match.isUserGoing(context.watch<UserState>().getUserDetails());

    var widgets = List<Widget>.from([]);
    var currentRightOffset = 0.0;

    var userAvatar = Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(50.0)),
          border: Border.all(
            color: Colors.white,
            width: 2.0,
          ),
        ),
        child: UserAvatar(14, context.read<UserState>().getUserDetails()));
    var plusPlayers = Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(50.0)),
        border: Border.all(
          color: Colors.white,
          width: 2.0,
        ),
      ),
      child: CircleAvatar(
          child: Center(
              child: Text("+" + (match.numPlayersGoing() - 1).toString(),
                  style: GoogleFonts.roboto(
                      color: Palette.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500))),
          radius: 14,
          backgroundColor: Palette.primary),
    );

    if (isLoggedInAndGoing) {
      widgets.add(plusPlayers);
      currentRightOffset += 18;
    }

    if (isLoggedInAndGoing && match.numPlayersGoing() > 1) {
      if (currentRightOffset > 0) {
        widgets.add(Positioned(right: currentRightOffset, child: userAvatar));
      } else {
        widgets.add(userAvatar);
      }
    }

    return (widgets.isEmpty) ? Container() : Container(
      child: Stack(
        // alignment: Alignment.bottomLeft,
          clipBehavior: Clip.none,
          children: widgets),
    );
  }
}