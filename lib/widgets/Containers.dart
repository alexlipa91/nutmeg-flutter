import 'package:flutter/material.dart';

class InfoContainer extends StatelessWidget {
  final Widget child;

  const InfoContainer({Key key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              spreadRadius: 0,
              blurRadius: 20,
              offset: Offset(0, 10), // changes position of shadow
            )
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: child,
        ));
  }
}
