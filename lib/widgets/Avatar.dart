import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:provider/provider.dart';
import 'package:skeletons/skeletons.dart';

import '../model/UserDetails.dart';
import '../state/UserState.dart';
import 'ModalBottomSheet.dart';
import 'PlayerBottomModal.dart';

class UserAvatar extends StatelessWidget {
  final double radius;
  final UserDetails? userDetails;

  const UserAvatar(this.radius, this.userDetails);

  @override
  Widget build(BuildContext context) {
    if (userDetails == null)
      return SkeletonAvatar(
        style: SkeletonAvatarStyle(
            width: radius * 2,
            padding: EdgeInsets.zero,
            shape: BoxShape.circle, height: radius * 2),
      );

    var photoUrl = userDetails?.getPhotoUrl();

    var backgroundColor = Palette.greyLighter;
    var backgroundImage = (photoUrl == null || photoUrl == "")
        ? null : NetworkImage(photoUrl);

    var displayName = UserDetails.getDisplayName(userDetails).toUpperCase();

    var fontSize = radius;

    var child = (photoUrl == null || photoUrl == "")
        ? Text(displayName[0],
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
                color: Palette.greyDark,
                fontSize: fontSize,
                fontWeight: FontWeight.w600))
        : null;

    return CircleAvatar(
        backgroundImage: backgroundImage,
        child: child,
        radius: radius,
        backgroundColor: backgroundColor);
  }
}

class NutmegAvatar extends StatelessWidget {
  final double radius;

  const NutmegAvatar(this.radius);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
        backgroundColor: Palette.primary,
        child: Padding(
            padding: EdgeInsets.all(5.0),
            child: Image.asset('assets/nutmeg_white.png', fit: BoxFit.cover)),
        radius: radius);
  }
}

class LoggedUserAvatarWithRedirectUserPage extends StatelessWidget {
  final double radius;

  const LoggedUserAvatarWithRedirectUserPage({Key? key, required this.radius})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () async => context.go("/user"),
      child: Container(
        height: 40,
        width: 40,
        child: Center(
          child: Container(
              height: 30,
              width: 30,
              // height and width nullify radius
              child: Center(
                  child: UserAvatar(
                      15,
                      context.watch<UserState>().getLoggedUserDetails()))),
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

class UserAvatarWithBottomModal extends StatelessWidget {
  final UserDetails? userData;
  final double radius;

  const UserAvatarWithBottomModal({Key? key, this.userData,
    this.radius = 24}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: (userData == null)
            ? null
            : () {
                ModalBottomSheet.showNutmegModalBottomSheet(
                    context, JoinedPlayerBottomModal(userData!));
              },
        child: UserAvatar(radius, userData));
  }
}
