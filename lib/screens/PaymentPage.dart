import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/controller/PaymentController.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:provider/provider.dart';


var apiKey =
    "pk_test_51HyCDAGRb87bTNwH1dlHJXwdDSIUhxqPZS3zeytnO7T9dHBxzhwiWO5E0kFYLkVdZbZ2t0LEHxjuPmKFZ32fiMjO00dWLo1DqE";
var secretKey =
    "sk_test_51HyCDAGRb87bTNwH4bDZ4nS8eQyDGQvJDt3uFOKdptndo68tkFc4Hr0lyASDEMWMMHbp53HkkXbBozZGEmlVmxP3001nYitsJu";

void main() async {
  final customerId = await Server().createCustomer("abc@gmail.com", "Abc Def");
  final sessionId = await Server().createCheckout(customerId, 1000);

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => UserChangeNotifier())
    ],
    child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: CheckoutPage(sessionId: sessionId)),
  ));
}

enum Status {
  success,
  paymentCanceled,
  paymentFailed,
}

class PaymentOutcome {
  final Status status;
  final PaymentRecap recap;

  PaymentOutcome(this.status, this.recap);
}

class CheckoutPage extends StatefulWidget {
  final PaymentRecap recap;
  final String sessionId;

  const CheckoutPage({Key key, this.sessionId, this.recap})
      : super(key: key);

  @override
  _CheckoutPageState createState() => _CheckoutPageState(recap);
}

class _CheckoutPageState extends State<CheckoutPage> {
  WebViewController _controller;

  final PaymentRecap recap;

  _CheckoutPageState(this.recap);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        child: Container(),
        preferredSize: Size.fromHeight(0.0),
      ),
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
            Navigator.of(context).pop(PaymentOutcome(
                Status.success, recap)); // <-- Handle success case
          } else if (request.url.startsWith('https://cancel.com')) {
            Navigator.of(context).pop(PaymentOutcome(
                Status.paymentCanceled, recap)); // <-- Handle cancel case
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
  Future<String> createCheckout(customerId, int amountInCents) async {
    final auth = 'Basic ' + base64Encode(utf8.encode('$secretKey:'));
    final body = {
      'payment_method_types[]': ['ideal', 'card'],
      'line_items': [
        {
          'price_data': {
            "unit_amount": amountInCents,
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
      'customer': customerId
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

  Future<String> createCustomer(String email, String name) async {
    final auth = 'Basic ' + base64Encode(utf8.encode('$secretKey:'));
    final body = {'email': email, 'name': name};

    try {
      final result = await Dio().post(
        "https://api.stripe.com/v1/customers",
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

class SuccessfulPaymentSimulator extends StatelessWidget {

  final Match match;
  final PaymentRecap paymentRecap;

  const SuccessfulPaymentSimulator({Key key, this.match, this.paymentRecap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var userDetails = context.read<UserChangeNotifier>().getUserDetails();

    payAndJoin() async {
      await Future.delayed(Duration(seconds: 1));
      Navigator.of(context).pop(PaymentOutcome(Status.success, paymentRecap));
    }

    return Scaffold(
      backgroundColor: Palette.light,
      body: FutureBuilder(
          future: payAndJoin(),
          builder: (context, snapshot) {
            return Container(
              color: Palette.primary,
              child: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Payment simulator", style: TextPalette.linkStyleInverted),
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
}
