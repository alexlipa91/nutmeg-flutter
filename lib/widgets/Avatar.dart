import 'package:flutter/material.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/screens/UserPage.dart';
import 'package:provider/provider.dart';


class UserAvatar extends StatelessWidget {

  final double radius;

  const UserAvatar({Key key, this.radius}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var userDetails = context.watch<UserState>().getUserDetails();

    var photoUrl = userDetails.getPhotoUrl();
    var backgroundImage = (photoUrl == null) ? null : NetworkImage(photoUrl);
    var userId = userDetails.name ?? userDetails.email;
    var child = (photoUrl == null) ? Center(child: Text(userId[0].toUpperCase())) : null;

    return CircleAvatar(
            child: child,
            backgroundImage: backgroundImage,
            radius: radius);
  }
}

class UserAvatarWithRedirect extends StatelessWidget {

  final double radius;

  const UserAvatarWithRedirect({Key key, this.radius}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
        child: UserAvatar(radius: radius),
        onTap: () async {
          await UserController.refresh(context.read<UserState>());
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => new UserPage()));
        });
  }
}
