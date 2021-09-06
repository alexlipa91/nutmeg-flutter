import 'package:flutter/material.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:progress_state_button/iconed_button.dart';
import 'package:progress_state_button/progress_button.dart';

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

mixin Primary on PrimaryButton {
  Color getBackgroundColor() => Colors.white;

  TextStyle getTextStyle() => TextPalette.linkStyle;
}

mixin Inverted on PrimaryButton {
  Color getBackgroundColor() => Colors.transparent;

  TextStyle getTextStyle() => TextPalette.linkStyleInverted;
}

mixin Alerted on PrimaryButton {
  Color getBackgroundColor() => Colors.red;

  TextStyle getTextStyle() => TextPalette.linkStyleInverted;
}

mixin All on PrimaryButton {}

class LeftButtonOff extends PrimaryButton with LeftRounded, Inverted {
  LeftButtonOff(String text, Function onPressed) : super(text, onPressed);
}

class RightButtonOff extends PrimaryButton with RightRounded, Inverted {
  RightButtonOff(String text, Function onPressed) : super(text, onPressed);
}

class LeftButtonOn extends PrimaryButton with LeftRounded, Primary {
  LeftButtonOn(String text, Function onPressed) : super(text, onPressed);
}

class RightButtonOn extends PrimaryButton with RightRounded, Primary {
  RightButtonOn(String text, Function onPressed) : super(text, onPressed);
}

class RoundedButton extends PrimaryButton with LeftRounded, RightRounded {
  RoundedButton(String text, Function onPressed) : super(text, onPressed);
}

class RoundedButtonAlerted extends PrimaryButton
    with LeftRounded, RightRounded, Alerted {
  RoundedButtonAlerted(String text, Function onPressed)
      : super(text, onPressed);
}

class ButtonWithLoader extends StatelessWidget {
  final String text;
  final Function onPressed;

  ButtonWithLoader(this.text, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return Container(
      // width: 30.0,
      child: ProgressButton(
        padding: EdgeInsets.all(0),
          progressIndicatorSize: 10,
          // height: 10.0,
          // minWidth: 10,
          // maxWidth: 35,
          stateWidgets: {
            ButtonState.idle: Text(
              text,
              style: TextPalette.linkStyleInverted,
            ),
            ButtonState.loading: Text(
              "LOADING",
              style: TextPalette.linkStyleInverted,
            ),
            ButtonState.success: Text(
              "LOADING",
              style: TextPalette.linkStyleInverted,
            ),
            ButtonState.fail: Text(
              "LOADING",
              style: TextPalette.linkStyleInverted,
            ),
          },
          stateColors: {
            ButtonState.idle: Palette.primary,
            ButtonState.loading: Palette.primary,
            ButtonState.fail: Palette.primary,
            ButtonState.success: Palette.primary,
          },
          onPressed: () => onPressed,
          state: ButtonState.idle),
    );
  }
}
