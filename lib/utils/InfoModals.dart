import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/utils/Utils.dart';

import 'UiUtils.dart';


class GenericInfoModal<T> {

  final String title;
  final String body;
  final List<Widget> bottomWidget;

  const GenericInfoModal.withBottom({Key key, this.title, this.body, this.bottomWidget});

  const GenericInfoModal({Key key, this.title, this.body}) : bottomWidget = null;

  Future<T> show(BuildContext context) {
    List<Widget> widgets = [
      Text(title, style: TextPalette.h2),
      Text(
        body,
        style: TextPalette.bodyText,
      ),
    ];
    widgets.addAll(bottomWidget);

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
              padding: EdgeInsets.only(bottom: 16, top: 24, left: 16, right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: interleave(widgets, SizedBox(height: 12))
              ),
            ),
          ),
        )
    );
  }
}