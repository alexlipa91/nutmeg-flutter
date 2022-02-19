import 'package:flutter/material.dart';
import 'package:nutmeg/utils/UiUtils.dart';


class InfoContainer extends StatelessWidget {

  static var borderRadius = BorderRadius.all(Radius.circular(10));
  static var boxShadow = BoxShadow(
    color: Palette.black.withOpacity(0.1),
    spreadRadius: 0,
    blurRadius: 20,
    offset: Offset(0, 10),
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
        padding = EdgeInsets.symmetric(horizontal: 16, vertical: 16);

  InfoContainer.withoutPadding({this.child}) :
        padding = EdgeInsets.all(0);

  @override
  Widget build(BuildContext context) {
    return Container(
        // margin: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        decoration: boxDecoration,
        child: Padding(
          padding: padding,
          child: child,
        ));
  }
}
