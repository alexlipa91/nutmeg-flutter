import 'package:flutter/material.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/AppBar.dart';
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
      appBar: AdminAreaAppBarInverted(),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            color: Palette.light,
            child: (subsWidgets.isEmpty)
                ? Text("No subscriptions yet.", style: TextPalette.bodyText)
                : SingleChildScrollView(
                    child: Column(
                      children: [Column(children: subsWidgets)],
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
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Subscription id", style: TextPalette.h3),
                              Text(subscription.documentId,
                                  style: TextPalette.bodyText),
                            ]),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("User id", style: TextPalette.h3),
                              Text(subscription.userId,
                                  style: TextPalette.bodyText),
                            ]),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("User email", style: TextPalette.h3),
                              Text(snapshot.data.email,
                                  style: TextPalette.bodyText),
                            ]),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Status", style: TextPalette.h3),
                              Text(
                                  subscription.status
                                      .toString()
                                      .split(".")
                                      .last,
                                  style: TextPalette.bodyText),
                            ]),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Created at", style: TextPalette.h3),
                              Text(
                                  getFormattedDate(
                                      subscription.createdAt.toDate()),
                                  style: TextPalette.bodyText),
                            ]),
                      ],
                    ),
                  ),
                )
              ]),
            ),
    );
  }
}
