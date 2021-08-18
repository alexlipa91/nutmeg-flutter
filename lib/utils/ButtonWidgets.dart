import 'dart:ui';
import 'package:flutter/material.dart';


class ButtonWithLoaderAndPop extends StatefulWidget {
  final String text;
  final Function onPressedFunction;

  const ButtonWithLoaderAndPop({Key key, this.onPressedFunction, this.text}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ButtonWithLoaderAndPopState(onPressedFunction, text);
}

class _ButtonWithLoaderAndPopState extends State<ButtonWithLoaderAndPop> {
  final Function onPressedFunction;
  final String text;

  bool _isExecuting = false;

  _ButtonWithLoaderAndPopState(this.onPressedFunction, this.text);

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Container(
      margin: EdgeInsets.all(30.0),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
                onPressed: () async {
                  setState(() {
                    _isExecuting = true;
                  });

                  await onPressedFunction();
                  await Future.delayed(Duration(milliseconds: 500));

                  setState(() {
                    _isExecuting = false;
                  });

                  Navigator.pop(context);
                },
                child: _isExecuting
                    ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                    : Text(text,),
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