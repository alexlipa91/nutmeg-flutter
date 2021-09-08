import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:provider/provider.dart';

class Login extends StatelessWidget {
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
          actions: [
            Padding(
                padding: EdgeInsets.only(right: 20),
                child: InkWell(
                  child: Icon(Icons.close),
                  onTap: () => Navigator.pop(context),
                ))
          ],
        ),
        body: Container(
            constraints: BoxConstraints.expand(),
            decoration: new BoxDecoration(color: Palette.primary),
            child: LoginArea()),
      ),
    );
  }
}

class LoginArea extends StatelessWidget {

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
                    SignInButton(provider: Provider.google),
                    SignInButton(provider: Provider.facebook),
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

class GoogleSignInButton extends StatelessWidget {
  final Function onPressed;

  const GoogleSignInButton({Key key, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                  side: BorderSide(width: 1.0, color: Palette.lightGrey),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40))),
              onPressed: () async {
                context.read<LoginStatusChangeNotifier>().setIsSigningIn(true);

                try {
                  var communication = await UserController.continueWithGoogle(
                      context.read<UserState>());
                  Navigator.pop(context, communication);
                } on FirebaseAuthException catch (e) {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(content: Text(e.message));
                      });
                } on PlatformException catch (e) {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                            content: Text(e.code + " " + e.message));
                      });
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
                    image: AssetImage("assets/google_logo.png"),
                    height: 20.0,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text(
                        'CONTINUE WITH GOOGLE',
                        style: TextPalette.bodyText,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

enum Provider { facebook, google }

class SignInButton extends StatelessWidget {

  final Provider provider;

  const SignInButton({Key key, this.provider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var loginFuture;
    var backgroundColor;
    var textStyle;
    var logoPath;

    switch (provider) {
      case Provider.facebook :
        loginFuture = () => UserController.continueWithFacebook(context.read<UserState>());
        backgroundColor = UiUtils.fromHex("#4267B2");
        textStyle = GoogleFonts.roboto(color: Palette.white, fontSize: 14, fontWeight: FontWeight.w700);
        logoPath = "assets/fb_logo.png";
        break;
      case Provider.google :
        loginFuture = () => UserController.continueWithGoogle(context.read<UserState>());
        backgroundColor = Colors.transparent;
        textStyle = GoogleFonts.roboto(color: Palette.darkgrey, fontSize: 14, fontWeight: FontWeight.w700);
        logoPath = "assets/google_logo.png";
        break;
      default :
        throw Exception("Invalid provider");
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                  backgroundColor: backgroundColor,
                  side: BorderSide(width: 1.0, color: Palette.lightGrey),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40))),
              onPressed: () async {
                context.read<LoginStatusChangeNotifier>().setIsSigningIn(true);

                try {
                  var communication = await loginFuture();
                  Navigator.pop(context, communication);
                } on FirebaseAuthException catch (e) {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(content: Text(e.message));
                      });
                } on PlatformException catch (e) {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                            content: Text(e.code + " " + e.message));
                      });
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
      ),
    );
  }
}

class FacebookSignInButton extends StatelessWidget {
  final Function onPressed;

  const FacebookSignInButton({Key key, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(Colors.white),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
      ),
      onPressed: () async {
        context.read<LoginStatusChangeNotifier>().setIsSigningIn(true);

        try {
          var communication = await UserController.continueWithFacebook(
              context.read<UserState>());
          Navigator.pop(context, communication);
        } on FirebaseAuthException catch (e) {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(content: Text(e.message));
              });
        } on PlatformException catch (e) {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(content: Text(e.code + " " + e.message));
              });
        } finally {
          context.read<LoginStatusChangeNotifier>().setIsSigningIn(false);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Image(
            image: AssetImage("assets/google_logo.png"),
            height: 20.0,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text('CONTINUE WITH FACEBOOK', style: TextPalette.bodyText),
          )
        ],
      ),
    );
  }
}

class LoginStatusChangeNotifier extends ChangeNotifier {
  bool _isSigningIn = false;

  bool get isSigningIn => _isSigningIn;

  void setIsSigningIn(bool value) {
    _isSigningIn = value;
    notifyListeners();
  }
}
