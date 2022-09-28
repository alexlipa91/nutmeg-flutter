import 'package:flutter/material.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/model/SportCenter.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';


// MAIN PAGE BUTTONS
class PrimaryButton extends StatelessWidget {
  final String text;
  final Function? onPressed;

  PrimaryButton(this.text, this.onPressed);

  Radius getLeftRadius() => Radius.circular(0.0);

  Radius getRightRadius() => Radius.circular(0.0);

  Color getBackgroundColor() => Palette.primary;

  Color getBorderColor() => Colors.white;

  TextStyle getTextStyle() => TextPalette.linkStyleInverted;

  Function? onPressedFunction() => onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 200,
      child: TextButton(
        onPressed: () => onPressedFunction(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 25),
          child: Text(
            text,
            style: getTextStyle(),
          ),
        ),
        style: getStyle(),
      ),
    );
  }

  ButtonStyle getStyle() {
    return TextButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 0),
        backgroundColor: getBackgroundColor(),
        shape: RoundedRectangleBorder(
            side: BorderSide(width: 2.0, color: getBorderColor()),
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

mixin Off on PrimaryButton {
  Color getBackgroundColor() => Colors.transparent;

  TextStyle getTextStyle() => TextPalette.buttonOff;

  Color getBorderColor() => Palette.grey_dark;
}

mixin Alerted on PrimaryButton {
  Color getBackgroundColor() => Colors.red;

  TextStyle getTextStyle() => TextPalette.linkStyleInverted;
}

mixin Light on PrimaryButton {
  Color getBackgroundColor() => Colors.transparent;

  TextStyle getTextStyle() => TextPalette.linkStyle;

  Color getBorderColor() => Palette.primary;
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

// OTHER BUTTONS

class ShareButton extends StatelessWidget {
  final Function onTap;
  final Color color;
  final bool withText;
  final double iconSize;

  ShareButton(this.onTap, this.color, [double size = 20])
      : withText = false,
        iconSize = size;

  @override
  Widget build(BuildContext context) {
    var icon = Icon(Icons.share, color: color, size: iconSize);

    return InkWell(
      splashColor: Palette.grey_lighter,
      onTap: () => onTap(),
      child: Container(
          width: 50,
          height: 50,
          child: Align(alignment: Alignment.center, child: icon)),
    );
  }
}

class ShareButtonWithText extends StatelessWidget {
  final Match match;
  final SportCenter sportCenter;
  final Color color;
  final bool withText;
  final double iconSize;

  ShareButtonWithText(this.match, this.sportCenter, this.color, [double size = 20])
      : withText = false,
        iconSize = size;

  @override
  Widget build(BuildContext context) {
    var icon = Icon(Icons.share, color: color, size: iconSize);

    var child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        icon,
        SizedBox(width: 5),
        Text("SHARE", style: TextPalette.linkStyle)
      ],
    );

    return InkWell(
        child: child,
        onTap: () async {
          await DynamicLinks.shareMatchFunction(match, sportCenter);
        });
  }
}
