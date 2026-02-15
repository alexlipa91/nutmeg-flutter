import 'package:url_launcher/url_launcher.dart';

/// Non-web: open in external browser
Future<void> navigateToUrlPlatform(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

/// No-op on non-web platforms
void listenForStripeReturn(void Function() onComplete) {}

/// No-op on non-web platforms
bool handleStripeReturnTab() => false;
