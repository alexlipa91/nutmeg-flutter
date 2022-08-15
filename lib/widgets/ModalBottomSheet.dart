import 'package:flutter/material.dart';
import 'package:nutmeg/utils/UiUtils.dart';


class ModalBottomSheet {

  static bool isOpen = false;

  static Future<T?> showNutmegModalBottomSheet<T>(BuildContext? context, Widget child) async {
    isOpen = true;
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
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Wrap(children: [child]))))
    );
    isOpen = false;
    return returnValue;
  }
 }
