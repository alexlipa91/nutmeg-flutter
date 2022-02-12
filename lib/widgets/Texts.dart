import 'package:flutter/material.dart';
import 'package:nutmeg/utils/UiUtils.dart';

class TextSeparatorWidget extends StatelessWidget {
  final String text;

  const TextSeparatorWidget(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 32, bottom: 16, left: 16, right: 16),
      child: Text(text, style: TextPalette.h4),
    );
  }
}