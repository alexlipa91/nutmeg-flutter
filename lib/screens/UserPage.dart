import 'package:flutter/material.dart';

import '../Utils.dart';

void main() {
  runApp(new MaterialApp(
    home: UserPage(),
    theme: appTheme,
  ));
}

class UserPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return SafeArea(child: Column(children: [
      UserImage(),
      // Expanded(child: Text("ABC")),
    ]));
  }
}

class UserImage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: 100,
        height: 100,
        child: Container(
          decoration: new BoxDecoration(color: Colors.grey.shade400),
          child: Container(
              margin: EdgeInsets.all(70.0),
              decoration: BoxDecoration(
                border: Border.all(width: 2),
                shape: BoxShape.circle,
                // You can use like this way or like the below line
                // borderRadius: new BorderRadius.circular(30.0),
                color: Colors.purple,
              ),
              child: Center(
                child: Text('A',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 100,
                        fontFamily: "Montserrat")),
              )),
        ),
      ),
    );
  }
}
