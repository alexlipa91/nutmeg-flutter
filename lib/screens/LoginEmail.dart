import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutmeg/models/UserModel.dart';
import 'package:provider/provider.dart';

import '../Utils.dart';
import 'Login.dart';

void main() {
  runApp(new MaterialApp(
    home: LoginEmail(),
    theme: appTheme,
  ));
}

class LoginEmail extends StatelessWidget {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    print("Building " + this.runtimeType.toString());

    final ThemeData themeData = Theme.of(context);

    void onLoginPress() {
      if (!Provider.of<UserModel>(context, listen: false)
          .login(emailController.text, passwordController.text)) {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(content: Text("User not found"));
            });
      } else {
        int count = 0;
        Navigator.of(context).popUntil((_) => count++ >= 2);
      }
    }

    return SafeArea(
      child: Scaffold(
        body: Container(
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
              LoginInputTextField(text: "Email", controller: emailController),
              LoginInputTextField(
                  text: "Password",
                  obscure: true,
                  controller: passwordController),
              LoginOptionButton(text: "Login", onTap: onLoginPress)
            ],
          ),
        ),
      ),
    );
  }
}

class LoginInputTextField extends StatelessWidget {
  final String text;
  final bool obscure;
  final TextEditingController controller;

  const LoginInputTextField({Key key, this.text, this.obscure, this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.0),
      child: TextField(
        inputFormatters: [
          FilteringTextInputFormatter.deny(RegExp('[ ]')),
        ],
        obscureText: (obscure != null) ? obscure : false,
        style: themeData.textTheme.headline3,
        controller: controller,
        decoration: InputDecoration(
            contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
            hintText: text,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(32.0))),
      ),
    );
  }
}

class LoginButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    var button = LoginOptionButton(text: "Login");

    return button;
  }
}
