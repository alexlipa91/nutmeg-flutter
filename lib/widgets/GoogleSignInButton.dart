import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';
import 'package:nutmeg/state/LoginStatusChangeNotifier.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

final logger = Logger('GoogleSignInButton');

class GoogleSignInButton extends StatelessWidget {
  final GoogleSignIn googleSignIn = GoogleSignIn(
    clientId:
        '956073807168-hiadijjqbhfssu8ou4d9fe2qv2dhhsus.apps.googleusercontent.com',
  );
  final String? from;

  GoogleSignInButton({Key? key, this.from}) : super(key: key);

  Future<void> _handleSignIn(BuildContext context) async {
    try {
      context.read<LoginStatusChangeNotifier>().setIsSigningIn(true);
      logger.info("signing in with google");
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();

      if (googleSignInAccount == null) {
        logger.info("googleSignInAccount is null");
        return;
      }

      final GoogleSignInAuthentication? googleSignInAuthentication =
          await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication?.accessToken,
        idToken: googleSignInAuthentication?.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        await context.read<UserState>().login(context, userCredential);
      }

      Navigator.of(context).pop();
    } catch (e, stack) {
      if (e.toString().contains('popup_closed')) {
        logger.info("Sign in popup closed by user");
        return; // Exit silently without showing error
      }

      logger.severe("error signing in", e, stack);
      await GenericInfoModal(
              title: "Sign-in failed",
              description: "Please try again or reach out for support")
          .show(context);
    } finally {
      context.read<LoginStatusChangeNotifier>().setIsSigningIn(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: Colors.transparent,
        side: BorderSide(width: 1.0, color: Palette.greyLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      ),
      onPressed: () => _handleSignIn(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Image(
            image: AssetImage('assets/login/google_logo.png'),
            height: 20.0,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                AppLocalizations.of(context)!.continueWithButton('GOOGLE'),
                style: GoogleFonts.roboto(
                    color: Palette.greyDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ),
          )
        ],
      ),
    );
  }
}
