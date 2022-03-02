import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nutmeg/screens/UserPage.dart';
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

    var backgroundColor = Palette.lighterGrey;
    var backgroundImage = (photoUrl == null) ? null : NetworkImage(photoUrl);

    var displayName = ((userDetails == null) ? "P" : (userDetails.name ??
        userDetails.email ?? "P")).toUpperCase();

    var child = (photoUrl == null)
        ? Center(
            child: Text(displayName[0],
                style: GoogleFonts.roboto(
                    color: Palette.mediumgrey,
                    fontSize: 24,
                    fontWeight: FontWeight.w500)))
        : null;

    return CircleAvatar(
        child: child,
        backgroundImage: backgroundImage,
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
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => new UserPage()));
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
