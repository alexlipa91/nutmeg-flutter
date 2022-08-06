// @CupertinoAutoRouter
// @AdaptiveAutoRouter
// @CustomAutoRouter
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nutmeg/screens/CreateMatch.dart';
import 'package:nutmeg/screens/Login.dart';
import 'package:provider/provider.dart';
import 'package:nutmeg/controller/LaunchController.dart';
import 'package:nutmeg/router/AutoRouter.gr.dart';
import 'package:nutmeg/screens/AvailableMatches.dart';
import 'package:nutmeg/screens/Launch.dart';
import 'package:nutmeg/screens/MatchDetails.dart';
import 'package:nutmeg/state/UserState.dart';

@MaterialAutoRouter(
  routes: <AutoRoute>[
    AutoRoute(page: LaunchWidget),
    AutoRoute(path: "/home", page: AvailableMatches, initial: true,
        guards: [LoadedGuard]),
    AutoRoute(path: "/match/:id", page: MatchDetails, guards: [LoadedGuard]),
    AutoRoute(path: "/login", page: Login, guards: [LoadedGuard]),
    AutoRoute(path: "/createMatch", page: CreateMatch, guards: [LoggedGuard]),
  ],
)

// extend the generated private router
class $AutoRouterAppRouter {}

class LoadedGuard extends AutoRouteGuard {

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    // the navigation is paused until resolver.next() is called with either
    // true to resume/continue navigation or false to abort navigation
    if(LaunchController.loadingDone){
      // if user is authenticated we continue
      resolver.next(true);
    } else {
      // we redirect the user to our login page
      // router.push(LaunchWidgetRoute()
      print("pushing launch widget");
      router.push(
        LaunchWidgetRoute(
          onLoadedCallback: (_) {
            LaunchController.loadingDone = true;

            router.replaceAll([
              AvailableMatchesRoute(),
              if (resolver.route.path != "/home")
                PageRouteInfo.fromMatch(resolver.route),
            ]);
            print("current stack after replace ${router.stack}");
          },
        )
      );
    }
  }
}

class LoggedGuard extends AutoRouteGuard {

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    // the navigation is paused until resolver.next() is called with either
    // true to resume/continue navigation or false to abort navigation
    if(navigatorKey.currentContext!.read<UserState>().isLoggedIn()){
      // if user is authenticated we continue
      resolver.next(true);
    } else {
      // we redirect the user to our login page
      // router.push(LaunchWidgetRoute()
      print("pushing launch widget");
      router.push(
          LoginRoute(
            onLoggedCallback: (_) {
              resolver.next();
              router.removeLast();
            },
          )
      );
    }
  }
}