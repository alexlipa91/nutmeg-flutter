import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/screens/CreateMatch.dart';
import 'package:nutmeg/screens/Launch.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:provider/provider.dart';
import 'package:nutmeg/utils/CrashlyticsLogger.dart';

final logger = CrashlyticsLogger('EmailLogin');

class EmailLogin extends StatelessWidget {
  final String? from;

  const EmailLogin({Key? key, this.from}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Stack(children: [
          Container(
              constraints: BoxConstraints.expand(),
              decoration: BoxDecoration(color: Palette.primary)),
          LaunchWidgetState.getBackgroundImages(context),
          EmailLoginForm(from: from),
        ]));
  }
}

class EmailLoginForm extends StatefulWidget {
  final String? from;

  const EmailLoginForm({Key? key, this.from}) : super(key: key);

  @override
  State<EmailLoginForm> createState() => _EmailLoginFormState();
}

class _EmailLoginFormState extends State<EmailLoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isNewUser = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _getFriendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password must be at least 6 characters';
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      default:
        return null;
    }
  }

  Future<void> _submit() async {
    var email = _emailController.text.trim();
    var password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await context
          .read<UserState>()
          .continueWithEmail(context, email, password, isNewUser: _isNewUser);

      // Pop EmailLogin and the Login screen behind it
      var nav = Navigator.of(context);
      nav.pop();
      nav.pop();
    } on FirebaseAuthException catch (e, stack) {
      logger.severe("Email auth error", e, stack);
      setState(
          () => _errorMessage = _getFriendlyError(e) ?? 'Authentication failed. Please try again');
    } on Exception catch (e, stack) {
      logger.severe("Email auth error", e, stack);
      setState(() => _errorMessage = 'Something went wrong. Please try again');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: 700),
                  child: InfoContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _isNewUser ? "Create account" : "Sign in",
                          style: TextPalette.h2,
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          style: TextPalette.getBodyText(Palette.black),
                          decoration:
                              CreateMatchState.getTextFormDecoration(null,
                                  hintText: 'Email'),
                        ),
                        SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextPalette.getBodyText(Palette.black),
                          decoration:
                              CreateMatchState.getTextFormDecoration(null,
                                      hintText: 'Password')
                                  .copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Palette.greyDark,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            suffixIconConstraints: null,
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            style: TextPalette.bodyText
                                .copyWith(color: Palette.destructive),
                          ),
                        ],
                        SizedBox(height: 16),
                        _isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                    color: Palette.primary))
                            : GenericButtonWithLoader(
                                _isNewUser ? "CREATE ACCOUNT" : "SIGN IN",
                                (BuildContext ctx) => _submit(),
                                Primary(),
                              ),
                        SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => setState(() {
                            _isNewUser = !_isNewUser;
                            _errorMessage = null;
                          }),
                          child: Text(
                            _isNewUser
                                ? "Already have an account? Sign in"
                                : "Don't have an account? Create one",
                            style: TextPalette.linkStyle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
