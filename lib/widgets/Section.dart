import 'package:flutter/material.dart';
import 'package:nutmeg/utils/UiUtils.dart';


class Section extends StatelessWidget {

  final String title;
  final String titleType;
  final Widget body;
  final double topSpace;
  final double belowTitleSpace;

  const Section({Key? key, required this.title, required this.body,
    this.topSpace = 32, this.belowTitleSpace = 10,
    this.titleType = "normal"}) : super(key: key);

  TextStyle? _getStyle() {
    if (titleType == "big")
      return TextPalette.h2;
    if (titleType == "normal")
      return TextPalette.h4;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: topSpace),
          Text(title, style: _getStyle(), textAlign: TextAlign.start,),
          SizedBox(height: belowTitleSpace),
          body
        ]
      ),
    );
  }
}

