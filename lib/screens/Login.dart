import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/screens/Launch.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:provider/provider.dart';
import '../state/LoginStatusChangeNotifier.dart';


class Login extends StatelessWidget {

  final String? from;

  const Login({Key? key, this.from}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (context) => LoginStatusChangeNotifier()),
      ],
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Container(),
          actions: [
            Padding(
                padding: EdgeInsets.only(right: 20),
                child: InkWell(
                  child: Icon(Icons.close),
                  onTap: () =>
                      GoRouter.of(context).location == "/user/login"
                          ? context.go("/") : context.pop()
                )
            )
          ],
        ),
        body: Stack(children: [
          Container(
            constraints: BoxConstraints.expand(),
            decoration: new BoxDecoration(color: Palette.primary)),
          LaunchWidgetState.getBackgoundImages(context),
          LoginArea(from: from)
        ])
      ),
    );
  }
}

class LoginArea extends StatelessWidget {

  final String? from;

  const LoginArea({Key? key, this.from}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/nutmeg_white.png', width: 106, height: 40),
          SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: InfoContainer(
                    child: Column(
                  children: [
                    SignInButton(provider: Provider.google, from: from),
                    SizedBox(height: 16),
                    SignInButton(provider: Provider.facebook, from: from),
                    if (!kIsWeb && Platform.isIOS)
                      Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: SignInButton(provider: Provider.apple,
                              from: from)),
                  ],
                )),
              ),
            ],
          ),
          SizedBox(height: 30),
          CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                  (context.watch<LoginStatusChangeNotifier>().isSigningIn)
                      ? Colors.white
                      : Colors.transparent)),
        ],
      ),
    );
  }
}

enum Provider { facebook, google, apple }

class SignInButton extends StatelessWidget {

  final Provider provider;
  final String? from;

  const SignInButton({Key? key, required this.provider, this.from})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var loginFuture;
    var backgroundColor;
    var textStyle;
    var logoPath;

    switch (provider) {
      case Provider.facebook :
        loginFuture = () => UserController.continueWithFacebook(context);
        backgroundColor = UiUtils.fromHex("#4267B2");
        textStyle = GoogleFonts.roboto(color: Palette.white, fontSize: 14, fontWeight: FontWeight.w700);
        logoPath = "assets/login/fb_logo.png";
        break;
      case Provider.google :
        loginFuture = () => UserController.continueWithGoogle(context);
        backgroundColor = Colors.transparent;
        textStyle = GoogleFonts.roboto(color: Palette.grey_dark, fontSize: 14, fontWeight: FontWeight.w700);
        logoPath = "assets/login/google_logo.png";
        break;
      case Provider.apple :
        loginFuture = () => UserController.continueWithApple(context);
        backgroundColor = Colors.black;
        textStyle = GoogleFonts.roboto(color: Palette.white, fontSize: 14, fontWeight: FontWeight.w700);
        logoPath = "assets/login/apple_logo.png";
        break;
      default :
        throw Exception("Invalid provider");
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: backgroundColor,
                side: BorderSide(width: 1.0, color: Palette.grey_light),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40))
            ),
            onPressed: () async {
              context.read<LoginStatusChangeNotifier>().setIsSigningIn(true);

              try {
                await loginFuture();
                context.pop();
              } on Exception catch (e, stack) {
                print(e);
                print(stack);
                GenericInfoModal(title: "Sign-in failed",
                    description: "Please try again or reach out for support").show(context);
              } finally {
                context
                    .read<LoginStatusChangeNotifier>()
                    .setIsSigningIn(false);
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Image(
                  image: AssetImage(logoPath),
                  height: 20.0,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      'CONTINUE WITH ' + provider.toString().split(".").last.toUpperCase(),
                      style: textStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              ],
            ),
          ),
        )
      ],
    );
  }
}

