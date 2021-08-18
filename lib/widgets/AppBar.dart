import 'package:flutter/material.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/screens/Login.dart';
import 'package:nutmeg/screens/UserPage.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:provider/provider.dart';


class CustomAppBar extends StatelessWidget with PreferredSizeWidget {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 70,
      title: Text("Nutmeg",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w500, fontSize: 26)),
      actions: [
        Consumer<UserChangeNotifier>(builder: (context, user, child) {
          var widget;
          var function;
          var backgroundImage;
          if (context.watch<UserChangeNotifier>().isLoggedIn()) {
            // fixme this doesn't really pad well
            function = () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => new UserPage()));
            };
            backgroundImage = NetworkImage(context
                .read<UserChangeNotifier>()
                .getUserDetails()
                .firebaseUser
                .photoURL);
          } else {
            function = () => Navigator.push(
                context, MaterialPageRoute(builder: (context) => Login()));
            widget = Icon(Icons.login, color: Colors.green);
          }

          return InkWell(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircleAvatar(
                  child: widget,
                  backgroundImage: backgroundImage,
                  radius: 25,
                  backgroundColor: Palette.white),
            ),
            onTap: function,
          );
        })
      ],
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(70.0);
}
