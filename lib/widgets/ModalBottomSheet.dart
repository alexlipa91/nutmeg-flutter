import 'package:flutter/material.dart';
import 'package:nutmeg/utils/UiUtils.dart';

class ModalBottomSheet {
  static bool isOpen = false;

  static Future<T?> showNutmegModalBottomSheet<T>(
      BuildContext? context, Widget child) async {
    isOpen = true;

    var returnValue;
    if (MediaQuery.of(context!).size.width <= 700) {
      returnValue = await showModalBottomSheet<T?>(
          isScrollControlled: true,
          backgroundColor: Palette.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
          ),
          context: context,
          builder: (BuildContext context) => SafeArea(
              minimum: EdgeInsets.only(bottom: 16),
              child: SingleChildScrollView(
                  child: Padding(
                      padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                          top: 16,
                          right: 16,
                          left: 16),
                      child: Wrap(
                          alignment: WrapAlignment.center,
                          children: [Container(width: 1000, child: child)])))));
    } else {
      returnValue = await showDialog(
          context: context,
          builder: (BuildContext context) =>
              Dialog(
                backgroundColor: Palette.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
                child: Padding(
                    padding:
                    EdgeInsets.only(bottom: 16, top: 16, right: 16, left: 16),
                    child: Wrap(alignment: WrapAlignment.center, children: [
                      Container(
                          constraints: BoxConstraints(maxWidth: 500),
                          child: child)
                    ])),
              ));
    }

    isOpen = false;

    return returnValue;
  }
}
