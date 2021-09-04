import 'package:flutter/material.dart';
import 'package:nutmeg/db/SubscriptionsFirestore.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/AppBar.dart';
import 'package:nutmeg/widgets/Containers.dart';

// main widget
class SubscriptionHistory extends StatelessWidget {
  final String matchId;
  final String userId;

  SubscriptionHistory(this.matchId, this.userId);

  @override
  Widget build(BuildContext context) {
    var loadSubs = () async {
      var subs = await SubscriptionsDb.getMatchSubscriptionsLogPerUser(
          matchId, userId);
      return subs..sort((a,b) => b.createdAt.compareTo(a.createdAt));
    };

    return Scaffold(
      appBar: AdminAreaAppBarInverted(),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: FutureBuilder<List<Subscription>>(
            future: loadSubs(),
            builder: (context, snapshot) => (!snapshot.hasData)
                ? Text("Loading")
                : Container(
                    color: Palette.light,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Text("History for user \n" + userId + "\non match\n" + matchId, style: TextPalette.bodyText),
                          Column(
                              children: snapshot.data
                                  .map((e) => SubscriptionRow(e))
                                  .toList())
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class SubscriptionRow extends StatelessWidget {
  final Subscription subscription;

  const SubscriptionRow(this.subscription);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 10, left: 20, right: 20),
      child: InfoContainer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text("Subscription id", style: TextPalette.h3),
              Text(subscription.documentId, style: TextPalette.bodyText),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text("Created at", style: TextPalette.h3),
              Text(getFormattedDate(subscription.createdAt.toDate()), style: TextPalette.bodyText),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text("Status", style: TextPalette.h3),
              Text(subscription.status.toString().split(".").last, style: TextPalette.bodyText),
            ]),
          ],
        ),
      ),
    );
  }
}
