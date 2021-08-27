import 'package:flutter/material.dart';
import 'package:nutmeg/utils/UiUtils.dart';

class ContainerTitleText extends StatelessWidget {

  final String text;

  const ContainerTitleText({Key key, this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(text, style: TextPalette.h2));
}