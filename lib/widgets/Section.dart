import 'package:flutter/material.dart';
import 'package:nutmeg/utils/UiUtils.dart';


class Section extends StatelessWidget {

  final String title;
  final Widget body;

  const Section({Key key, this.title, this.body}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 36,),
          Text(title, style: TextPalette.h4, textAlign: TextAlign.start,),
          SizedBox(height: 10,),
          body
        ]
      ),
    );
  }
}

