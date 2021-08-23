import 'package:flutter/material.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/screens/Login.dart';
import 'package:nutmeg/screens/UserPage.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:provider/provider.dart';

class CustomAppBar extends StatelessWidget with PreferredSizeWidget {
  @override
  Widget build(BuildContext context) {
    var isLoggedIn = context.watch<UserChangeNotifier>().isLoggedIn();
    var userDetails = context.watch<UserChangeNotifier>().getUserDetails();

    return AppBar(
      centerTitle: false,
      backgroundColor: Palette.primary,
      toolbarHeight: 70,
      title: Image.asset('assets/nutmeg_logo.png', width: 116, height: 46),
      actions: [
        if (isLoggedIn)
          InkWell(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircleAvatar(
                    backgroundImage: NetworkImage(userDetails.getPhotoUrl()),
                    radius: 25),
              ),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => new UserPage())))
        else
          Padding(
              padding: EdgeInsets.only(right: 15),
              child: Center(
                  child: InkWell(
                      child: Text("LOGIN", style: TextPalette.whiteLogin),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (context) => Login())))))
      ],
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(70.0);
}
