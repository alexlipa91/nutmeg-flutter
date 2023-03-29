import 'package:flutter/material.dart';
import 'package:nutmeg/utils/UiUtils.dart';


class ModalBottomSheet {

  static Future<T?> showNutmegModalBottomSheet<T>(BuildContext? context, Widget child) async {
    var returnValue = await showModalBottomSheet<T?>(
      isScrollControlled: true,
      backgroundColor: Palette.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      context: context!,
      builder: (BuildContext context) => SafeArea(
          minimum: EdgeInsets.only(bottom: 16),
          child: SingleChildScrollView(child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 16, right: 16, left: 16),
              child: Wrap(alignment: WrapAlignment.center,
                  children: [Container(
                      width: 1000,
                      child: child)]))))
    );
    return returnValue;
  }
 }
