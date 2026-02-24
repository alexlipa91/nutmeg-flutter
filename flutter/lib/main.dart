import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nutmeg/config/app_config.dart';
import 'package:nutmeg/controller/LaunchController.dart';
import 'package:nutmeg/screens/AvailableMatches.dart';
import 'package:nutmeg/screens/CreateMatch.dart';
import 'package:nutmeg/screens/Launch.dart';
import 'package:nutmeg/screens/LeaderboardScreen.dart';
import 'package:nutmeg/screens/Login.dart';
import 'package:nutmeg/screens/MatchDetails.dart';
import 'package:nutmeg/screens/UserPage.dart';
import 'package:nutmeg/state/MatchState.dart';
import 'package:nutmeg/state/UsersState.dart';
import 'package:nutmeg/utils/CrashlyticsLogger.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:logging/logging.dart';

import '../firebase_options.dart';
import '../state/LoadOnceState.dart';
import '../state/MatchesState.dart';
import '../state/UserState.dart';
import '../utils/LocationUtils.dart';
import 'package:nutmeg/l10n/app_localizations.dart';
import 'package:nutmeg/utils/navigate_url.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final logger = CrashlyticsLogger("Main");

final appRouter = GoRouter(
  debugLogDiagnostics: true,
  refreshListenable: LaunchController.loadingNotifier,
  errorBuilder: (context, state) => AvailableMatches(),
  routes: [
    GoRoute(
      path: '/launch',
      builder: (context, state) => LaunchWidget(),
    ),
    GoRoute(
        path: '/',
        builder: (context, state) {
          return AvailableMatches();
        },
        routes: [
          GoRoute(path: 'login', builder: (context, state) => Login()),
          GoRoute(
              path: 'user',
              builder: (context, state) => UserPage(
                stripeOnboardingComplete: state.uri.queryParameters['stripe_onboarding'] == 'complete',
              ),
              routes: [
                GoRoute(path: 'login', builder: (context, state) => Login())
              ]),
          GoRoute(
            path: 'createMatch',
            builder: (context, state) => CreateMatch(),
          ),
          GoRoute(
              path: 'match/:id',
              builder: (context, state) {
                final matchId = state.pathParameters["id"]!;
                final paymentOutcome = state.uri.queryParameters["payment_outcome"];
                final matchState =
                    context.read<MatchesState>().getMatch(matchId);

                return ChangeNotifierProvider<MatchState>.value(
                  value: matchState,
                  child: MatchDetails(
                    key: ValueKey("MatchDetails-$matchId"),
                    matchId: matchId,
                    paymentOutcome: paymentOutcome,
                  ),
                );
              },
              ),
          GoRoute(
              path: 'leaderboard',
              builder: (context, state) => LeaderboardScreen()),
        ]),
  ],
  redirect: (context, state) {
    var redirectUrl;
    var userState = navigatorKey.currentContext!.read<UserState>();

    if (!LaunchController.loadingDone) {
      if (state.matchedLocation != "/launch") {
        LaunchController.pendingRedirect = state.uri.toString();
        redirectUrl = "/launch";
      }
    } else if (state.matchedLocation == "/launch") {
      // Loading finished — go to the original URL or home
      redirectUrl = LaunchController.pendingRedirect ?? "/";
      LaunchController.pendingRedirect = null;
    } else if (!userState.isLoggedIn()) {
      if ({"/createMatch", "/user", "/admin"}.contains(state.matchedLocation))
        redirectUrl = "/login?from=${state.matchedLocation}";
    } else if (!(userState.getLoggedUserDetails()!.isAdmin ?? false) &&
        state.matchedLocation == "/admin") {
      redirectUrl = "/";
    }

    if (redirectUrl != null) {
      logger.info("redirecting from ${state.uri} to $redirectUrl");
    }

    return redirectUrl;
  },
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.root.level = Level.LEVELS.firstWhere(
    (l) => l.name == AppConfig.logLevel.toUpperCase(),
    orElse: () => Level.SEVERE,
  );
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    if (!kIsWeb) {
      FlutterError.onError = (FlutterErrorDetails details) async {
        logger.severe("*** ERROR CAUGHT FROM FRAMEWORK ***",
            details.exceptionAsString(), details.stack);
      };
    }
  } catch (e, stack) {
    Logger.root.severe('Error initializing Firebase', e, stack);
  }

  // Debug: sign in as another user via INJECT_AUTH_TOKEN_UID
  if (AppConfig.injectAuthToken.isNotEmpty) {
    logger.info('Injecting auth token: ${AppConfig.injectAuthToken}');
    try {
      await FirebaseAuth.instance
          .signInWithCustomToken(AppConfig.injectAuthToken);
      Logger.root.info('Signed in with injected auth token');
    } catch (e, stack) {
      Logger.root.severe('Failed to sign in with injected token', e, stack);
    }
  }

  PlatformDispatcher.instance.onError = (error, stack) {
    if (kIsWeb) {
      logger.severe("*** ERROR CAUGHT FROM PLATFORM ***", error, stack);
    } else {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    return true;
  };

  ErrorWidget.builder = (errorDetails) => Container();

  usePathUrlStrategy();

  // If this is the Stripe return tab, notify the opener and close — don't run the app
  if (handleStripeReturnTab()) return;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserState()),
        ChangeNotifierProxyProvider<UserState, UsersState>(
          create: (_) => UsersState(),
          update: (context, userState, usersState) {
            usersState ??= UsersState();
            usersState.updateBasedOnLoggedUser(userState);
            return usersState;
          },
        ),
        ChangeNotifierProxyProvider<UserState, MatchesState>(
          create: (_) => MatchesState(),
          update: (context, userState, matchesState) {
            matchesState ??= MatchesState();
            matchesState.updateMatchStateBasedOnUser(userState);
            return matchesState;
          },
        ),
        ChangeNotifierProvider(create: (context) => LoadOnceState()),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp.router(
            key: navigatorKey,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: getLanguageLocaleWatch(context),
            scaffoldMessengerKey: scaffoldMessengerKey,
            routeInformationParser: appRouter.routeInformationParser,
            routerDelegate: appRouter.routerDelegate,
            routeInformationProvider: appRouter.routeInformationProvider,
            debugShowCheckedModeBanner: false,
            backButtonDispatcher: RootBackButtonDispatcher(),
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.light(
                primary: Palette.primary,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Palette.black,
              ),
              bannerTheme: MaterialBannerThemeData(
                contentTextStyle: TextPalette.bodyText,
              ),
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            builder: (context, child) {
              if (!AppConfig.testMode) return child ?? const SizedBox.shrink();
              return Banner(
                message: "TEST",
                location: BannerLocation.topEnd,
                color: Colors.red,
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    ),
  );
}
