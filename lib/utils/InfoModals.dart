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
        builder: (context) => Container(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                    padding: EdgeInsets.only(bottom: 20.0),
                    child:
                    Text(title, style: TextPalette.h2)),
                Padding(
                  padding: EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    body,
                    style: TextPalette.bodyText,
                  ),
                ),
                if (bottomWidget != null)
                  bottomWidget
              ],
            ),
          ),
        )
    );
  }
}