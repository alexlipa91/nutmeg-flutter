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

  const InfoContainer({required this.child,
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

class InfoContainerWithTitle extends StatelessWidget {

  final String title;
  final Widget body;
  final EdgeInsets padding;

  const InfoContainerWithTitle({Key? key,
    required this.title,
    required this.body,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InfoContainer(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextPalette.h2),
        SizedBox(height: 24, width: 100,),
        body
    ],),
      padding: padding,
    );
  }
}

class NutmegDivider extends StatelessWidget {

  final bool horizontal;

  const NutmegDivider({Key? key, required this.horizontal}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var color = Palette.greyLight;
    return horizontal ? Divider(color: color) : VerticalDivider(color: color);
  }
}