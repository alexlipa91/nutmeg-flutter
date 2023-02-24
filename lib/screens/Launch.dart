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
import 'package:nutmeg/screens/Login.dart';
import 'package:nutmeg/screens/MatchDetails.dart';
import 'package:nutmeg/screens/UserPage.dart';
import 'package:nutmeg/screens/admin/AvailableMatchesAdmin.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:provider/provider.dart';
import 'package:skeletons/skeletons.dart';

import '../Exceptions.dart';
import '../firebase_options.dart';
import '../state/LoadOnceState.dart';
import '../state/MatchesState.dart';
import '../state/UserState.dart';
import 'admin/AddOrEditMatch.dart';

final navigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  debugLogDiagnostics: true,
  urlPathStrategy: UrlPathStrategy.path,
  routes: [
    GoRoute(
      path: '/launch',
      builder: (context, state) => LaunchWidget(from: state.queryParams["from"]),
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
              ]
          ),
          GoRoute(
            path: 'createMatch',
            builder: (context, state) => CreateMatch(),
          ),
          GoRoute(
            path: 'match/:id',
            builder: (context, state) {
              var keyString = "MatchDetails-${state.params["id"]}-"
                  "${state.queryParams.entries
                  .map((e) => "${e.key}-${e.value}").join("-")}";
              return MatchDetails(
                key: ValueKey(keyString),
                matchId: state.params["id"]!,
                paymentOutcome: state.queryParams["payment_outcome"]);
            },
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => CreateMatch.edit(
                    context.read<MatchesState>().getMatch(state.params["id"]!)
                )
              )
            ]
          ),
        ]
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => AdminAvailableMatches(),
      routes: [
        GoRoute(
            path: 'match/:id',
            builder: (context, state) {
              var keyString = "AdminMatchDetails-${state.params["id"]}-"
                  "${state.queryParams.entries
                  .map((e) => "${e.key}-${e.value}").join("-")}";
              return AdminMatchDetails(
                  key: ValueKey(keyString),
                  matchId: state.params["id"]!);
            }
        ),
      ]
    )
  ],
  // redirect to the launch page
  redirect: (state) {
    var redirectUrl;
    var userState = navigatorKey.currentContext!.read<UserState>();

    if (!LaunchController.loadingDone && state.subloc != "/launch") {
      // the loading
      var from = state.location == '/' ? '' : '?from=${state.location}';
      redirectUrl = "/launch$from";
    } else if (!userState.isLoggedIn()) {
      // the pages that need login
      if ({"/createMatch", "/user", "/admin"}.contains(state.subloc))
        redirectUrl = "/login?from=${state.location}";
    } else if (!(userState.getLoggedUserDetails()!.isAdmin ?? false)
        && state.subloc == "/admin") {
      redirectUrl = "/";
    }

    return redirectUrl;
  },
);


void main() async {
  Logger.level = Level.error;
  WidgetsFlutterBinding.ensureInitialized(); //imp line need to be added first
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    FlutterError.onError = (FlutterErrorDetails details) async {
      print(details.exceptionAsString());
      print(details.stack);
      print("*** CAUGHT FROM FRAMEWORK ***");
      await FirebaseCrashlytics.instance.recordFlutterError(details);
    };
  }

  runZonedGuarded(() {
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
          builder: (context) => MaterialApp.router(
              key: navigatorKey,
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
            ),
          maximumSize: Size(812.0, 812.0), // Maximum size
          enabled: kIsWeb,
          backgroundColor: Palette.grey_light,
        ),
      ),
    ));
  }, (Object error, StackTrace stackTrace) async {
    print(error);
    print(stackTrace);
    print("**** ZONED EXCEPTION ****");
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
  });
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
        Expanded(child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/nutmeg_white.png", width: 116, height: 46),
                SizedBox(height: 30),
                CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
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
            child: Stack(children: [getBackgoundImages(context), mainWidgets])));
  }

  static Widget getBackgoundImages(BuildContext context) => Row(children: [
    Expanded(child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
              alignment: Alignment.topLeft,
              child: SvgPicture.asset('assets/launch/blob_top_left.svg')),
          Expanded(
            child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: SvgPicture.asset('assets/launch/blob_middle_middle.svg',
                  fit: BoxFit.fill,)),
          ),
          Align(
              alignment: Alignment.bottomRight,
              child: SvgPicture.asset('assets/launch/blob_bottom_right.svg'))
        ]))
  ]);
}

// Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   print("Handling a background message");
//   print('Message data: ${message.data}');
// if (message.data.containsKey("match_id")) {
//   LaunchController.goToMatchScreen(navigatorKey.currentContext, message.data["match_id"]);
// }
// }
