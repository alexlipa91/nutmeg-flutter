import 'package:flutter/material.dart';
import 'package:nutmeg/utils/UiUtils.dart';


class ModalPaymentDescriptionArea extends StatelessWidget {
  static var divider = Divider(color: Palette.grey_lighter, height: 0);

  final List<Widget> rows;
  final Widget finalRow;

  const ModalPaymentDescriptionArea({Key key, this.rows, this.finalRow})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var rowWidgets = [];
    if (rows.isNotEmpty) {
      rowWidgets.add(divider);
      rowWidgets.add(SizedBox(height: 16));
      rowWidgets.addAll(rows.map((r) => Padding(
            padding: EdgeInsets.only(top: 4, bottom: 4),
            child: r,
          )));
      rowWidgets.add(SizedBox(height: 16));
    }
    rowWidgets.add(divider);
    rowWidgets.add(SizedBox(height: 16));
    rowWidgets.add(finalRow);
    rowWidgets.add(SizedBox(height: 16));

    return Container(
      child: Column(
        children: List<Widget>.from(rowWidgets),
      ),
    );
  }
}
