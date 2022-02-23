import 'package:flutter/material.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';


class ModalPaymentDescriptionArea extends StatelessWidget {

  static var divider = Divider(color: Palette.mediumgrey);

  final List<Widget> rows;
  final Widget finalRow;

  const ModalPaymentDescriptionArea({Key key, this.rows, this.finalRow})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var rowWidgets = [];
    if (rows.isNotEmpty) {
      rowWidgets.add(divider);
      rowWidgets.addAll(rows);
    }
    rowWidgets.add(divider);
    rowWidgets.add(finalRow);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Container(
        child: Column(
          children: List<Widget>.from(interleave(rowWidgets, SizedBox(height: 12))),
        ),
      ),
    );
  }
}
