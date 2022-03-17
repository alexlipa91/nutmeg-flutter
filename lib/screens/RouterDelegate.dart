import 'package:flutter/material.dart';
import 'package:nutmeg/screens/AvailableMatches.dart';
import 'package:nutmeg/screens/Launch.dart';

import 'MatchDetails.dart';

class MyRouterDelegate extends RouterDelegate<List<RouteSettings>>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<List<RouteSettings>> {
  final _pages = <Page>[];

  @override
  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Future<void> setNewRoutePath(List<RouteSettings> configuration) {
    // TODO: implement setNewRoutePath
    throw UnimplementedError();
  }

  @override
  Widget build(BuildContext context) {
    print('building delegate');
    return Navigator(
      key: navigatorKey,
      pages: List.of(_pages),
      onPopPage: _onPopPage,
    );
  }

  bool _onPopPage(Route route, dynamic result) {
    if (!route.didPop(result)) return false;
    popRoute();
    return true;
  }

  @override
  Future<bool> popRoute() {
    if (_pages.length > 1) {
      _pages.removeLast();
      notifyListeners();
      return Future.value(true);
    }
    return _confirmAppExit();
  }

  MaterialPage _createPage(RouteSettings routeSettings) {
    Widget child;
    switch (routeSettings.name) {
      case '/':
        child = LaunchWidget();
        break;
      case '/home':
        child = AvailableMatches();
        break;
      case '/match':
        child = MatchDetails();
        break;
    }
    return MaterialPage(
      child: child,
      key: Key(routeSettings.name),
      name: routeSettings.name,
      arguments: routeSettings.arguments,
    );
  }

  void pushPage({@required String name, dynamic arguments}) {
    _pages.add(_createPage(
        RouteSettings(name: name, arguments: arguments)
    ));
    notifyListeners();
  }

  Future<bool> _confirmAppExit() {
    return showDialog<bool>(
        context: navigatorKey.currentContext,
        builder: (context) {
          return AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit the app?'),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context, true),
              ),
              TextButton(
                child: const Text('Confirm'),
                onPressed: () => Navigator.pop(context, false),
              ),
            ],
          );
        });
  }
}
