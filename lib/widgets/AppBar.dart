import 'package:flutter/material.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/screens/Login.dart';
import 'package:nutmeg/screens/UserPage.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:provider/provider.dart';

class MainAppBar extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    var isLoggedIn = context.watch<UserChangeNotifier>().isLoggedIn();
    var userDetails = context.watch<UserChangeNotifier>().getUserDetails();

    return Container(
        color: Palette.primary,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset('assets/nutmeg_logo.png', width: 106, height: 40),
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
                InkWell(
                child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("LOGIN", style: TextPalette.h2White)),
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (context) => Login())),
              ),
            ],
          ),
        ));
  }
}

class SecondaryAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        child: Padding(
      padding: EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
              child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.arrow_back, color: Colors.black)),
              onTap: () => Navigator.pop(context)),
          InkWell(
              child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.share, color: Colors.black)),
              onTap: () => print("IMPLEMENT SHARE")),
        ],
      ),
    ));
  }
}
