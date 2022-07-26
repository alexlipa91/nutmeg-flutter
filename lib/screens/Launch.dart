// @dart=2.9
import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_web_frame/flutter_web_frame.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:nutmeg/controller/LaunchController.dart';
import 'package:nutmeg/screens/AvailableMatches.dart';
import 'package:nutmeg/screens/CreateMatch.dart';
import 'package:nutmeg/screens/EnterDetails.dart';
import 'package:nutmeg/screens/MatchDetails.dart';
import 'package:nutmeg/screens/PlayerOfTheMatch.dart';
import 'package:nutmeg/screens/UserPage.dart';
import 'package:nutmeg/screens/admin/AddOrEditMatch.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:provider/provider.dart';
import 'package:skeletons/skeletons.dart';

import '../Exceptions.dart';
import '../state/LoadOnceState.dart';
import '../state/MatchesState.dart';
import '../state/UserState.dart';
import 'admin/AvailableMatchesAdmin.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  Logger.level = Level.error;
  WidgetsFlutterBinding.ensureInitialized(); //imp line need to be added first

  if (!kIsWeb) {
    FlutterError.onError = (FlutterErrorDetails details) async {
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
          builder: (context) => GetMaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            home: new Container(
                decoration: new BoxDecoration(color: Colors.grey.shade400),
                child: Center(child: new LaunchWidget())),
            theme: ThemeData(
              colorScheme: ColorScheme.light().copyWith(
                primary: Palette.primary,
              ),
            ),
            unknownRoute: GetPage(
              name: '/notFound',
              page: () => Scaffold(
                backgroundColor: Palette.primary,
                body: Center(child: Text("Not Found",
                  style: TextPalette.getBodyText(Palette.grey_light),)),
              )),
            getPages: [
              GetPage(
                  name: '/home',
                  page: () => AvailableMatches(),
                  transition: Transition.native),
              GetPage(
                  name: '/match/:matchId',
                  transition: Transition.native,
                  page: () => MatchDetails()),
              GetPage(
                  name: '/login/enterDetails',
                  page: () => EnterDetails(),
                  transition: Transition.native),
              GetPage(
                  name: '/user',
                  page: () => UserPage(),
                  transition: Transition.native),
              GetPage(
                  name: '/editMatch/:matchId',
                  page: () => AdminMatchDetails(),
                  transition: Transition.native),
              GetPage(
                  name: '/adminHome',
                  page: () => AdminAvailableMatches(),
                  transition: Transition.native),
              GetPage(
                  name: '/potm/:userId',
                  page: () => PlayerOfTheMatch(),
                  transition: Transition.native,
                  transitionDuration: Duration.zero),
              GetPage(
                  name: '/createMatch',
                  page: () => CreateMatch(),
                  transition: Transition.native),
            ],
          ),
          maximumSize: Size(475.0, 812.0), // Maximum size
          enabled: kIsWeb, // default is enable, when disable content is full size
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
  @override
  State<StatefulWidget> createState() => LaunchWidgetState();
}

class LaunchWidgetState extends State<LaunchWidget> {
  @override
  void initState() {
    super.initState();
    LaunchController.loadData(context)
        .catchError((e, s) => ErrorHandlingUtils.handleError(e, s, context));
  }

  void initDynamicLinks() {
    FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData dynamicLink) async {
      final Uri deepLink = dynamicLink?.link;

      if (deepLink != null) {
        LaunchController.handleLink(deepLink);
      }
    }, onError: (OnLinkErrorException e) async {
      print(e.message);
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
                Image.asset("assets/nutmeg_white.png", width: 116, height: 46),
                SizedBox(height: 30),
                CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              ],
            )
          ],
        ),
      )
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
