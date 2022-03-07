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

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final backgroundColor;

  const InfoContainer({this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    this.margin = const EdgeInsets.all(0),
    this.backgroundColor = Palette.white
  });

  @override
  Widget build(BuildContext context) {
    return Container(
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: borderRadius,
    ),
    margin: margin,
    clipBehavior: Clip.none,
        child: Padding(
          padding: padding,
          child: child,
        ));
  }
}
