import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:provider/provider.dart';

import '../model/UserDetails.dart';
import '../state/UserState.dart';


class UserAvatar extends StatelessWidget {
  final double radius;
  final UserDetails userDetails;

  const UserAvatar(this.radius, this.userDetails);

  @override
  Widget build(BuildContext context) {
    var photoUrl = userDetails?.getPhotoUrl();

    var backgroundColor = Palette.grey_lighter;
    var backgroundImage = (photoUrl == null) ? null : NetworkImage(photoUrl);

    var displayName = UserDetails.getDisplayName(userDetails).toUpperCase();

    var fontSize = radius;

    var child = (photoUrl == null)
        ? Text(displayName[0],
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
                color: Palette.grey_dark,
                fontSize: fontSize,
                fontWeight: FontWeight.w600
            ))
        : null;

    return CircleAvatar(
        backgroundImage: backgroundImage,
        child: child,
        radius: radius,
        backgroundColor: backgroundColor);
  }
}

class CurrentUserAvatarWithRedirect extends StatelessWidget {
  final double radius;

  const CurrentUserAvatarWithRedirect({Key key, this.radius}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        Get.toNamed("/user");
      },
      child: Container(
        height: 40,
        width: 40,
        child: Center(
          child: Container(
              height: 30,
              width: 30,
              // height and width nullify radius
              child: Center(child: UserAvatar(200, context.watch<UserState>().getLoggedUserDetails()))),
        ),
      ),
    );
  }
}

class UserAvatarWithBorder extends StatelessWidget {
  final UserDetails userDetails;

  UserAvatarWithBorder(this.userDetails);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
        backgroundColor: Palette.white,
        radius: 38,
        child: UserAvatar(34, userDetails));
  }
}
