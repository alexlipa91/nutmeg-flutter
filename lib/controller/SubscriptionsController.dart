import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutmeg/controller/PaymentController.dart';
import 'package:nutmeg/db/SubscriptionsFirestore.dart';
import 'package:nutmeg/db/UserFirestore.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import "package:collection/collection.dart";


class SubscriptionsController {

  static Future<List<Subscription>> getMatchSubscriptionsLatestState(String matchId) async {
    List<Subscription> log = await SubscriptionsDb.getMatchSubscriptionsLog(matchId);
    if (log.isEmpty) {
      return [];
    }
    return log.groupListsBy((s) => s.userId).values.map((subs) => subs.reduce((a, b) => (a.createdAt.compareTo(b.createdAt) > 0) ? a : b)).toList();
  }

  static Future<Subscription> getMatchSubscriptionsLatestStatePerUser(
      String userId, String matchId) async {
    List<Subscription> latestStates = await getMatchSubscriptionsLatestState(matchId);
    var latestStateFilter = latestStates.where((s) => s.userId == userId);
    if (latestStateFilter.isEmpty) {
      return null;
    }
    return latestStateFilter.first;
  }
}
