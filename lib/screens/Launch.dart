import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_web_frame/flutter_web_frame.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:nutmeg/controller/LaunchController.dart';
import 'package:nutmeg/screens/AvailableMatches.dart';
import 'package:nutmeg/screens/CreateMatch.dart';
import 'package:nutmeg/screens/LeaderboardScreen.dart';
import 'package:nutmeg/screens/Login.dart';
import 'package:nutmeg/screens/MatchDetails.dart';
import 'package:nutmeg/screens/UserPage.dart';
import 'package:nutmeg/screens/admin/AvailableMatchesAdmin.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:provider/provider.dart';
import 'package:skeletons/skeletons.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import '../Exceptions.dart';
import '../firebase_options.dart';
import '../state/LoadOnceState.dart';
import '../state/MatchesState.dart';
import '../state/UserState.dart';
import '../utils/LocationUtils.dart';
import 'admin/AddOrEditMatch.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

final appRouter = GoRouter(
  debugLogDiagnostics: true,
  // urlPathStrategy: UrlPathStrategy.path,
  errorBuilder: (context, state) => AvailableMatches(),
  routes: [
    GoRoute(
      path: '/launch',
      builder: (context, state) =>
          LaunchWidget(from: state.uri.queryParameters["from"]),
    ),
    GoRoute(
        path: '/',
        builder: (context, state) => AvailableMatches(),
        routes: [
          GoRoute(path: 'login', builder: (context, state) => Login()),
          GoRoute(
              path: 'user',
              builder: (context, state) => UserPage(),
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
                var keyString = "MatchDetails-${state.pathParameters["id"]}-"
                    "${state.pathParameters.entries.map((e) => "${e.key}-${e.value}").join("-")}";
                return MatchDetails(
                    key: ValueKey(keyString),
                    matchId: state.pathParameters["id"]!,
                    paymentOutcome: state.pathParameters["payment_outcome"]);
              },
              routes: [
                GoRoute(
                    path: 'edit',
                    builder: (context, state) =>
                        CreateMatch.edit(state.pathParameters["id"]!))
              ]),
          GoRoute(
              path: 'leaderboard',
              builder: (context, state) => LeaderboardScreen()),
        ]),
    GoRoute(
        path: '/admin',
        builder: (context, state) => AdminAvailableMatches(),
        routes: [
          GoRoute(
              path: 'match/:id',
              builder: (context, state) {
                var keyString =
                    "AdminMatchDetails-${state.pathParameters["id"]}-"
                    "${state.pathParameters.entries.map((e) => "${e.key}-${e.value}").join("-")}";
                return AdminMatchDetails(
                    key: ValueKey(keyString),
                    matchId: state.pathParameters["id"]!);
              }),
        ])
  ],
  // redirect to the launch page
  redirect: (context, state) {
    var redirectUrl;
    var userState = navigatorKey.currentContext!.read<UserState>();

    if (!LaunchController.loadingDone && state.matchedLocation != "/launch") {
      // the loading
      var from =
          state.matchedLocation == '/' ? '' : '?from=${state.matchedLocation}';
      redirectUrl = "/launch$from";
    } else if (!userState.isLoggedIn()) {
      // the pages that need login
      if ({"/createMatch", "/user", "/admin"}.contains(state.matchedLocation))
        redirectUrl = "/login?from=${state.matchedLocation}";
    } else if (!(userState.getLoggedUserDetails()!.isAdmin ?? false) &&
        state.matchedLocation == "/admin") {
      redirectUrl = "/";
    }

    print("redirecting from ${state.matchedLocation} to $redirectUrl");

    return redirectUrl;
  },
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Logger.level = Level.error;
  await Firebase.initializeApp(
      // https://github.com/firebase/flutterfire/issues/10228
      // name: kIsWeb ? null : "nutmeg",
      options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    FlutterError.onError = (FlutterErrorDetails details) async {
      print(details.exceptionAsString());
      print(details.stack);
      print("*** CAUGHT FROM FRAMEWORK ***");
      await FirebaseCrashlytics.instance.recordFlutterError(details);
    };
  }
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  ErrorWidget.builder = (errorDetails) => Container();

  usePathUrlStrategy();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => UserState()),
      ChangeNotifierProvider(create: (context) => MatchesState()),
      ChangeNotifierProvider(create: (context) => LoadOnceState()),
    ],
    child: SkeletonTheme(
      shimmerGradient: LinearGradient(
        colors: [
          UiUtils.fromHex("EAEAEA"),
          UiUtils.fromHex("D5D5D5"),
          UiUtils.fromHex("EAEAEA"),
        ],
        stops: [
          0.1,
          0.8,
          0.9,
        ],
      ),
      child: FlutterWebFrame(
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
              colorScheme: ColorScheme.light().copyWith(
                primary: Palette.primary,
              ),
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
          );
        },
        maximumSize: Size(812.0, 812.0), // Maximum size
        enabled: false,
        backgroundColor: Palette.greyLight,
      ),
    ),
  ));
}

class LaunchWidget extends StatefulWidget {
  final String? from;
  final Map<String, String>? queryParams;

  const LaunchWidget({Key? key, this.from, this.queryParams}) : super(key: key);

  @override
  State<StatefulWidget> createState() => LaunchWidgetState();
}

class LaunchWidgetState extends State<LaunchWidget> {
  @override
  void initState() {
    super.initState();
    LaunchController.loadData(context, widget.from)
        .catchError((e, s) => ErrorHandlingUtils.handleError(e, s, context));
  }

  void initDynamicLinks() {
    Future<Null> Function(PendingDynamicLinkData? dynamicLink) onSuccess =
        (PendingDynamicLinkData? dynamicLink) async {
      final Uri? deepLink = dynamicLink?.link;

      if (deepLink != null) {
        LaunchController.handleLink(deepLink);
      }
    };

    FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) {
      onSuccess(dynamicLinkData);
    }).onError((error) {
      print(error);
    });
  }

  @override
  Widget build(BuildContext context) {
    var mainWidgets =
        Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Expanded(
          child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/loading.gif", width: 100),
              SizedBox(height: 30),
              Image.asset("assets/nutmeg_white.png", width: 116, height: 46),
            ],
          )
        ],
      ))
    ]);

    return Scaffold(
        body: Container(
            decoration: BoxDecoration(
              color: Palette.primary,
            ),
            child:
                Stack(children: [getBackgroundImages(context), mainWidgets])));
  }

  static Widget getBackgroundImages(BuildContext context) => Row(children: [
        Expanded(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              Align(
                  alignment: Alignment.topLeft,
                  child: SvgPicture.asset('assets/launch/blob_top_left.svg')),
              Expanded(
                child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: SvgPicture.asset(
                      'assets/launch/blob_middle_middle.svg',
                      fit: BoxFit.fill,
                    )),
              ),
              Align(
                  alignment: Alignment.bottomRight,
                  child:
                      SvgPicture.asset('assets/launch/blob_bottom_right.svg'))
            ]))
      ]);
}
