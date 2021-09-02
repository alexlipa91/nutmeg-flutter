import 'package:flutter/material.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/Containers.dart';

// main widget
class SubscriptionsMatchDetails extends StatelessWidget {
  final Match match;

  const SubscriptionsMatchDetails(this.match);

  @override
  Widget build(BuildContext context) {
    var subsWidgets =
        match.subscriptions.map((e) => SubscriptionRow(e)).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Container(
          color: Palette.light,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Column(children: subsWidgets)
                ],
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
    return FutureBuilder<UserDetails>(
      future: UserChangeNotifier.getSpecificUserDetails(subscription.userId),
      builder: (context, snapshot) => (!snapshot.hasData)
          ? Text("loading")
          : Padding(
        padding: EdgeInsets.only(top: 10),
        child: Row(children: [
                Expanded(
                  child: InfoContainer(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Subscription id: " + subscription.documentId, style: TextPalette.bodyText),
                        Text("User id: " + subscription.userId, style: TextPalette.bodyText),
                        Text("User name: " + snapshot.data.name, style: TextPalette.h2),
                        Text("Status: " + subscription.status.toString().split(".").last,
                            style: TextPalette.bodyText)
                      ],
                    ),
                  ),
                )
              ]),
          ),
    );
  }
}
