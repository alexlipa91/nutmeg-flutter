import 'package:flutter/material.dart';
import 'package:nutmeg/utils/UiUtils.dart';


class ModalBottomSheet {

  static Future showNutmegModalBottomSheet(BuildContext context, Widget child) {
    return showModalBottomSheet(
      backgroundColor: Palette.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      context: context,
      builder: (BuildContext context) => child
    );
  }
 }
