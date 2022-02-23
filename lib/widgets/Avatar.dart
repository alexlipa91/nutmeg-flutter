import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/screens/UserPage.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:provider/provider.dart';


class UserAvatar extends StatelessWidget {
  final double radius;
  final UserDetails userDetails;

  const UserAvatar(this.radius, this.userDetails);

  @override
  Widget build(BuildContext context) {
    var ud = userDetails ?? context.watch<UserState>().getUserDetails();

    var photoUrl = (ud == null) ? null : ud.getPhotoUrl();

    var backgroundColor = Palette.lighterGrey;
    var backgroundImage = (photoUrl == null) ? null : NetworkImage(photoUrl);

    var displayName = ((ud == null) ? "P" : (ud.name ?? ud.email ?? "P")).toUpperCase();

    var child = (photoUrl == null)
        ? Center(
            child: Text(displayName[0],
                style: GoogleFonts.roboto(
                    color: Palette.white,
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

class UserAvatarWithRedirect extends StatelessWidget {
  final double radius;

  const UserAvatarWithRedirect({Key key, this.radius}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 40,
      child: InkWell(
          child: UserAvatar(radius, null),
          onTap: () async {
            await UserController.refreshCurrentUser(context.read<UserState>());
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => new UserPage()));
          },
        customBorder: CircleBorder(),
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
