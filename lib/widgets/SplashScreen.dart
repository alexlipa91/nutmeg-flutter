import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/utils/UiUtils.dart';

// use this for any waiting operation
class SplashScreen extends StatelessWidget {

  final Future<void> future;

  SplashScreen(this.future);

  @override
  Widget build(BuildContext context) {
    print("building splash screen");
    futureAndPop() async {
      await Future.delayed(Duration(seconds: 1));
      await future;
      Navigator.of(context).pop();
    }

    return Scaffold(
      backgroundColor: Palette.light,
      body: FutureBuilder(
          future: futureAndPop(),
          builder: (context, snapshot) {
            return Container(
              color: Palette.primary,
              child: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset("assets/nutmeg_white.png", width: 116, height: 46),
                        SizedBox(height: 30),
                        CircularProgressIndicator(
                            valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white)),
                      ])),
            );
          }),
    );
  }
}