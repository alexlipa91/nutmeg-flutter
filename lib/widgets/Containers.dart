import 'package:flutter/material.dart';

class InfoContainer extends StatelessWidget {
  final Widget child;

  final EdgeInsets padding;

  InfoContainer({this.child}) :
        padding = EdgeInsets.symmetric(horizontal: 25, vertical: 10);

  InfoContainer.withoutMargin({this.child}) :
        padding = EdgeInsets.all(0);

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: Offset(0, 3), // changes position of shadow
            )
          ],
        ),
        child: Padding(
          padding: padding,
          child: child,
        ));
  }
}
