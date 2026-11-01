import 'navigate_url_stub.dart' if (dart.library.html) 'navigate_url_web.dart' as impl;

/// Navigate to [url] in a new tab on web, or external browser on mobile.
Future<void> navigateToUrl(String url) => impl.navigateToUrlPlatform(url);

/// Listen for a postMessage from the Stripe return tab (web only).
void listenForStripeReturn(void Function() onComplete) =>
    impl.listenForStripeReturn(onComplete);

/// If this is the Stripe return tab, notify opener and close. Returns true if closing.
bool handleStripeReturnTab() => impl.handleStripeReturnTab();
