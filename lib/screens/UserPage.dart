import 'package:flutter/material.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/screens/admin/Matches.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/AppBar.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:nutmeg/widgets/Buttons.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';


class UserPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    // don't watch this or when logout things will break
    var userState = context.read<UserState>();
    var userDetails = userState.getUserDetails();

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
          child: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Text("Account", style: TextPalette.h1Default)),
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
                              Text(userDetails.name ?? "N/A", style: TextPalette.h2),
                              SizedBox(height: 10),
                              Text(userDetails.email, style: TextPalette.bodyText)
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
                                Text(userDetails.getCreditsAvailable(),
                                    style: TextPalette.h2),
                                SizedBox(height: 20),
                                Text("Available Credits", style: TextPalette.h3)
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
                                  MatchesController.numPlayedByUser(
                                              context.watch<MatchesState>(),
                                              userDetails.getUid())
                                          .toString(),
                                  style: TextPalette.h2),
                              SizedBox(height: 20),
                              Text("Games Played", style: TextPalette.h3)
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
                      LinkInfo(text: "Follow us on Instagram", onTap: () async {
                        var url = 'https://www.instagram.com/nutmegapp/';

                            if (await canLaunch(url)) {
                              await launch(
                                url,
                                universalLinksOnly: true,
                              );
                            } else {
                              throw 'There was a problem to open the url: $url';
                            }
                          },),
                          // LinkInfo(text: "Terms and Conditions"),
                          Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ButtonWithLoader("LOGOUT", () async {
                                    await UserController.logout(
                                        context.read<UserState>());
                                    Navigator.pop(context);
                                  }),
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
                                    child: ButtonWithoutLoader("ADMIN AREA", () async {
                                      await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  AdminAvailableMatches()));
                                    }),
                                  )
                                ],
                              ),
                            )
                        ])),
                      ),
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
