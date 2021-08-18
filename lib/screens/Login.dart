import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/utils/GoogleSignInButton.dart';
import 'package:nutmeg/utils/LoginUtils.dart';


import '../utils/Utils.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Authentication.initializeFirebase();

  runApp(new MaterialApp(
    home: Login(),
    theme: appTheme,
  ));
}

class Login extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(50),
        decoration: new BoxDecoration(color: Colors.grey.shade400),
        // padding: EdgeInsets.symmetric(100, padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Nutmeg", style: themeData.textTheme.headline1),
            SizedBox(height: 10),
            Text(
                "Join Football matches in your city\n"
                    "whenever you want",
                style: themeData.textTheme.bodyText1,
                textAlign: TextAlign.center),
            SizedBox(height: 30),
            LoginAreaWidget()
          ],
        ),
      ),
    );
  }
}

class LoginAreaWidget extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Container(
          child: Column(children: [
            LoginOptionButton(text: "Facebook"),
            GoogleSignInButton()
            // LoginOptionButton(text: "Google"),
          ]));
    }
}

// fixme this is being used because of the UI somewhere else. Rename it and generalize
class LoginOptionButton extends StatelessWidget {
  final String text;
  final Function onTap;
  final Widget next;

  const LoginOptionButton({Key key, this.text, this.onTap, this.next}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Container(
      margin: EdgeInsets.all(30.0),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
                onPressed: onTap,
                child: Text(
                  text,
                ),
                style: ButtonStyle(
                    side: MaterialStateProperty.all(
                        BorderSide(width: 2, color: Colors.grey)),
                    foregroundColor: MaterialStateProperty.all(Colors.black),
                    backgroundColor: MaterialStateProperty.all(Colors.grey),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        )),
                    padding: MaterialStateProperty.all(
                        EdgeInsets.symmetric(vertical: 10, horizontal: 50)),
                    textStyle: MaterialStateProperty.all(
                        themeData.textTheme.headline3))),
          )
        ],
      ),
    );
  }
}