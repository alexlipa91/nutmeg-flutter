import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/model/UserDetails.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:nutmeg/widgets/FeedbackBottomModal.dart';
import 'package:nutmeg/widgets/PageTemplate.dart';
import 'package:nutmeg/widgets/Section.dart';
import 'package:nutmeg/widgets/WarningWidget.dart';
import 'package:provider/provider.dart';
import 'package:skeletons/skeletons.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';

import '../state/UserState.dart';

class UserPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return UserPageState();
  }
}

class UserPageState extends State<UserPage> {
  final verticalSpace = SizedBox(height: 20);

  bool loadingPicture = false;

  Future<void> refreshPageState() async {
    await UserController.refreshLoggedUser(context);
  }

  @override
  Widget build(BuildContext context) {
    var userState = context.watch<UserState>();
    var userDetails = userState.getLoggedUserDetails();

    if (userDetails != null && !userState.isLoggedIn()) return Container();

    var loadSkeleton = userDetails == null || userDetails is EmptyUserDetails;

    var showOrganizerView = userDetails != null &&
        (userDetails.isOrganiser(true) || userDetails.isOrganiser(false));

    var widgets = [
      Text("Account", style: TextPalette.h1Default),
      verticalSpace,
      InfoContainer(
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
              : InkWell(
                  onTap: (loadSkeleton)
                      ? null
                      : () async {
                          setState(() {
                            loadingPicture = true;
                          });
                          try {
                            await UserController.updloadPicture(
                                context, userDetails!);
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
                      badgeContent: Icon(Icons.camera_alt_outlined,
                          size: 16.0, color: Palette.white),
                      badgeColor: Palette.primary,
                      elevation: 0,
                      position:
                          BadgePosition.bottomEnd(bottom: -5.0, end: -5.0),
                      child: UserAvatar(30, userDetails))),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                (loadSkeleton)
                    ? SkeletonLine(
                        style: SkeletonLineStyle(
                            height: 12,
                            width: 200,
                            borderRadius: BorderRadius.circular(8.0)))
                    : Text(userDetails!.name ?? "N/A", style: TextPalette.h2),
                SizedBox(height: 10),
                (loadSkeleton)
                    ? SkeletonLine(
                        style: SkeletonLineStyle(
                            height: 12,
                            width: 100,
                            borderRadius: BorderRadius.circular(8.0)))
                    : Text(userDetails!.email ?? "N/A",
                        style: TextPalette.bodyText)
              ],
            ),
          )
        ],
      )),
      verticalSpace,
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(
            child: UserInfoBox(
                content: (loadSkeleton)
                    ? null
                    : formatCurrency(userDetails?.creditsInCents ?? 0),
                description: "Credits")),
        SizedBox(width: 20),
        Expanded(
          child: UserInfoBox(
              content: (loadSkeleton || userDetails?.getNumJoinedMatches() == null)
                  ? null
                  : userDetails?.getNumJoinedMatches().toString(),
              description: "Matches Played"),
        )
      ]),
      verticalSpace,
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(
          child: UserInfoBox(
              content: (loadSkeleton)
                  ? null
                  : (userDetails?.getScoreMatches() == null)
                      ? "-"
                      : userDetails?.getScoreMatches()?.toStringAsFixed(1),
              description: "Avg. Score"),
        ),
        SizedBox(width: 20),
        Expanded(
          child: UserInfoBox(
            content: (loadSkeleton)
                ? null
                : userDetails?.getNumManOfTheMatch().toString(),
            description: "Player of the Match",
          ),
        )
      ]),
      if (showOrganizerView)
        Section(
          title: "ORGANISER",
          body: Container(child: Builder(builder: (context) {
            var widgets = List<Widget>.from([]);

            void addCompleteBanner(bool isTest) {
              if (userDetails != null &&
                  userDetails.isOrganiser(isTest) &&
                  !userDetails.areChargesEnabled(isTest))
                widgets.addAll([
                  Row(children: [
                    Expanded(
                        child: CompleteOrganiserAccountWidget(isTest: true))
                  ]),
                  verticalSpace
                ]);
            }
            addCompleteBanner(true);
            addCompleteBanner(false);

            widgets.add(Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Builder(builder: (BuildContext context) {
                    int n = userDetails?.createdMatches!.length ?? 0;
                    var widgets = List<Widget>.from([]);

                    void addGotoDashboard(bool isTest) {
                      if (userDetails != null &&
                          userDetails.isOrganiser(isTest) &&
                          userDetails.areChargesEnabled(isTest))
                        widgets.addAll([
                          if (widgets.isNotEmpty)
                            verticalSpace,
                          Row(children: [
                            Expanded(
                                child: GenericButtonWithLoader(
                                    "GO TO MY STRIPE DASHBOARD" + (isTest ? " TEST" : ""),
                                        (_) async {
                                      var url =
                                          "https://europe-central2-nutmeg-9099c.cloudfunctions.net/go_to_account_login_link?"
                                          "is_test=$isTest&user_id=${userState.currentUserId}";

                                      await launch(url, forceSafariVC: false);
                                    }, Primary()))
                          ]),
                        ]);
                      }

                    addGotoDashboard(true);
                    addGotoDashboard(false);

                    return UserInfoBox(
                        content: (loadSkeleton) ? null : n.toString(),
                        description: "Organized match" + ((n > 1) ? "es" : ""),
                        bottom: Column(children: widgets),
                    );
                  }))
                ]));

            return Column(children: widgets);
          })),
        ),
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
          LinkInfo(
                text: "Give us feedback",
                onTap: () async {
                  await FeedbackBottomModal.feedbackAction(context);
                },
          ),
          LinkInfo(
            text: "Email support",
            onTap: () async {
              await launch("mailto:support@nutmegapp.com?subject=Support request", forceSafariVC: false);
            }
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GenericButtonWithLoader(
                  "LOGOUT",
                  (BuildContext context) async {
                    context.read<GenericButtonWithLoaderState>().change(true);

                    try {
                      await Future.delayed(
                          Duration(milliseconds: 500),
                          () =>
                              UserController.logout(context.read<UserState>()));
                    } catch (e, stackTrace) {
                      print(e);
                      print(stackTrace);
                    }
                    Navigator.of(context).pop();
                  },
                  Primary(),
                ),
              )
            ],
          ),
        ])),
      ),
      if (userDetails != null && userDetails.getIsAdmin())
        Section(
          title: "ADMIN COMMANDS",
          body: InfoContainer(
              child: Column(children: [
            Row(
              children: [
                Expanded(
                    child: GenericButtonWithLoader(
                  "ADMIN AREA",
                  (BuildContext context) async =>
                      GoRouter.of(context).go("/admin"),
                  Primary(),
                ))
              ],
            ),
            verticalSpace,
            Row(
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
                Expanded(child: Text("It allows to see in the UI test matches"))
              ],
            ),
            // verticalSpace,
            // Row(
            //   children: [
            //     Text("Update Credits (in cents)"),
            //     SizedBox(width: 10),
            //     Expanded(
            //       child: TextFormField(
            //           initialValue: userDetails.creditsInCents.toString(),
            //           keyboardType: TextInputType.number,
            //           inputFormatters: <TextInputFormatter>[
            //             FilteringTextInputFormatter.digitsOnly
            //           ], // Only numbers can be
            //           onChanged: (v) {
            //             var newValue = int.tryParse(v);
            //             if (newValue != null) creditCount = newValue;
            //           }
            //           // entered
            //           ),
            //     ),
            //     SizedBox(width: 10),
            //     Container(
            //       width: 100,
            //       child: GenericButtonWithLoader("SET",
            //           (BuildContext context) async {
            //         context.read<GenericButtonWithLoaderState>().change(true);
            //         userDetails.creditsInCents = creditCount;
            //         try {
            //           await UserController.editUser(context, userDetails);
            //           await GenericInfoModal(
            //                   title: "Credits updated",
            //                   description: "Your new balance is: " +
            //                       formatCurrency(creditCount))
            //               .show(context);
            //         } catch (e, s) {
            //           print(e);
            //           print(s);
            //           ErrorHandlingUtils.handleError(e, s, context);
            //         }
            //         context.read<GenericButtonWithLoaderState>().change(false);
            //       }, Primary()),
            //     )
            //   ],
            // ),
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
                              ? (snapshot.data!.item1.toString() +
                                  " build " +
                                  snapshot.data!.item2)
                              : ""),
                      style: TextPalette.bodyText,
                      textAlign: TextAlign.right,
                    )),
          ),
        ),
      )
    ];

    return PageTemplate(
      refreshState: () => refreshPageState(),
      widgets: widgets,
      appBar: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BackButton(
              color: Palette.black,
              onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}

class LinkInfo extends StatelessWidget {
  final String text;
  final Function? onTap;

  const LinkInfo({Key? key, required this.text, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap!(),
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
  final String? content;
  final String? description;
  final Widget? bottom;

  // final Widget badge;

  const UserInfoBox({Key? key, this.content, this.description, this.bottom})
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
            : Text(content!, style: TextPalette.getStats(Palette.black)),
        SizedBox(height: 4),
        Text(description!, style: TextPalette.bodyText),
        if (bottom != null)
          SizedBox(height: 4),
        if (bottom != null)
          bottom!
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

class CompleteOrganiserAccountWidget extends StatelessWidget {
  final bool isTest;

  const CompleteOrganiserAccountWidget({Key? key, required this.isTest})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var userState = context.watch<UserState>();

    return WarningWidget(
      title: "Create your " + (this.isTest ? "Test " : "") + "Stripe account",
      body:
          "To start receiving payments, you need to create your Stripe account",
      textAction: "GO TO STRIPE",
      action: () async {
        var url =
            "https://europe-central2-nutmeg-9099c.cloudfunctions.net/go_to_onboard_connected_account?is_test=$isTest&id=${userState.currentUserId}";
        await launch(url, forceSafariVC: false);
      },
    );
  }
}
