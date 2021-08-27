import 'package:flutter/material.dart';

class InfoContainer extends StatelessWidget {
  static var borderRadius = BorderRadius.all(Radius.circular(20));
  static var boxShadow = BoxShadow(
    color: Colors.grey.withOpacity(0.5),
    spreadRadius: 5,
    blurRadius: 7,
    offset: Offset(0, 3), // changes position of shadow
  );
  static var boxDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: borderRadius,
    boxShadow: [
      boxShadow
    ],
  );

  final Widget child;

  final EdgeInsets padding;

  InfoContainer({this.child}) :
        padding = EdgeInsets.symmetric(horizontal: 25, vertical: 10);

  InfoContainer.withoutPadding({this.child}) :
        padding = EdgeInsets.all(0);

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        decoration: boxDecoration,
        child: Padding(
          padding: padding,
          child: child,
        ));
  }
}
