import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:progress_state_button/progress_button.dart';
import 'package:provider/provider.dart';
import 'package:provider/src/provider.dart';

// GENERIC STATEFUL BUTTON

class GenericButtonState extends ChangeNotifier {
  ButtonState buttonState = ButtonState.idle;

  change(ButtonState b) {
    buttonState = b;
    notifyListeners();
  }
}

class GenericStatefulButton extends StatelessWidget {
  final String text;
  final Function onPressed;

  const GenericStatefulButton({Key key, this.text, this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => GenericButtonState()),
      ],
      child: Builder(
        builder: (context) {
          var color = Palette.primary;

          return ProgressButton(
            stateWidgets: {
              ButtonState.idle:
                  Text(text, style: TextPalette.linkStyleInverted),
              ButtonState.loading:
                  Text(text, style: TextPalette.linkStyleInverted),
              ButtonState.fail:
                  Text(text, style: TextPalette.linkStyleInverted),
              ButtonState.success: Icon(Icons.check_circle, color: Colors.white)
            },
            stateColors: {
              ButtonState.idle: color,
              ButtonState.loading: color,
              ButtonState.fail: color,
              ButtonState.success: color
            },
            maxWidth: 202,
            minWidth: 50,
            minWidthStates: [ButtonState.success],
            radius: 50,
            height: 40,
            animationDuration: Duration(seconds: 3),
            progressIndicatorSize: 23,
            padding: EdgeInsets.symmetric(horizontal: 10),
            onPressed: () => onPressed(context),
            state: context.watch<GenericButtonState>().buttonState,
          );
        },
      ),
    );
  }
}