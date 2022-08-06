import 'package:flutter/material.dart';
import 'package:nutmeg/screens/CreateMatch.dart';
import 'package:nutmeg/screens/UserPage.dart';
import 'package:nutmeg/state/UserState.dart';

import '../screens/AvailableMatches.dart';
import '../screens/Launch.dart';
import '../screens/Login.dart';
import '../screens/MatchDetails.dart';
import '../state/AppState.dart';

// enum NutmegPage {
//   LAUNCH, HOME, USER, LOGIN, MATCH, CREATE_MATCH, UNKNOWN
// }
//
// class AppRoutePath {
//   final String matchId;
//   final NutmegPage page;
//
//   AppRoutePath(this.page, [this.matchId]);
//
//   @override
//   String toString() {
//     return 'AppRoutePath{matchId: $matchId, page: $page}';
//   }
// }
//
// class AppRouterDelegate extends RouterDelegate<AppRoutePath>
//     with ChangeNotifier, PopNavigatorRouterDelegateMixin<AppRoutePath> {
//
//   final AppState appState;
//   final UserState userState;
//
//   @override
//   final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
//
//   AppRouterDelegate(this.appState, this.userState);
//
//   Page _buildPage(NutmegPage p, Widget w) {
//     return MaterialPage(
//         key: ValueKey(p.toString().split(".").last),
//         name: p.toString().split(".").last,
//         child: w);
//   }
//
//   List<Page> _buildPages() {
//     List<NutmegPage> stack;
//     if (!appState.loadingDone)
//      stack = List<NutmegPage>.of([NutmegPage.LAUNCH]);
//     else {
//       stack = appState.stack;
//
//       if (!userState.isLoggedIn() && stack.last == NutmegPage.CREATE_MATCH)
//         stack.add(NutmegPage.LOGIN);
//     }
//
//     print("building stack $stack");
//
//     return stack.map((p) {
//       switch (p) {
//         case NutmegPage.LAUNCH: return _buildPage(p, LaunchWidget());
//         case NutmegPage.CREATE_MATCH: return _buildPage(p, CreateMatch());
//         case NutmegPage.LOGIN: return _buildPage(p, Login());
//         case NutmegPage.MATCH: return _buildPage(p,
//             MatchDetails(matchId: appState.selectedMatch));
//         case NutmegPage.HOME: return _buildPage(p, AvailableMatches());
//         case NutmegPage.USER: return _buildPage(p, UserPage());
//         case NutmegPage.UNKNOWN: return null;
//       }
//     }).toList();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     print("rebuilding stack: $appState");
//     // var pageStack;
//
//     // if (!appState.loadingDone) {
//     //   print("going in loading branch");
//     //   pageStack = [
//     //     _buildPage(appState)
//     //   ];
//     // } else {
//     //   print("going in main branch");
//     //   pageStack = [
//     //     _buildPage("AvailableMatches", AvailableMatches()),
//     //     if (appState.page == NutmegPage.MATCH && appState.selectedMatch != null)
//     //       _buildPage("MatchDetails", MatchDetails(matchId: appState.selectedMatch)),
//     //     if (appState.page == NutmegPage.USER)
//     //       _buildPage("UserPage", UserPage()),
//     //     if (appState.page == NutmegPage.LOGIN)
//     //       _buildPage("Login", Login()),
//     //     if (appState.page == NutmegPage.CREATE_MATCH)
//     //       _buildPage("CreateMatch", CreateMatch())
//     //   ];
//     // }
//
//     return Navigator(
//       key: navigatorKey,
//       pages: _buildPages(),
//       onPopPage: (route, result) {
//         print("popping " + route.settings.name);
//
//         if (!route.didPop(result)) {
//           return false;
//         }
//
//         // if (route.settings.name == "MatchDetails") {
//         //   appState.setSelectedMatch(null);
//         // } else if (route.settings.name == "Login") {
//         //   appState.setPage(NutmegPage.HOME);
//         // } else if (route.settings.name == "UserPage") {
//         //   appState.setPage(NutmegPage.HOME);
//         // } else if (route.settings.name == "CreateMatch") {
//         //   appState.setPage(NutmegPage.CREATE_MATCH);
//         // }
//         appState.removeLastFromStack();
//         return true;
//       },
//     );
//   }
//
//   @override
//   Future<void> setNewRoutePath(AppRoutePath configuration) async {
//     // appState.stack.add(configuration.page);
//     //
//     // if (configuration.page == NutmegPage.MATCH)
//     //   appState.selectedMatch = configuration.matchId;
//     print("setting route with config $configuration; current state is $appState");
//
//     if (appState.stack.last != configuration.page)
//       appState.stack.add(configuration.page);
//   }
//
//   AppRoutePath get currentConfiguration {
//     // AppRoutePath config = AppRoutePath(appState.stack.last, appState.selectedMatch);
//     // print("current config updated from state $appState $config");
//     // return config;
//   }
// }
//
// class AppRouteInformationParser extends RouteInformationParser<AppRoutePath> {
//   const AppRouteInformationParser() : super();
//
//   @override
//   Future<AppRoutePath> parseRouteInformation(
//       RouteInformation routeInformation) async {
//     final uri = Uri.parse(routeInformation.location);
//     AppRoutePath appRoutePath;
//
//     if (routeInformation.location == "/")
//       appRoutePath = AppRoutePath(NutmegPage.HOME);
//     else if (uri.pathSegments.length == 2 && uri.pathSegments[0] == "match")
//       appRoutePath = AppRoutePath(NutmegPage.MATCH, uri.pathSegments[1]);
//     else if (routeInformation.location == "/user")
//       appRoutePath = AppRoutePath(NutmegPage.USER);
//     else if (routeInformation.location == "/login")
//       appRoutePath = AppRoutePath(NutmegPage.LOGIN);
//     else if (routeInformation.location == "/createMatch")
//       appRoutePath = AppRoutePath(NutmegPage.CREATE_MATCH);
//     else
//       appRoutePath = AppRoutePath(NutmegPage.UNKNOWN);
//
//     print("parse route info from location ${routeInformation.location} "
//         "to appRoutePath $appRoutePath");
//     return appRoutePath;
//   }
//
//   @override
//   RouteInformation restoreRouteInformation(configuration) {
//     String location;
//
//     if (configuration.page == NutmegPage.HOME)
//       location = "/";
//     else if (configuration.page == NutmegPage.MATCH)
//       location = "/match/${configuration.matchId}";
//     else if (configuration.page == NutmegPage.USER)
//       location = "/user";
//     else if (configuration.page == NutmegPage.LOGIN)
//       location = "/login";
//     else if (configuration.page == NutmegPage.CREATE_MATCH)
//       location = "/createMatch";
//
//     print("restore route info from $configuration to location $location");
//     return RouteInformation(location: location);
//   }
// }
