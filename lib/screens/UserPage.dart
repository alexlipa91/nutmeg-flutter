import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/screens/Launch.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/AppBar.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';

import 'admin/Matches.dart';


class UserPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // don't watch this or when logout things will break
    var userState = context.watch<UserState>();
    var userDetails = userState.getUserDetails();

    int creditCount = (userDetails == null) ? 0 : userDetails.creditsInCents;

    return Scaffold(
      appBar: UserPageAppBar(),
      bottomSheet: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Image.asset("assets/nutmeg_white.png",
                    color: Palette.darkgrey, height: 24),
              ))
        ],
      ),
      body: SafeArea(
        child: Container(
            child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: (userState.getUserDetails() == null)
              ? Container()
              : SingleChildScrollView(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                            padding: EdgeInsets.only(top: 20),
                            child:
                                Text("Account", style: TextPalette.h1Default)),
                        Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: InfoContainer(
                              child: Row(
                            children: [
                              UserAvatar(24, null),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 30),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(userDetails.name ?? "N/A",
                                        style: TextPalette.h2),
                                    SizedBox(height: 10),
                                    Text(userDetails.email,
                                        style: TextPalette.bodyText)
                                  ],
                                ),
                              )
                            ],
                          )),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: InfoContainer(
                                  child: Column(
                                    children: [
                                      Text(formatCurrency(userDetails.creditsInCents),
                                          style: TextPalette.h2),
                                      SizedBox(height: 20),
                                      Text("Available Credits",
                                          style: TextPalette.h3)
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 20),
                              Expanded(
                                child: InfoContainer(
                                    child: Column(
                                  children: [
                                    Text(
                                        context
                                            .watch<MatchesState>()
                                            .getNumPlayedByUser(
                                                userDetails.getUid())
                                            .toString(),
                                        style: TextPalette.h2),
                                    SizedBox(height: 20),
                                    Text("Matches Played", style: TextPalette.h3)
                                  ],
                                )),
                              )
                            ],
                          ),
                        ),
                        Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: Text("USEFUL LINKS", style: TextPalette.h4)),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: InfoContainer(
                              child: Column(children: [
                            LinkInfo(
                              text: "Follow us on Instagram",
                              onTap: () async {
                                var url =
                                    'https://www.instagram.com/nutmegapp/';

                                if (await canLaunch(url)) {
                                  await launch(
                                    url,
                                    universalLinksOnly: true,
                                  );
                                } else {
                                  throw 'There was a problem to open the url: $url';
                                }
                              },
                            ),
                            // LinkInfo(text: "Terms and Conditions"),
                            Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: GenericButtonWithLoader(
                                          "LOGOUT",

                                              (BuildContext context) async {
                                            context
                                                .read<GenericButtonWithLoaderState>()
                                                .change(true);

                                            try {
                                              await Future.delayed(
                                                  Duration(milliseconds: 500),
                                                  () => UserController.logout(
                                                      context
                                                          .read<UserState>()));
                                              Navigator.of(context).pop();
                                            } catch (e, stackTrace) {
                                              print(e);
                                              print(stackTrace);
                                              Navigator.pop(context, false);
                                              return;
                                            }
                                          },
                                         Primary(),
                                      ),
                                  )
                                ],
                              ),
                            ),
                            if (userDetails.isAdmin)
                              Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                        child: GenericButtonWithLoader(
                                            "ADMIN AREA",
                                            (BuildContext context) async {
                                              await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          AdminAvailableMatches()));
                                            },
                                            Primary(),
                                        ))
                                  ],
                                ),
                              ),
                            if (userDetails.isAdmin)
                              Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: Row(
                                  children: [
                                    Text("Test Mode"),
                                    SizedBox(width: 10),
                                    Switch(
                                      value:
                                          context.watch<UserState>().isTestMode,
                                      onChanged: (value) => userState
                                          .setTestMode(!userState.isTestMode),
                                      activeTrackColor: Colors.red,
                                      activeColor: Colors.red,
                                    ),
                                    Expanded(
                                        child: Text(
                                            "It allows to see in the UI test matches"))
                                  ],
                                ),
                              ),
                            if (userDetails.isAdmin)
                              Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: Row(
                                  children: [
                                    Text("Update Credits (in cents)"),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: TextFormField(
                                          initialValue: userDetails
                                              .creditsInCents
                                              .toString(),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: <TextInputFormatter>[
                                            FilteringTextInputFormatter
                                                .digitsOnly
                                          ], // Only numbers can be
                                          onChanged: (v) {
                                            var newValue = int.tryParse(v);
                                            if (newValue != null)
                                              creditCount = newValue;
                                          }
                                          // entered
                                          ),
                                    ),
                                    SizedBox(width: 10),
                                    Container(
                                      width: 100,
                                      child: GenericButtonWithLoader(
                                          "SET",
                                          (BuildContext context) async {
                                            userDetails.creditsInCents =
                                                creditCount;
                                            userState
                                                .setUserDetails(userDetails);
                                            await UserController.editUser(userDetails);
                                            await GenericInfoModal(title: "Credits updated",
                                                body: "Your new balance is: " + formatCurrency(creditCount)).show(context);
                                          },
                                          Primary()),
                                    )
                                  ],
                                ),
                              ),
                          ])),
                        ),
                        Align(
                            alignment: Alignment.centerRight,
                            child: FutureBuilder<Tuple2<Version, String>>(
                                future: LaunchWidgetState.getVersion(),
                                builder: (context, snapshot) =>
                                    Text("v" + ((snapshot.hasData) ?
                                    (snapshot.data.item1.toString()
                                        + " build "
                                        + snapshot.data.item2) : ""),
                                        style: TextPalette.bodyText)))
                      ]),
                ),
        )),
      ),
    );
  }
}

class LinkInfo extends StatelessWidget {
  final String text;
  final Function onTap;

  const LinkInfo({Key key, this.text, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(top: 10),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(text, style: TextPalette.h3),
            SizedBox(height: 20),
            Icon(Icons.arrow_forward_ios_sharp, size: 14, color: Palette.black),
          ]),
          Divider()
        ]),
      ),
    );
  }
}
