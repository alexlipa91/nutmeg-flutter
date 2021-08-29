import 'package:flutter/material.dart';
import 'package:nutmeg/utils/UiUtils.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final Function onPressed;

  PrimaryButton(this.text, this.onPressed);

  Radius getLeftRadius() => Radius.circular(0.0);

  Radius getRightRadius() => Radius.circular(0.0);

  Color getBackgroundColor() => Palette.primary;

  TextStyle getTextStyle() => TextPalette.linkStyleInverted;

  Function onPressedFunction() => onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressedFunction(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 25),
        child: Text(
          text,
          style: getTextStyle(),
        ),
      ),
      style: getStyle(),
    );
  }

  ButtonStyle getStyle() {
    return TextButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 0),
        backgroundColor: getBackgroundColor(),
        shape: RoundedRectangleBorder(
            side: BorderSide(width: 2.0, color: Colors.white),
            borderRadius: getBorderRadius()));
  }

  BorderRadius getBorderRadius() => BorderRadius.only(
      topLeft: getLeftRadius(),
      bottomLeft: getLeftRadius(),
      topRight: getRightRadius(),
      bottomRight: getRightRadius());
}

mixin LeftRounded on PrimaryButton {
  Radius getLeftRadius() => Radius.circular(50);
}

mixin RightRounded on PrimaryButton {
  Radius getRightRadius() => Radius.circular(50);
}

mixin On on PrimaryButton {
  Color getBackgroundColor() => Colors.white;

  TextStyle getTextStyle() => TextPalette.linkStyle;
}

mixin Off on PrimaryButton {
  Color getBackgroundColor() => Colors.transparent;

  TextStyle getTextStyle() => TextPalette.linkStyleInverted;
}

mixin All on PrimaryButton {}

class LeftButtonOff extends PrimaryButton with LeftRounded, Off {
  LeftButtonOff(String text, Function onPressed) : super(text, onPressed);
}

class RightButtonOff extends PrimaryButton with RightRounded, Off {
  RightButtonOff(String text, Function onPressed) : super(text, onPressed);
}

class LeftButtonOn extends PrimaryButton with LeftRounded, On {
  LeftButtonOn(String text, Function onPressed) : super(text, onPressed);
}

class RightButtonOn extends PrimaryButton with RightRounded, On {
  RightButtonOn(String text, Function onPressed) : super(text, onPressed);
}

class RoundedButton extends PrimaryButton with LeftRounded, RightRounded {
  RoundedButton(String text, Function onPressed) : super(text, onPressed);
}

class ButtonWithLoader extends StatefulWidget {
  final RoundedButton button;
  final Color loadingColor;

  ButtonWithLoader(this.button, this.loadingColor);

  @override
  State<StatefulWidget> createState() =>
      ButtonWithLoaderState(button, loadingColor);
}

class ButtonWithLoaderState extends State<ButtonWithLoader> {
  bool isOpRunning = false;

  final RoundedButton button;
  final Color loadingColor;

  ButtonWithLoaderState(this.button, this.loadingColor);

  @override
  Widget build(BuildContext context) {
    return (!isOpRunning)
        ? RoundedButton(button.text, () async {
            setState(() {
              isOpRunning = true;
            });
            await button.onPressed();
            setState(() {
              isOpRunning = false;
            });
          })
        : SizedBox(
            height: 30,
            child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(loadingColor)),
          );
  }
}
