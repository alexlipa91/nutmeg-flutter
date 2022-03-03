import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutmeg/controller/LaunchController.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/AppBar.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:nutmeg/widgets/Section.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';

import '../state/UserState.dart';
import '../widgets/GenericAvailableMatches.dart';
import 'admin/AvailableMatchesAdmin.dart';

class UserPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return UserPageState();
  }
}

class UserPageState extends State<UserPage> {
  final RefreshController refreshController = RefreshController();

  @override
  void initState() {
    super.initState();
    refreshPageState();
  }

  Future<void> refreshPageState() async {
    await UserController.refreshCurrentUser(context);
  }

  @override
  Widget build(BuildContext context) {
    var userState = context.watch<UserState>();
    var userDetails = userState.getLoggedUserDetails();

    if (!userState.isLoggedIn()) return Container();

    int creditCount = (userDetails == null) ? 0 : userDetails.creditsInCents;

    var avgScore = (userDetails.getScoreMatches() == -1) ? "-"
        : userDetails.getScoreMatches().toStringAsFixed(2);

    var widgets = [
      Padding(
          padding: EdgeInsets.only(top: 20, left: 16, right: 16),
          child: Text("Account", style: TextPalette.h1Default)),
      Padding(
        padding: EdgeInsets.only(top: 20),
        child: InfoContainer(
            margin: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                UserAvatar(
                    30, context.watch<UserState>().getLoggedUserDetails()),
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
        padding: EdgeInsets.only(top: 20, left: 16, right: 16),
        child:
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: UserInfoBox(
                content: formatCurrency(userDetails.creditsInCents),
                description: "Credits"),
          ),
          SizedBox(width: 20),
          Expanded(
            child: UserInfoBox(
                content: userDetails.joinedMatches.length.toString(),
                description: "Matches Played"),
          )
        ]),
      ),
      Padding(
        padding: EdgeInsets.only(top: 20, left: 16, right: 16),
        child:
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: UserInfoBox(
                content: avgScore,
                description: "Avg Score"),
          ),
          SizedBox(width: 20),
          Expanded(
            child: UserInfoBox(
                content: userDetails.getNumManOfTheMatch().toString(),
                description: "POTM",
            ),
          )
        ]),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Section(
          title: "USEFUL LINK",
          body: InfoContainer(
              child: Column(children: [
            LinkInfo(
              text: "Follow us on Instagram",
              onTap: () async {
                var url = 'https://www.instagram.com/nutmegapp/';

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
                                  context.read<UserState>()));
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
          ])),
        ),
      ),
      if (userDetails.isAdmin)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Section(
            title: "ADMIN COMMANDS",
            body: InfoContainer(
                child: Column(children: [
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
                                builder: (context) => AdminAvailableMatches()));
                      },
                      Primary(),
                    ))
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Text("Test Mode"),
                    SizedBox(width: 10),
                    Switch(
                      value: context.watch<UserState>().isTestMode,
                      onChanged: (value) =>
                          userState.setTestMode(!userState.isTestMode),
                      activeTrackColor: Colors.red,
                      activeColor: Colors.red,
                    ),
                    Expanded(
                        child: Text("It allows to see in the UI test matches"))
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Text("Update Credits (in cents)"),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                          initialValue: userDetails.creditsInCents.toString(),
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly
                          ], // Only numbers can be
                          onChanged: (v) {
                            var newValue = int.tryParse(v);
                            if (newValue != null) creditCount = newValue;
                          }
                          // entered
                          ),
                    ),
                    SizedBox(width: 10),
                    Container(
                      width: 100,
                      child: GenericButtonWithLoader("SET",
                          (BuildContext context) async {
                        userDetails.creditsInCents = creditCount;
                        userState.setCurrentUserDetails(userDetails);
                        await UserController.editUser(userDetails);
                        await GenericInfoModal(
                                title: "Credits updated",
                                description: "Your new balance is: " +
                                    formatCurrency(creditCount))
                            .show(context);
                      }, Primary()),
                    )
                  ],
                ),
              ),
            ])),
          ),
        ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: 100,
          child: FutureBuilder<Tuple2<Version, String>>(
              future: LaunchController.getVersion(),
              builder: (context, snapshot) => Text(
                    "v" +
                        ((snapshot.hasData)
                            ? (snapshot.data.item1.toString() +
                                " build " +
                                snapshot.data.item2)
                            : ""),
                    style: TextPalette.bodyText,
                    textAlign: TextAlign.right,
                  )),
        ),
      )
    ];

    return Scaffold(
        backgroundColor: Palette.light,
        appBar: UserPageAppBar(),
        body: SafeArea(
            child: (userDetails != null)
                ? SmartRefresher(
                    enablePullDown: true,
                    enablePullUp: false,
                    header: MaterialClassicHeader(),
                    controller: refreshController,
                    onRefresh: () async {
                      await UserController.refreshCurrentUser(context);
                      refreshController.refreshCompleted();
                    },
                    child: ListView.builder(
                        itemCount: widgets.length,
                        itemBuilder: (context, index) => widgets[index]),
                  )
                : Column(
                    children: [
                      MatchInfoSkeleton(),
                      MatchInfoSkeleton(),
                      MatchInfoSkeleton()
                    ],
                  )));
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

class UserInfoBox extends StatelessWidget {
  final String content;
  final String description;
  // final Widget badge;

  const UserInfoBox({Key key, this.content, this.description})
    // this.badge
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget icContent = Column(
      children: [
        Text(content, style: TextPalette.h1Default),
        SizedBox(height: 4),
        Text(description, style: TextPalette.bodyText)
      ],
    );

    // if (badge != null)
    //   icContent = Badge(
    //       badgeColor: Colors.transparent,
    //       toAnimate: false,
    //       elevation: 0,
    //       borderRadius: BorderRadius.all(Radius.circular(1.0)),
    //       borderSide: BorderSide(width: 0.5, color: Palette.lighterGrey),
    //       // borderRadius: BorderRadius.all(Radius.circular(1.0)),
    //       badgeContent: Icon(Icons.question_mark, size: 8, color: Palette.mediumgrey),
    //       child: icContent);
    return InfoContainer(child: icContent);
  }
}
