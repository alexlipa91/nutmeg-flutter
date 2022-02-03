import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/Buttons.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:cloud_functions/cloud_functions.dart';


var apiKey =
    "pk_live_51HyCDAGRb87bTNwHHFjJ2aRfC6SlNbAaaxOrdaPZ136H3gVdP3BYP9xW4rS0CZnImV5MrlqZWjjJ18smw7zJBhQH00mZP1Fqtm";

enum Status {
  success,
  paymentCanceled,
  paymentFailed,
  paymentSuccessButJoinFailed
}

class PaymentOutcome {
  final Status status;
  final PaymentRecap recap;

  PaymentOutcome(this.status, this.recap);
}

class CheckoutPage extends StatefulWidget {
  final PaymentRecap recap;
  final String sessionId;
  final Match match;

  CheckoutPage(this.sessionId, this.recap, this.match);

  @override
  _CheckoutPageState createState() => _CheckoutPageState(recap, match);
}

class _CheckoutPageState extends State<CheckoutPage> {
  WebViewController _controller;

  final PaymentRecap recap;
  final Match match;

  _CheckoutPageState(this.recap, this.match);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        child: Container(),
        preferredSize: Size.fromHeight(0.0),
      ),
      resizeToAvoidBottomInset: true,
      body: WebView(
        initialUrl: initialUrl,
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (controller) => _controller = controller,
        onPageFinished: (String url) {
          //<---- add this
          if (url == initialUrl) {
            _redirectToStripe();
          }
        },
        navigationDelegate: (NavigationRequest request) async {
          print(request.url);
          if (request.url.startsWith('https://example.com/succes')) {
             var status;
             try {
                await MatchesController.joinMatch(context.read<MatchesState>(),
                    match.documentId, context.read<UserState>(), recap);
                status = Status.success;
              } catch (e, s) {
                print(e);
                print(s);
                status = Status.paymentSuccessButJoinFailed;
              }

              Navigator.pop(context, status); // <-- Handle success case
          } else if (request.url.startsWith('https://example.com/cancel')) {
            Navigator.pop(context, Status.paymentCanceled); // <-- Handle cancel case
          }
          return NavigationDecision.navigate;
        },
      ),
    );
  }

  void _redirectToStripe() {
    //<--- prepare the JS in a normal string
    final redirectToCheckoutJs = '''
var stripe = Stripe(\'$apiKey\');
    
stripe.redirectToCheckout({
  sessionId: '${widget.sessionId}'
}).then(function (result) {
  result.error.message = 'Error'
});
''';
    _controller.evaluateJavascript(
        redirectToCheckoutJs); //<--- call the JS function on controller
  }

  String get initialUrl => 'https://nutmegapp.com/internal/checkout_page_start.html';
}

const kStripeHtmlPage = '''
<!DOCTYPE html>
<html>
<script src="https://js.stripe.com/v3/"></script>
<head><title>Stripe checkout</title></head>
</html>
''';

class Server {
  Future<String> createCheckout(customerId, int amountInCents) async {
    HttpsCallable callable =
        FirebaseFunctions.instanceFor(region: "europe-central2")
            .httpsCallable('create-stripe-session');
    final results = await callable(
        {'customer_id': customerId, 'amount_in_cents': amountInCents});
    return results.data["session_id"];
  }

  Future<String> createCustomer(String name, String email) async {
    HttpsCallable callable =
        FirebaseFunctions.instanceFor(region: "europe-central2")
            .httpsCallable('create-stripe-customer');
    final results = await callable({'name': name, 'email': email});
    return results.data["customer_id"];
  }
}

class PaymentSimulator extends StatelessWidget {
  final Match match;
  final PaymentRecap paymentRecap;

  const PaymentSimulator(this.match, this.paymentRecap);

  @override
  Widget build(BuildContext context) {
    future() async {
      Status status = await runPayAndPossiblyJoin(context);
      Navigator.of(context).pop(status);
    }

    return Scaffold(
      backgroundColor: Palette.light,
      body: FutureBuilder(
          future: future().catchError((err, stack) => print(err.toString())),
          builder: (context, snapshot) {
            return Container(
              color: Palette.primary,
              child: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Text("Payment simulator",
                        style: TextPalette.linkStyleInverted),
                    (snapshot.hasError)
                        ? Text(snapshot.stackTrace.toString())
                        : Image.asset("assets/nutmeg_white.png",
                            width: 116, height: 46),
                    SizedBox(height: 30),
                    CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white)),
                  ])),
            );
          }),
    );
  }

  Future<Status> runPayAndPossiblyJoin(BuildContext context) async {
    var status = await pay(context);

    if (status == Status.success) {
      try {
        await MatchesController.joinMatch(context.read<MatchesState>(),
            match.documentId, context.read<UserState>(), paymentRecap);
      } catch (e, s) {
        print(e);
        print(s);
        return Status.paymentSuccessButJoinFailed;
      }
    }

    return status;
  }

  Future<Status> pay(BuildContext context) async {
    await Future.delayed(Duration(seconds: 1));
    return await showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        color: Palette.light,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text("Choose the outcome of the payment to test",
                    style: TextPalette.linkStyle)),
            Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: RoundedButton(
                  "SUCCESS", () => Navigator.pop(context, Status.success)),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: RoundedButton("FAILURE",
                  () => Navigator.pop(context, Status.paymentFailed)),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: RoundedButton("CANCELED",
                  () => Navigator.pop(context, Status.paymentCanceled)),
            ),
          ],
        ),
      ),
    );
  }
}
