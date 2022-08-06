import 'package:flutter/material.dart';
import 'package:nutmeg/utils/UiUtils.dart';


class TextSeparatorWidget extends StatelessWidget {
  final String text;

  const TextSeparatorWidget(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 32, bottom: 16),
      child: Text(text, style: TextPalette.h4),
    );
  }
}

class TappableLinkText extends StatelessWidget {

  final String text;
  final Function onTap;

  const TappableLinkText({Key? key, required this.text,
    required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Container(
          // width: 40,
          height: 40,
          child: Align(
              alignment: Alignment.center,
              child: Text(text, style: TextPalette.linkStyle))),
      onTap: () => onTap(context),
    );
  }
}