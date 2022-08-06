import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/router/AutoRouter.gr.dart';

class AppState extends ChangeNotifier {

  List<PageRouteInfo> stack = List<PageRouteInfo>.of([AvailableMatchesRoute()]);

  bool loadingDone = false;
  String? selectedMatch;

  void setLoadingDone() {
    loadingDone = true;
    notifyListeners();
  }

  void setSelectedMatch(String matchId) {
    selectedMatch = matchId;
    notifyListeners();
  }

  void addToStack(PageRouteInfo p) {
    this.stack.add(p);
    print("notifying add to stack");
    notifyListeners();
  }

  @override
  String toString() {
    return 'AppState{stack: $stack, loadingDone: $loadingDone}';
  }
}
//   List<NutmegPage> stack = List<NutmegPage>.of([NutmegPage.HOME]);
//
//   void setStack(List<NutmegPage> stack, [String matchId]) {
//    this.stack = stack;
//    this.selectedMatch = matchId;
//    print("notifying set stack");
//    print(stack);
//    notifyListeners();
//   }
//

//
//   void removeLastFromStack() {
//     this.stack.removeLast();
//     print("notifying remove last from stack");
//     notifyListeners();
//   }
//

//   //
//   // void setPage(NutmegPage p) {
//   //   page = p;
//   //   notifyListeners();
//   // }
//

// }
