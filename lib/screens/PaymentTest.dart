import 'dart:convert';
import 'dart:io';

import 'package:cool_alert/cool_alert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/models/MatchesModel.dart';
import 'package:nutmeg/models/UserModel.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';


void main() async {
  runApp(new MaterialApp(home: MyApp()));
}

var apiKey =
    "pk_test_51HyCDAGRb87bTNwH1dlHJXwdDSIUhxqPZS3zeytnO7T9dHBxzhwiWO5E0kFYLkVdZbZ2t0LEHxjuPmKFZ32fiMjO00dWLo1DqE";
var secretKey =
    "sk_test_51HyCDAGRb87bTNwH4bDZ4nS8eQyDGQvJDt3uFOKdptndo68tkFc4Hr0lyASDEMWMMHbp53HkkXbBozZGEmlVmxP3001nYitsJu";

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Stripe Checkout Demo',
      theme: ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: PaymentPage(),
    );
  }
}

class PaymentPage extends StatefulWidget {

  final String matchId;

  const PaymentPage({Key key, this.matchId}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PaymentPageState(matchId);
}

class _PaymentPageState extends State<PaymentPage> {

  final String matchId;

  bool paymentDone = false;
  String outcome;

  _PaymentPageState(this.matchId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () async {
              final sessionId = await Server().createCheckout();
              Navigator.of(context)
                  .push(MaterialPageRoute(
                      builder: (_) => CheckoutPage(sessionId: sessionId)))
                  .then((value) => CoolAlert.show(
                      context: context,
                      type: (value == "success")
                          ? CoolAlertType.success
                          : CoolAlertType.error,
                      text: (value == "success")
                          ? "Your transaction was successful!"
                          : "Something went wrong!"))
                  .then((value) {
                    if (value == "success") {
                      context.read<MatchesModel>().joinMatch(context.read<UserModel>().user, matchId);
                    }
                    Navigator.pop(context);
              });
            },
            child: Text('Pay!'),
          ),
        ),
      ),
    );
  }
}

class CheckoutPage extends StatefulWidget {
  final String sessionId;

  const CheckoutPage({Key key, this.sessionId}) : super(key: key);

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  WebViewController _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
        navigationDelegate: (NavigationRequest request) {
          if (request.url.startsWith('https://success.com')) {
            Navigator.of(context).pop('success'); // <-- Handle success case
          } else if (request.url.startsWith('https://cancel.com')) {
            Navigator.of(context).pop('cancel'); // <-- Handle cancel case
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

  String get initialUrl =>
      'data:text/html;base64,${base64Encode(Utf8Encoder().convert(kStripeHtmlPage))}';
}

const kStripeHtmlPage = '''
<!DOCTYPE html>
<html>
<script src="https://js.stripe.com/v3/"></script>
<head><title>Stripe checkout</title></head>
</html>
''';

// fixme move to a backend
class Server {
  Future<String> createCheckout() async {
    final auth = 'Basic ' + base64Encode(utf8.encode('$secretKey:'));
    final body = {
      'payment_method_types[]': ['ideal', 'card'],
      'line_items': [
        {
          'price_data': {
            "unit_amount": 800,
            "product_data": {
              "name": "Nutmeg match",
            },
            "currency": "eur"
          },
          'quantity': 1,
        }
      ],
      'mode': 'payment',
      'success_url': 'https://success.com/{CHECKOUT_SESSION_ID}',
      'cancel_url': 'https://cancel.com/',
    };

    try {
      final result = await Dio().post(
        "https://api.stripe.com/v1/checkout/sessions",
        data: body,
        options: Options(
          headers: {HttpHeaders.authorizationHeader: auth},
          contentType: "application/x-www-form-urlencoded",
        ),
      );
      return result.data['id'];
    } on DioError catch (e, s) {
      print(e.response);
      throw e;
    }
  }
}
