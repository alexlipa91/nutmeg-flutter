import 'dart:html' as html;

/// Web: open in a new tab. The return URL will postMessage back and close itself.
Future<void> navigateToUrlPlatform(String url) async {
  html.window.open(url, '_blank');
}

/// Listen for a postMessage from the Stripe onboarding return tab.
/// When received, calls [onComplete].
void listenForStripeReturn(void Function() onComplete) {
  html.window.onMessage.listen((event) {
    if (event.data == 'stripe_onboarding_complete') {
      onComplete();
    }
  });
}

/// If the current page was opened as a Stripe return redirect,
/// notify the opener and close this tab.
/// Returns true if this tab should close (i.e. it's the return tab).
bool handleStripeReturnTab() {
  var uri = Uri.parse(html.window.location.href);
  if (uri.queryParameters['stripe_onboarding'] == 'complete' &&
      html.window.opener != null) {
    html.window.opener!.postMessage('stripe_onboarding_complete', '*');
    html.window.close();
    return true;
  }
  return false;
}
