import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:provider/provider.dart';
import 'package:provider/src/provider.dart';

import '../utils/InfoModals.dart';

// GENERIC BUTTON WITH LOADER
class GenericButtonWithLoaderState extends ChangeNotifier {
  bool isLoading = false;

  change(bool b) {
    isLoading = b;
    notifyListeners();
  }
}

class GenericButtonWithLoader extends StatelessWidget {
  final String text;
  final Function? onPressed;
  final ButtonType buttonType;

  GenericButtonWithLoader(this.text, this.onPressed, this.buttonType);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (context) => GenericButtonWithLoaderState()),
      ],
      child: Builder(
        builder: (context) {
          var _isLoading =
              context.watch<GenericButtonWithLoaderState>().isLoading;

          return ElevatedButton(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: _isLoading
                  ? SizedBox(
                      height: buttonType.textStyle.fontSize,
                      width: buttonType.textStyle.fontSize,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: buttonType.loaderColor,
                      ),
                    )
                  : Text(text, style: buttonType.textStyle),
            ),
            onPressed: _isLoading
                ? null
                : (onPressed == null)
                    ? null
                    : () => onPressed!(context),
            style: ButtonStyle(
              elevation: MaterialStateProperty.all(0),
              backgroundColor:
                  MaterialStateProperty.all<Color>(buttonType.backgroundColor),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50.0))),
              side: MaterialStateProperty.all<BorderSide>(
                  BorderSide(color: buttonType.borderColor, width: 2)),
            ),
          );
        },
      ),
    );
  }
}

class GenericButtonWithLoaderAndErrorHandling extends StatelessWidget {
  final String text;
  final Function onPressed;
  final ButtonType buttonType;

  GenericButtonWithLoaderAndErrorHandling(
      this.text, this.onPressed, this.buttonType);

  @override
  Widget build(BuildContext context) {
    return GenericButtonWithLoader(text, (BuildContext context) async {
      context.read<GenericButtonWithLoaderState>().change(true);
      try {
        await onPressed(context);
      } catch (e, stack) {
        print(e);
        print(stack);
        GenericInfoModal(title: "Something went wrong").show(context);
      }
      context.read<GenericButtonWithLoaderState>().change(false);
    }, buttonType);
  }
}

abstract class ButtonType {
  late Color backgroundColor;
  late TextStyle textStyle;
  late Color borderColor;
  late Color loaderColor;
}

class Primary extends ButtonType {
  Color backgroundColor = Palette.primary;
  TextStyle textStyle = TextPalette.linkStyleInverted;
  Color borderColor = Palette.primary;
  Color loaderColor = Palette.white;
}

class Secondary extends ButtonType {
  Color backgroundColor = Colors.transparent;
  TextStyle textStyle = TextPalette.linkStyle;
  Color borderColor = Palette.primary;
  Color loaderColor = Palette.primary;
}

class Disabled extends ButtonType {
  Color backgroundColor = Colors.transparent;
  TextStyle textStyle = TextPalette.getLinkStyle(Palette.grey_lighter);
  Color borderColor = Palette.grey_lighter;
  Color loaderColor = Palette.grey_lighter;
}

class Destructive extends ButtonType {
  Color backgroundColor = Palette.destructive;
  TextStyle textStyle = TextPalette.getLinkStyle(Palette.white);
  Color borderColor = Palette.destructive;
  Color loaderColor = Palette.white;
}

class PrimaryInverted extends ButtonType {
  Color backgroundColor = Palette.white;
  TextStyle textStyle = TextPalette.linkStyle;
  Color borderColor = Palette.white;
  Color loaderColor = Palette.white;
}
