import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nutmeg/state/LoginStatusChangeNotifier.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/CrashlyticsLogger.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:provider/provider.dart';
import 'package:nutmeg/l10n/app_localizations.dart';

final logger = CrashlyticsLogger('GoogleSignInButton');

class GoogleSignInButton extends StatelessWidget {
  final GoogleSignIn googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '956073807168-hiadijjqbhfssu8ou4d9fe2qv2dhhsus.apps.googleusercontent.com'
        : null,
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

      // final userCredential = await FirebaseAuth.instance.signInWithCustomToken(
      //     'eyJhbGciOiAiUlMyNTYiLCAidHlwIjogIkpXVCIsICJraWQiOiAiYzQyNDU2MmIxYjgwODY1NmNkN2Y4N2FmNGE2NDI1YjBkNzY4YTQwNyJ9.eyJpc3MiOiAiZmlyZWJhc2UtYWRtaW5zZGstb3pzeTZAbnV0bWVnLTkwOTljLmlhbS5nc2VydmljZWFjY291bnQuY29tIiwgInN1YiI6ICJmaXJlYmFzZS1hZG1pbnNkay1venN5NkBudXRtZWctOTA5OWMuaWFtLmdzZXJ2aWNlYWNjb3VudC5jb20iLCAiYXVkIjogImh0dHBzOi8vaWRlbnRpdHl0b29sa2l0Lmdvb2dsZWFwaXMuY29tL2dvb2dsZS5pZGVudGl0eS5pZGVudGl0eXRvb2xraXQudjEuSWRlbnRpdHlUb29sa2l0IiwgInVpZCI6ICJ2emtyTUw0SGRIZGJBS3RRTHBJTUJ1aWowbmwyIiwgImlhdCI6IDE3NDcwNzgzMTMsICJleHAiOiAxNzQ3MDgxOTEzfQ.RyGBs86tK2AX_4I8hcvuFN8OCGHcfuf9JguRNLoRhXHLFCuQHSk-pzNFSYUq6mQa6czAFO_ucw6vcilFStJljxBf6oU12CJ4HqVI5Xz8LIQL4zDYYo5hHFpVc3v8wD3IgsqOS-53_1QkxqAD_BDmS_eKlQKVwvi9WjuNQ0x-f7PZhRI8NrdvndfCiZHyR1k-gEFtc6gp_5Z9ESZSlmPs-0hVjZrBoAtxHqz2usr8asyiB7cN3IgRwtJ1KKLJdusc0rz6rCKYSpYbr_1ef7KXT-8KXqR0-UR6dEq4mQK4Nv4wmJhISvfBWeabjPUKnLA7t9HqSaBFecGrSFLKLnxb4Q');

      if (userCredential.user != null) {
        await context.read<UserState>().login(userCredential, context);
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
