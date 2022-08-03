import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/screens/UserPage.dart';

import '../screens/AvailableMatches.dart';
import '../screens/Launch.dart';
import '../screens/Login.dart';
import '../screens/MatchDetails.dart';
import '../state/AppState.dart';

enum NutmegPage {
  HOME, USER, LOGIN, MATCH, UNKNOWN
}

class AppRoutePath {
  final String matchId;
  final NutmegPage page;

  AppRoutePath(this.page, [this.matchId = null]);

  @override
  String toString() {
    return 'AppRoutePath{matchId: $matchId, page: $page';
  }
}

class AppRouterDelegate extends RouterDelegate<AppRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<AppRoutePath> {

  final AppState appState;

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  AppRouterDelegate(this.appState) {
   print("created router delegate");
  }

  Page _buildPage(String name, Widget widget) =>
      MaterialPage(
          key: ValueKey(name),
          name: name,
          child: widget);

  @override
  Widget build(BuildContext context) {
    print("rebuilding stack: $appState");
    var pageStack;

    if (!appState.loadingDone) {
      print("going in loading branch");
      pageStack = [
        _buildPage("Launch", LaunchWidget())
      ];
    } else {
      print("going in main branch");
      pageStack = [
        _buildPage("AvailableMatches", AvailableMatches()),
        if (appState.page == NutmegPage.MATCH && appState.selectedMatch != null)
          _buildPage("MatchDetails", MatchDetails(matchId: appState.selectedMatch)),
        if (appState.page == NutmegPage.USER)
          _buildPage("UserPage", UserPage()),
        if (appState.page == NutmegPage.LOGIN)
          _buildPage("Login", Login())
      ];
    }
    print("built stack with ${pageStack.length} pages");

    return Navigator(
      key: navigatorKey,
      pages: pageStack,
      onPopPage: (route, result) {
        print("popping " + route.settings.name);

        if (!route.didPop(result)) {
          return false;
        }

        if (route.settings.name == "MatchDetails") {
          appState.setSelectedMatch(null);
        } else if (route.settings.name == "Login") {
          appState.setPage(NutmegPage.LOGIN);
        } else if (route.settings.name == "UserPage") {
          appState.setPage(NutmegPage.USER);
        }
        return true;
      },
    );
  }

  @override
  Future<void> setNewRoutePath(AppRoutePath configuration) async {
    print("setting route with config $configuration; current state is $appState");
    appState.page = configuration.page;

    if (configuration.page == NutmegPage.HOME) {
      appState.selectedMatch = null;
    } else if (configuration.page == NutmegPage.MATCH) {
      appState.selectedMatch = configuration.matchId;
    }
  }

  AppRoutePath get currentConfiguration {
    AppRoutePath config = AppRoutePath(appState.page, appState.selectedMatch);
    print("current config updated $config");
    return config;
  }
}

class AppRouteInformationParser extends RouteInformationParser<AppRoutePath> {
  const AppRouteInformationParser() : super();

  @override
  Future<AppRoutePath> parseRouteInformation(
      RouteInformation routeInformation) async {
    final uri = Uri.parse(routeInformation.location);
    AppRoutePath appRoutePath;

    if (routeInformation.location == "/")
      appRoutePath = AppRoutePath(NutmegPage.HOME);
    else if (uri.pathSegments.length == 2 && uri.pathSegments[0] == "match")
      appRoutePath = AppRoutePath(NutmegPage.MATCH, uri.pathSegments[1]);
    else if (routeInformation.location == "/user")
      appRoutePath = AppRoutePath(NutmegPage.USER);
    else if (routeInformation.location == "/login")
      appRoutePath = AppRoutePath(NutmegPage.LOGIN);
    else
      appRoutePath = AppRoutePath(NutmegPage.UNKNOWN);

    print("parse route info from location ${routeInformation.location} "
        "to appRoutePath $appRoutePath");
    return appRoutePath;
  }

  @override
  RouteInformation restoreRouteInformation(configuration) {
    String location;

    if (configuration.page == NutmegPage.HOME)
      location = "/";
    else if (configuration.page == NutmegPage.MATCH)
      location = "/match/${configuration.matchId}";
    else if (configuration.page == NutmegPage.USER)
      location = "/user";
    else if (configuration.page == NutmegPage.LOGIN)
      location = "/login";

    print("restore route info from $configuration to location $location");
    return RouteInformation(location: location);
  }
}