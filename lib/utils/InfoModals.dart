import 'package:flutter/cupertino.dart';

import 'UiUtils.dart';

class GenericInfoModal extends StatelessWidget {

  final String title;
  final String body;
  final Widget bottomWidget;

  const GenericInfoModal.withBottom({Key key, this.title, this.body, this.bottomWidget}) : super(key: key);

  const GenericInfoModal({Key key, this.title, this.body}) : bottomWidget = null, super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // fixme why not having borders?
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.only(topRight: Radius.circular(10)),
      ),
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
    );
  }
}