import 'package:flutter/material.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';


class PrimaryButton extends StatelessWidget {
  final String text;
  final Function onPressed;

  PrimaryButton(this.text, this.onPressed);

  Radius getLeftRadius() => Radius.circular(0.0);

  Radius getRightRadius() => Radius.circular(0.0);

  Color getBackgroundColor() => Palette.primary;

  Color getBorderColor() => Colors.white;

  TextStyle getTextStyle() => TextPalette.linkStyleInverted;

  Function onPressedFunction() => onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 200,
      child: TextButton(
        onPressed: onPressedFunction(),
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

class RoundedButtonLight extends PrimaryButton
    with LeftRounded, RightRounded, Light {
  RoundedButtonLight(String text, Function onPressed)
      : super(text, onPressed);
}

class RoundedButtonAlerted extends PrimaryButton
    with LeftRounded, RightRounded, Alerted {
  RoundedButtonAlerted(String text, Function onPressed)
      : super(text, onPressed);
}

abstract class AbstractButtonWithLoader extends StatelessWidget {

  final String text;
  double width;
  RoundedLoadingButtonController controller;
  bool shouldAnimate;

  Future<void> onPressed(BuildContext context);

  AbstractButtonWithLoader({double width, this.text, RoundedLoadingButtonController controller, bool shouldAnimate=true}) {
    this.width = width;
    this.controller = controller;
    this.shouldAnimate = shouldAnimate;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [Container(
        // height: 40,
        width: width,
        child: RoundedLoadingButton(
          height: 35,
          animateOnTap: shouldAnimate,
          duration: Duration(milliseconds: 500),
          child: Text(text, style: TextPalette.linkStyleInverted),
          onPressed: () => onPressed(context),
          controller: controller,
          color: Palette.primary,
          loaderSize: 25,
        ),
      )],
    );
  }
}

class ButtonWithLoader extends AbstractButtonWithLoader {

  final String text;
  final Function onTap;

  ButtonWithLoader(this.text, this.onTap): super(text: text, controller: RoundedLoadingButtonController());

  @override
  Future<void> onPressed(BuildContext context) => onTap();
}

class ButtonWithoutLoader extends AbstractButtonWithLoader {

  final String text;
  final Function onTap;

  ButtonWithoutLoader(this.text, this.onTap): super(text: text, controller: RoundedLoadingButtonController(), shouldAnimate: false);

  @override
  Future<void> onPressed(BuildContext context) => onTap();
}

class ShareButton extends StatefulWidget {
  final String matchId;

  const ShareButton({Key key, this.matchId}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ShareButtonState(matchId);
}

class ShareButtonState extends State<ShareButton> {
  final String matchId;
  bool active;

  ShareButtonState(this.matchId);

  @override
  void initState() {
    active = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
        child: Icon(Icons.share, color: Colors.black),
        onTap: () async {
          if (active) {
            print("already active");
            return;
          }
          setState(() {
            active = true;
          });
          await DynamicLinks.shareMatchFunction(matchId);
          setState(() {
            print("now can go");
            active = false;
          });
        });
  }
}