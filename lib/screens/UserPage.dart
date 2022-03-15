import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:nutmeg/widgets/PageTemplate.dart';
import 'package:nutmeg/widgets/Section.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:skeletons/skeletons.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';

import '../state/AvailableMatchesState.dart';
import '../state/UserState.dart';

class UserPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return UserPageState();
  }
}

class UserPageState extends State<UserPage> {
  final RefreshController refreshController = RefreshController();
  final ImagePicker picker = ImagePicker();
  final ImageCropper cropper = ImageCropper();

  bool loadingPicture = false;

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

    var widgets = [
      Text("Account", style: TextPalette.h1Default),
      Padding(
        padding: EdgeInsets.only(top: 20),
        child: InfoContainer(
            child: Row(
          children: [
            (loadingPicture)
                ? CircleAvatar(
                    backgroundColor: Palette.grey_lightest,
                    radius: 30,
                    child: Container(
                      height: 20.0,
                      width: 20.0,
                      child: CircularProgressIndicator(
                        color: Palette.grey_light,
                        strokeWidth: 2.0,
                      ),
                    ))
                : (userDetails == null)
                    ? SkeletonAvatar(
                        style: SkeletonAvatarStyle(
                            shape: BoxShape.circle, height: 69),
                      )
                    : InkWell(
                        onTap: () async {
                          setState(() {
                            loadingPicture = true;
                          });
                          try {
                            await UserController.updloadPicture(
                                context, userDetails);
                          } catch (e, s) {
                            print(e);
                            print(s);
                          }
                          setState(() {
                            loadingPicture = false;
                          });
                        },
                        child: Badge(
                            toAnimate: false,
                            badgeContent: Icon(Icons.camera_alt_outlined, size: 16.0, color: Palette.white),
                            badgeColor: Palette.primary,
                            elevation: 0,
                            position: BadgePosition.bottomEnd(
                                bottom: -5.0, end: -5.0),
                            child: UserAvatar(30, userDetails))),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  (userDetails == null)
                      ? SkeletonLine(
                          style: SkeletonLineStyle(
                              height: 12,
                              width: 200,
                              borderRadius: BorderRadius.circular(8.0)))
                      : Text(userDetails.name ?? "N/A", style: TextPalette.h2),
                  SizedBox(height: 10),
                  (userDetails == null)
                      ? SkeletonLine(
                          style: SkeletonLineStyle(
                              height: 12,
                              width: 100,
                              borderRadius: BorderRadius.circular(8.0)))
                      : Text(userDetails.email ?? "N/A",
                          style: TextPalette.bodyText)
                ],
              ),
            )
          ],
        )),
      ),
      Padding(
        padding: EdgeInsets.only(top: 20),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
              child: UserInfoBox(
                  content: (userDetails == null)
                      ? null
                      : formatCurrency(userDetails.creditsInCents ?? 0),
                  description: "Credits")),
          SizedBox(width: 20),
          Expanded(
            child: UserInfoBox(
                content: (userDetails == null)
                    ? null
                    : userDetails.getJoinedMatches().length.toString(),
                description: "Matches Played"),
          )
        ]),
      ),
      if (!shouldDisableRatings)
        Padding(
          padding: EdgeInsets.only(top: 20),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
              child: UserInfoBox(
                  content: (userDetails == null)
                      ? null
                      : (userDetails.getScoreMatches() == -1)
                          ? "-"
                          : userDetails.getScoreMatches().toStringAsFixed(2),
                  description: "Avg. Score"),
            ),
            SizedBox(width: 20),
            Expanded(
              child: UserInfoBox(
                content: (userDetails == null)
                    ? null
                    : userDetails.getNumManOfTheMatch().toString(),
                description: "Player of the Match",
              ),
            )
          ]),
        ),
      if (!shouldDisableRatings)
        Section(
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
                        } catch (e, stackTrace) {
                          print(e);
                          print(stackTrace);
                        }
                        // when logging out, go back to first tab in main page
                        Get.back(result: false);
                      },
                      Primary(),
                    ),
                  )
                ],
              ),
            ),
          ])),
        ),
      if (userDetails != null && userDetails.getIsAdmin())
        Section(
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
                      Get.toNamed("/adminHome");
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
                      context.read<GenericButtonWithLoaderState>().change(true);
                      userDetails.creditsInCents = creditCount;
                      await UserController.editUser(context, userDetails);
                      await GenericInfoModal(
                              title: "Credits updated",
                              description: "Your new balance is: " +
                                  formatCurrency(creditCount))
                          .show(context);
                      context
                          .read<GenericButtonWithLoaderState>()
                          .change(false);
                    }, Primary()),
                  )
                ],
              ),
            ),
          ])),
        ),
      Padding(
        padding: EdgeInsets.only(top: 8),
        child: Center(
          child: Container(
            child: FutureBuilder<Tuple2<Version, String>>(
                future: getVersion(),
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
        ),
      ),
      SizedBox(
        height: MediaQuery.of(context).padding.bottom,
      )
    ];

    return PageTemplate(
      refreshState: () => UserController.refreshCurrentUser(context),
      widgets: widgets,
      appBar: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BackButton(color: Palette.black),
        ],
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        (content == null)
            ? SkeletonLine(
                style: SkeletonLineStyle(
                    alignment: AlignmentDirectional.center,
                    width: 80,
                    height: 12,
                    borderRadius: BorderRadius.circular(8.0)))
            : Text(content, style: TextPalette.getStats(Palette.black)),
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
    //       borderSide: BorderSide(width: 0.5, color: Palette.grey_lighter),
    //       // borderRadius: BorderRadius.all(Radius.circular(1.0)),
    //       badgeContent: Icon(Icons.question_mark, size: 8, color: Palette.grey_dark),
    //       child: icContent);
    return InfoContainer(child: icContent);
  }
}
