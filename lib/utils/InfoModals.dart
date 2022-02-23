import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'UiUtils.dart';


class GenericInfoModal<T> {
  final String title;
  final String description;
  final Widget content;
  final Widget action;

  final double verticalSpaceBetweenElements = 16.0;

  const GenericInfoModal(
      {Key key, this.title, this.description, this.content, this.action});

  Future<T> show(BuildContext context) {
    List<Widget> widgets = [
      Text(title, style: TextPalette.h2),
      SizedBox(height: verticalSpaceBetweenElements),
      Text(description, style: TextPalette.bodyText),
    ];

    // change space depending if description is there
    var spaceBeforeAction = verticalSpaceBetweenElements;
    if (content != null) {
      spaceBeforeAction = spaceBeforeAction - 8;
      widgets.add(SizedBox(height: verticalSpaceBetweenElements + 8));
      widgets.add(content);
    }
    if (action != null) {
      widgets.add(SizedBox(height: spaceBeforeAction));
      widgets.add(action);
    }

    return showModalBottomSheet<T>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      isScrollControlled: true,
      context: context,
      builder: (context) => SafeArea(
        child: Container(
          child: Padding(
              // make 32 if find visual cue
              padding:
                  EdgeInsets.only(bottom: 16, top: 24, left: 16, right: 16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: widgets)),
        ),
      ),
    );
  }
}
