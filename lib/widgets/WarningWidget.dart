import 'package:flutter/material.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/Containers.dart';

class WarningWidget extends StatelessWidget {

  final String title;
  final String body;
  final String textAction;
  final Function action;

  const WarningWidget({Key? key, required this.title, required this.body,
    required this.textAction, required this.action}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InfoContainer(
      backgroundColor: Palette.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextPalette.h2),
          SizedBox(height: 8),
          Text(body, style: TextPalette.bodyText),
          SizedBox(height: 8),
          InkWell(
              onTap: () async {
                action();
              },
              child: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(textAction, style: TextPalette.linkStyle)))
        ],
      ),
    );
  }
}
