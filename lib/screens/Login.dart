import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/utils/LoginUtils.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/AppBar.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Authentication.initializeFirebase();

  runApp(new MaterialApp(
    home: Login(),
    theme: appTheme,
  ));
}

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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/nutmeg_logo.png', width: 106, height: 40),
        SizedBox(height: 30),
        Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 35),
            decoration: InfoContainer.boxDecoration,
            child: GoogleSignInButton()),
        SizedBox(height: 30),
        CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
                (context.watch<LoginStatusChangeNotifier>().isSigningIn)
                    ? Colors.white
                    : Colors.transparent)),
      ],
    );
  }
}

class GoogleSignInButton extends StatelessWidget {
  final Function onPressed;

  const GoogleSignInButton({Key key, this.onPressed}) : super(key: key);

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
          await context.read<UserChangeNotifier>().loginWithGoogle();
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
                return AlertDialog(content: Text(e.code));
              });
        }

        context.read<LoginStatusChangeNotifier>().setIsSigningIn(false);

        print("user is " +
            context.read<UserChangeNotifier>().getUserDetails().getUid());
        Navigator.pop(context, true);
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
            child:
                Text('CONTINUE WITH GOOGLE', style: TextPalette.bodyText2Gray),
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
