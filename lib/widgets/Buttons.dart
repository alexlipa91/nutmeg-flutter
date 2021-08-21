import 'package:flutter/material.dart';
import 'package:nutmeg/utils/UiUtils.dart';

class PrimaryButton extends StatelessWidget {

  final String text;
  final Function onPressed;

  PrimaryButton(this.text, this.onPressed);

  Radius getLeftRadius() => Radius.circular(0.0);

  Radius getRightRadius() => Radius.circular(0.0);

  Color getBackgroundColor() => Palette.primary;

  TextStyle getTextStyle() => TextPalette.whiteInButton;

  @override
  Widget build(BuildContext context) {
    // fixme make the size fixed and not depending on text of the button otherwise GOING is bigger
    return TextButton(
      onPressed: onPressed,
      child: Text(
        text,
        style: getTextStyle(),
      ),
      style: getStyle(),
    );
  }

  ButtonStyle getStyle() {
    return TextButton.styleFrom(
        fixedSize: Size(170, 40),
        backgroundColor: getBackgroundColor(),
        shape: RoundedRectangleBorder(
            side: BorderSide(width: 1.0, color: Colors.white),
            borderRadius: getBorderRadius()));
  }

  BorderRadius getBorderRadius() => BorderRadius.only(
      topLeft: getLeftRadius(),
      bottomLeft: getLeftRadius(),
      topRight: getRightRadius(),
      bottomRight: getRightRadius());
}

mixin LeftRounded on PrimaryButton {
  Radius getLeftRadius() => Radius.circular(10.0);
}

mixin RightRounded on PrimaryButton {
  Radius getRightRadius() => Radius.circular(10.0);
}

mixin On on PrimaryButton {
  Color getBackgroundColor() => Colors.white;

  TextStyle getTextStyle() => TextPalette.primaryInButton;
}

mixin Off on PrimaryButton {
  Color getBackgroundColor() => Colors.transparent;

  TextStyle getTextStyle() => TextPalette.whiteInButton;
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
