import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/widgets/ModalBottomSheet.dart';

import 'UiUtils.dart';


class GenericInfoModal<T> {
  static var modalRadius = BorderRadius.vertical(top: Radius.circular(20.0));
  static var padding = EdgeInsets.only(top: 16, left: 16, right: 16);

  final String? title;
  final String? description;
  final Widget? content;
  final Widget? action;

  final double verticalSpaceBetweenElements = 16.0;

  const GenericInfoModal(
      {Key? key, this.title, this.description, this.content, this.action});

  Future<T?> show(BuildContext? context) {
    List<Widget> widgets = [
      Text(title!, style: TextPalette.h2),
      SizedBox(height: verticalSpaceBetweenElements),
      if (description != null)
        Text(description!, style: TextPalette.bodyText),
    ];

    // change space depending if description is there
    var spaceBeforeAction = verticalSpaceBetweenElements;
    if (content != null) {
      spaceBeforeAction = spaceBeforeAction - 8;
      widgets.add(SizedBox(height: verticalSpaceBetweenElements + 8));
      widgets.add(content!);
    }
    if (action != null) {
      widgets.add(SizedBox(height: spaceBeforeAction));
      widgets.add(action!);
    }

    return ModalBottomSheet.showNutmegModalBottomSheet<T>(context, Container(
      child: Padding(
        // make 32 if find visual cue
          padding: padding,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: widgets)),
    ));
  }
}
