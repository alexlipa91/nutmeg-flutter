import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'UiUtils.dart';


class GenericInfoModal<T> {

  final String title;
  final String body;
  final Widget bottomWidget;

  const GenericInfoModal.withBottom({Key key, this.title, this.body, this.bottomWidget});

  const GenericInfoModal({Key key, this.title, this.body}) : bottomWidget = null;

  Future<T> show(BuildContext context) {
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
                children: <Widget>[
                  Text(title, style: TextPalette.h2),
                  SizedBox(height: 12),
                  Text(
                    body,
                    style: TextPalette.bodyText,
                  ),
                  SizedBox(height: 12),
                  if (bottomWidget != null)
                    bottomWidget
                ],
              ),
            ),
          ),
        )
    );
  }
}