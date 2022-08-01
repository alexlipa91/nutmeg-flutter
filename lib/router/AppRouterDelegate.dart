import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../screens/AvailableMatches.dart';
import '../screens/Launch.dart';
import '../screens/MatchDetails.dart';
import '../state/AppState.dart';

class AppRoutePath {
  final String matchId;
  final bool isUnknown;
  final bool loadingDone;

  AppRoutePath.home()
      : matchId = null,
        isUnknown = false,
        loadingDone = true;

  AppRoutePath.details(this.matchId) : isUnknown = false, loadingDone = true;

  AppRoutePath.unknown()
      : matchId = null,
        isUnknown = true, loadingDone = true;

  AppRoutePath.loading() : matchId = null,
        isUnknown = false, loadingDone = false;

  bool get isHomePage => matchId == null;
  bool get isDetailsPage => matchId != null;
}

class AppRouterDelegate extends RouterDelegate<AppRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<AppRoutePath> {

  final AppState appState;
  final GlobalKey<NavigatorState> navigatorKey;

  AppRouterDelegate(this.appState) :
        navigatorKey = GlobalKey<NavigatorState>();

  Page _buildPage(String name, Widget widget) =>
      MaterialPage(
          key: ValueKey(name),
          name: name,
          child: widget);

  @override
  Widget build(BuildContext context) {
    var pageStack;

    if (!appState.loadingDone) {
      pageStack = [
        _buildPage("Launch", LaunchWidget())
      ];
    } else {
      pageStack = [
        _buildPage("AvailableMatches", AvailableMatches()),
        if (appState.selectedMatch != null)
          _buildPage("MatchDetails", MatchDetails(matchId: appState.selectedMatch))
      ];
    }

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
        }
        return true;
      },
    );
  }

  @override
  Future<void> setNewRoutePath(AppRoutePath configuration) async {
    print("setting route");
    if (configuration.isHomePage) {
      appState.setSelectedMatch(null);
      return;
    }

    if (configuration.isDetailsPage) {
      appState.setSelectedMatch(configuration.matchId);
      return;
    }

    // TODO
    throw UnimplementedError();
  }

  AppRoutePath get currentConfiguration {
    print("config");
    if (!appState.loadingDone)
      return AppRoutePath.loading();

    print(appState.selectedMatch);
    return AppRoutePath.home();
  }
}

class AppRouteInformationParser extends RouteInformationParser<AppRoutePath> {
  const AppRouteInformationParser() : super();

  @override
  Future<AppRoutePath> parseRouteInformation(
      RouteInformation routeInformation) async {
    print("parse route info");

    final uri = Uri.parse(routeInformation.location);

    if (uri.pathSegments.length == 0)
      return AppRoutePath.home();

    if (uri.pathSegments.length == 2 && uri.pathSegments[0] == "match")
      return AppRoutePath.details(uri.pathSegments[1]);

    return AppRoutePath.unknown();
  }

  @override
  RouteInformation restoreRouteInformation(configuration) {
    print("restore route info");

    if (configuration.isHomePage)
      return RouteInformation(location: "/");

    if (configuration.isDetailsPage)
      return RouteInformation(location: "/match/${configuration.matchId}");

    // TODO: implement restoreRouteInformation
    return super.restoreRouteInformation(configuration);
  }
}