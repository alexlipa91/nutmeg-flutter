import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/controller/PaymentController.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/screens/Launch.dart';
import 'package:nutmeg/screens/Login.dart';
import 'package:nutmeg/screens/MatchDetailsModals.dart';
import 'package:nutmeg/screens/UserPage.dart';
import 'package:nutmeg/screens/admin/Matches.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:progress_state_button/progress_button.dart';
import 'package:provider/src/provider.dart';
import 'package:url_launcher/url_launcher.dart';

var formatCurrency = NumberFormat.simpleCurrency(name: "EUR");

var stateWidgets = (text) => {
      ButtonState.idle: Text(text, style: TextPalette.linkStyleInverted),
      ButtonState.loading: Text(text, style: TextPalette.linkStyleInverted),
      ButtonState.fail: Text(text, style: TextPalette.linkStyleInverted),
      ButtonState.success: Icon(Icons.check_circle, color: Colors.white)
    };

var stateColors = {
  ButtonState.idle: Palette.primary,
  ButtonState.loading: Palette.primary,
  ButtonState.fail: Palette.primary,
  ButtonState.success: Palette.primary
};

// JOIN

class JoinButton extends StatefulWidget {
  final Match match;

  static var onJoinGameAction = (BuildContext context, Match match) async {
    var userState = context.read<UserState>();
    var matchesState = context.read<MatchesState>();

    if (!userState.isLoggedIn()) {
      try {
        AfterLoginCommunication communication = await Navigator.push(
            context, MaterialPageRoute(builder: (context) => Login()));
        if (communication != null) {
          await GenericInfoModal(title: "Welcome", body: communication.text)
              .show(context);
        }
      } catch (e) {
        // fixme proper alert
        CoolAlert.show(
            context: context,
            type: CoolAlertType.error,
            text: "Could not login");
        Navigator.pop(context);
        return;
      }
    }

    if (userState.isLoggedIn()) {
      var paymentRecap = await PaymentController.generatePaymentRecap(
          matchesState, match.documentId, userState);

      var success = await GenericInfoModal.withBottom(
          title: "Join this game",
          body:
              "You can cancel up to 24h before the game starting time to get a full refund in credits to use on your next game.\nIf you cancel after this time you won't get a refund.",
          bottomWidget: Column(
            children: [
              Divider(),
              PaymentDetailsDescription(
                  match: match, paymentRecap: paymentRecap),
            ],
          )).show(context);
      if (success != null && !success) {
        UiUtils.showGenericErrorModal(context);
      }
    }
  };

  const JoinButton({Key key, this.match}) : super(key: key);

  @override
  State<StatefulWidget> createState() => JoinButtonState(match);
}

class JoinButtonState extends State<JoinButton> {
  final Match match;

  ButtonState buttonState = ButtonState.idle;

  JoinButtonState(this.match);

  @override
  Widget build(BuildContext context) {
    var text = "JOIN GAME";

    return ProgressButton(
      stateWidgets: stateWidgets(text),
      stateColors: stateColors,
      maxWidth: 202,
      minWidth: 50,
      minWidthStates: [ButtonState.success],
      radius: 32,
      height: 43,
      progressIndicatorSize: 23,
      padding: EdgeInsets.symmetric(horizontal: 10),
      animationDuration: Duration(milliseconds: 500),
      onPressed: () async {
        setState(() {
          buttonState = ButtonState.loading;
        });
        await Future.delayed(Duration(milliseconds: 500));
        await JoinButton.onJoinGameAction(context, match);
        setState(() {
          buttonState = ButtonState.idle;
        });
      },
      state: buttonState,
    );
  }
}

// PAY WITH CREDITS

class PayWithCreditsButton extends StatefulWidget {
  final Match match;
  final PaymentRecap paymentRecap;

  const PayWithCreditsButton({Key key, this.match, this.paymentRecap})
      : super(key: key);

  @override
  State<StatefulWidget> createState() =>
      PayWithCreditsButtonState(match, paymentRecap);
}

class PayWithCreditsButtonState extends State<PayWithCreditsButton> {
  final Match match;
  final PaymentRecap paymentRecap;

  ButtonState buttonState = ButtonState.idle;

  PayWithCreditsButtonState(this.match, this.paymentRecap);

  @override
  Widget build(BuildContext context) {
    var text = "PAY WITH CREDITS";

    return ProgressButton(
      stateWidgets: stateWidgets(text),
      stateColors: stateColors,
      maxWidth: 202,
      minWidth: 50,
      minWidthStates: [ButtonState.success],
      radius: 32,
      height: 43,
      animationDuration: Duration(seconds: 3),
      progressIndicatorSize: 23,
      padding: EdgeInsets.symmetric(horizontal: 10),
      onPressed: () async {
        setState(() {
          buttonState = ButtonState.loading;
        });

        await MatchesController.joinMatch(context.read<MatchesState>(),
            match.documentId, context.read<UserState>(), paymentRecap);
        await Future.delayed(Duration(milliseconds: 500));
        setState(() {
          buttonState = ButtonState.idle;
        });

        Navigator.pop(context, true);
        await communicateSuccessToUser(context, match.documentId);
      },
      state: buttonState,
    );
  }
}

// PAY WITH MONEY

class PayWithMoneyButton extends StatefulWidget {
  final Match match;
  final PaymentRecap paymentRecap;

  const PayWithMoneyButton({Key key, this.match, this.paymentRecap})
      : super(key: key);

  @override
  State<StatefulWidget> createState() =>
      PayWithMoneyButtonState(match, paymentRecap);
}

class PayWithMoneyButtonState extends State<PayWithMoneyButton> {
  final Match match;
  final PaymentRecap paymentRecap;

  ButtonState buttonState = ButtonState.idle;

  PayWithMoneyButtonState(this.match, this.paymentRecap);

  @override
  Widget build(BuildContext context) {
    var text = "CONTINUE TO PAYMENT";

    return ProgressButton(
      stateWidgets: stateWidgets(text),
      stateColors: stateColors,
      maxWidth: 202,
      minWidth: 50,
      minWidthStates: [ButtonState.success],
      radius: 32,
      height: 43,
      animationDuration: Duration(seconds: 3),
      progressIndicatorSize: 23,
      padding: EdgeInsets.symmetric(horizontal: 10),
      onPressed: () async {
        setState(() {
          buttonState = ButtonState.loading;
        });

        var userState = context.read<UserState>();
        var userDetails = userState.getUserDetails();

        var sessionUrl;
        try {
          sessionUrl = await PaymentController.createCheckout(
              match.stripePriceId,
              userDetails.documentId,
              match.documentId,
              match.isTest);
        } catch (e) {
          print(e);
          Navigator.pop(context, false);
        }

        await launch(sessionUrl, forceSafariVC: false);
      },
      state: buttonState,
    );
  }
}

// LEAVE MATCH
class LeaveMatchButton extends StatefulWidget {
  final Match match;
  final PaymentRecap paymentRecap;

  const LeaveMatchButton({Key key, this.match, this.paymentRecap})
      : super(key: key);

  @override
  State<StatefulWidget> createState() =>
      LeaveMatchButtonState(match, paymentRecap);
}

class LeaveMatchButtonState extends State<LeaveMatchButton> {
  final Match match;
  final PaymentRecap paymentRecap;

  ButtonState buttonState = ButtonState.idle;

  LeaveMatchButtonState(this.match, this.paymentRecap);

  @override
  Widget build(BuildContext context) {
    var text = "LEAVE MATCH";

    return ProgressButton(
      stateWidgets: stateWidgets(text),
      stateColors: stateColors,
      maxWidth: 202,
      minWidth: 50,
      minWidthStates: [ButtonState.success],
      radius: 32,
      height: 43,
      animationDuration: Duration(seconds: 3),
      progressIndicatorSize: 23,
      padding: EdgeInsets.symmetric(horizontal: 10),
      onPressed: () async {
        setState(() {
          buttonState = ButtonState.loading;
        });

        try {
          await MatchesController.leaveMatch(context.read<MatchesState>(),
              match.documentId, context.read<UserState>());
        } catch (e, stackTrace) {
          print(e);
          print(stackTrace);
          Navigator.pop(context, false);
          return;
        }

        await Future.delayed(Duration(milliseconds: 500));
        Navigator.of(context).pop(true);

        GenericInfoModal.withBottom(
            title: formatCurrency.format(match.pricePerPersonInCents / 100) +
                " credits were added to your account",
            body:
                "You can find your credits in your account page. Next time you join a game they will be automatically used.",
            bottomWidget: Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: InkWell(
                  onTap: () {
                    Navigator.pushReplacement(navigatorKey.currentContext,
                        MaterialPageRoute(builder: (context) => UserPage()));
                  },
                  child:
                      Text("GO TO MY ACCOUNT", style: TextPalette.linkStyle)),
            )).show(context);
      },
      state: buttonState,
    );
  }
}

// LOGOUT
class LogoutButton extends StatefulWidget {
  final Match match;
  final PaymentRecap paymentRecap;

  const LogoutButton({Key key, this.match, this.paymentRecap})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => LogoutButtonState();
}

class LogoutButtonState extends State<LogoutButton> {
  ButtonState buttonState = ButtonState.idle;

  @override
  Widget build(BuildContext context) {
    var text = "LOGOUT";

    return ProgressButton(
      stateWidgets: stateWidgets(text),
      stateColors: stateColors,
      maxWidth: 202,
      minWidth: 50,
      minWidthStates: [ButtonState.success],
      radius: 32,
      height: 43,
      animationDuration: Duration(seconds: 3),
      progressIndicatorSize: 23,
      padding: EdgeInsets.symmetric(horizontal: 10),
      onPressed: () async {
        setState(() {
          buttonState = ButtonState.loading;
        });

        try {
          await Future.delayed(Duration(milliseconds: 500),
              () => UserController.logout(context.read<UserState>()));
          Navigator.of(context).pop();
        } catch (e, stackTrace) {
          print(e);
          print(stackTrace);
          Navigator.pop(context, false);
          return;
        }

        await Future.delayed(Duration(milliseconds: 500));
        Navigator.of(context).pop(true);
      },
      state: buttonState,
    );
  }
}


// GENERIC STATELESS BUTTON

class GenericStatelessButton extends StatelessWidget {
  final String text;
  final Function onPressed;

  const GenericStatelessButton({Key key, this.text, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProgressButton(
      stateWidgets: stateWidgets(text),
      stateColors: stateColors,
      maxWidth: 202,
      minWidth: 50,
      minWidthStates: [ButtonState.success],
      radius: 32,
      height: 43,
      animationDuration: Duration(seconds: 3),
      progressIndicatorSize: 23,
      padding: EdgeInsets.symmetric(horizontal: 10),
      onPressed: () => onPressed()
    );
  }
}
