import 'package:badges/badges.dart';
import 'package:circle_flags/circle_flags.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/model/UserDetails.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:nutmeg/widgets/FeedbackBottomModal.dart';
import 'package:nutmeg/widgets/PageTemplate.dart';
import 'package:nutmeg/widgets/PlayerBottomModal.dart';
import 'package:nutmeg/widgets/Section.dart';
import 'package:nutmeg/widgets/WarningWidget.dart';
import 'package:provider/provider.dart';
import 'package:skeletons/skeletons.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../state/UserState.dart';
import '../utils/InfoModals.dart';
import '../widgets/ModalBottomSheet.dart';

class UserPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return UserPageState();
  }
}

class UserPageState extends State<UserPage> {
  final verticalSpace = SizedBox(height: 20);

  bool loadingPicture = false;

  Future<void> myInitState() async {
    await FirebaseAnalytics.instance.logEvent(name: "open_user_page");
    await refreshPageState();
  }

  Future<void> refreshPageState() async =>
      context.read<UserState>().fetchLoggedUserDetails();

  @override
  Widget build(BuildContext context) {
    var userState = context.watch<UserState>();
    var userDetails = userState.getLoggedUserDetails();

    if (userDetails != null && !userState.isLoggedIn()) return Container();

    var loadSkeleton = userDetails == null;

    var showOrganizerView = userDetails != null &&
        (userDetails.isOrganiser(true) || userDetails.isOrganiser(false));

    var title = Row(children: [
      Text(AppLocalizations.of(context)!.accountTitle,
          style: TextPalette.h1Default)
    ]);

    var widgets;
    if (loadSkeleton) {
      var userInfoBoxSkeleton = Expanded(
          child: InfoContainer(
              child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SkeletonLine(
              style: SkeletonLineStyle(
                  alignment: AlignmentDirectional.center,
                  width: 80,
                  height: 12,
                  borderRadius: BorderRadius.circular(8.0))),
          SizedBox(height: 4),
          SkeletonLine(
              style: SkeletonLineStyle(
                  alignment: AlignmentDirectional.center,
                  width: 80,
                  height: 12,
                  borderRadius: BorderRadius.circular(8.0))),
        ],
      )));
      var userInfoBoxRowSkeleton = Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [userInfoBoxSkeleton, userInfoBoxSkeleton]);

      widgets = [
        title,
        verticalSpace,
        InfoContainer(
            child: Row(
          children: [
            (loadingPicture)
                ? CircleAvatar(
                    backgroundColor: Palette.greyLightest,
                    radius: 30,
                    child: Container(
                      height: 20.0,
                      width: 20.0,
                      child: CircularProgressIndicator(
                        color: Palette.greyLight,
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
                  SkeletonLine(
                      style: SkeletonLineStyle(
                          height: 12,
                          width: 200,
                          borderRadius: BorderRadius.circular(8.0))),
                  SizedBox(height: 10),
                  SkeletonLine(
                      style: SkeletonLineStyle(
                          height: 12,
                          width: 100,
                          borderRadius: BorderRadius.circular(8.0)))
                ],
              ),
            )
          ],
        )),
        verticalSpace,
        userInfoBoxRowSkeleton,
        verticalSpace,
        userInfoBoxRowSkeleton,
      ];
    } else {
      widgets = [
        title,
        verticalSpace,
        InfoContainer(
            child: Row(
          children: [
            (loadingPicture)
                ? CircleAvatar(
                    backgroundColor: Palette.greyLightest,
                    radius: 30,
                    child: Container(
                      height: 20.0,
                      width: 20.0,
                      child: CircularProgressIndicator(
                        color: Palette.greyLight,
                        strokeWidth: 2.0,
                      ),
                    ))
                : InkWell(
                    onTap: () async {
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
                  Text(userDetails!.name ?? "N/A", style: TextPalette.h2),
                  SizedBox(height: 10),
                  Text(formatEmail(userDetails.email),
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
                content: userDetails.getNumJoinedMatches().toString(),
                description: AppLocalizations.of(context)!.numMatchesTitle),
          ),
          SizedBox(width: 20),
          Expanded(
            child: UserScoreBox(userDetails: userDetails),
          ),
        ]),
        verticalSpace,
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: UserInfoBox(
              content: userDetails.getNumManOfTheMatch().toString(),
              description:
                  AppLocalizations.of(context)!.numPlayersOfTheMatchBoxTitle,
            ),
          ),
          SizedBox(width: 20),
          Expanded(
              child: UserInfoBox(
                  content: (userDetails.numWin ?? 0).toString(),
                  description:
                  AppLocalizations.of(context)!.numMatchesWonBoxTitle)),
        ]),
        if (userDetails.numWin != null) verticalSpace,
        if (userDetails.numWin != null)
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
                child: UserInfoBox(
                    content: (userDetails.numDraw ?? 0).toString(),
                    description:
                    AppLocalizations.of(context)!.numMatchesDrawBoxTitle)),
            SizedBox(width: 20),
            Expanded(
              child: UserInfoBox(
                  content: (userDetails.numLoss ?? 0).toString(),
                  description:
                      AppLocalizations.of(context)!.numMatchesLostBoxTitle),
            )
          ]),
        if (userDetails.getLastScores().length > 0)
          Section(
              title: AppLocalizations.of(context)!.performanceTitle,
              body: SizedBox(
                  height: 180,
                  child: InfoContainer(
                      child:
                          PerformanceGraph(userId: userDetails.documentId)))),
        if ((userDetails.skillsCount ?? {}).isNotEmpty)
          Builder(
            builder: (BuildContext context) {
              var sorted = userDetails.skillsCount!.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              return Section(
                  title: "TOP SKILLS",
                  body: InfoContainer(
                    child: Column(
                        children: interleave(
                            sorted
                                .asMap()
                                .entries
                                .map((e) => Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            width: 20,
                                            child: Text((e.key + 1).toString(),
                                                style: GoogleFonts.roboto(
                                                    color: Palette.greyDark,
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w400)),
                                          ),
                                          Container(
                                            width: 180,
                                            child: Text(e.value.key,
                                                style: TextPalette.getBodyText(
                                                    Palette.black)),
                                          ),
                                          Container(
                                            height: 8,
                                            width: 80,
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(10)),
                                              child: LinearProgressIndicator(
                                                value: e.value.value /
                                                    sorted.first.value,
                                                color: Palette.primary,
                                                backgroundColor:
                                                    Palette.greyLighter,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            width: 20,
                                            child: Text(
                                              e.value.value == 0
                                                  ? "-"
                                                  : e.value.value.toString(),
                                              style: TextPalette.getBodyText(
                                                  Palette.black),
                                            ),
                                          )
                                        ]))
                                .toList(),
                            SizedBox(height: 12))),
                  ));
            },
          ),
        if (showOrganizerView)
          Section(
            title: AppLocalizations.of(context)!.organiserSectionTitle,
            body: Container(child: Builder(builder: (context) {
              var widgets = List<Widget>.from([]);

              void addCompleteBanner(bool isTest) {
                if (userDetails.isOrganiser(isTest) &&
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
                      int n = userDetails.createdMatches!.length;
                      var widgets = List<Widget>.from([]);

                      void addGotoDashboard(bool isTest) {
                        if (userDetails.isOrganiser(isTest) &&
                            userDetails.areChargesEnabled(isTest))
                          widgets.addAll([
                            if (widgets.isNotEmpty) verticalSpace,
                            Row(children: [
                              Expanded(
                                  child: GenericButtonWithLoader(
                                      AppLocalizations.of(context)!
                                              .goToStripeDashboardText +
                                          (isTest ? " TEST" : ""), (_) async {
                                var url = CloudFunctionsClient()
                                    .getUrl("stripe/account?is_test?$isTest");

                                await launchUrl(Uri.parse(url));
                              }, Primary()))
                            ]),
                          ]);
                      }

                      addGotoDashboard(true);
                      addGotoDashboard(false);

                      return UserInfoBox(
                        content: (loadSkeleton) ? null : n.toString(),
                        description: AppLocalizations.of(context)!
                            .organizedMatchesBoxTitle,
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
              text: AppLocalizations.of(context)!.followOnIg,
              onTap: () async {
                var url = 'https://www.instagram.com/nutmegapp/';

                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(
                    Uri.parse(url),
                  );
                } else {
                  throw 'There was a problem to open the url: $url';
                }
              },
            ),
            LinkInfo(
              text: AppLocalizations.of(context)!.feedback,
              onTap: () async {
                await FeedbackBottomModal.feedbackAction(context);
              },
            ),
            LinkInfo(
                text: "Email support",
                onTap: () => launchUrl(Uri.parse(
                    "mailto:support@nutmegapp.com?subject=Support request"))),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                      child: Text("Delete Profile", style: TextPalette.h3),
                      onTap: () async {
                        var shouldCancel = await GenericInfoModal(
                            title:
                                "Are you sure you want to delete your profile?",
                            description:
                                "This is going to permanently delete all your data stored in Nutmeg and cannot be undone.",
                            action: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                GenericButtonWithLoader("CANCEL", (_) async {
                                  Navigator.pop(context, false);
                                }, Secondary()),
                                SizedBox(width: 8),
                                GenericButtonWithLoader("YES", (_) async {
                                  Navigator.pop(context, true);
                                }, Primary()),
                              ],
                            )).show(context);

                        if (shouldCancel) {
                          await Future.delayed(Duration(milliseconds: 500),
                              () => context.read<UserState>().logout());
                          Navigator.of(context).pop();
                        }
                      }),
                )
              ],
            ),
            NutmegDivider(horizontal: true),
            SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                      child: Text("Privacy Policy", style: TextPalette.h3),
                      onTap: () => launchUrl(Uri.parse(
                          "https://nutmeg.flycricket.io/privacy.html"))),
                )
              ],
            ),
            NutmegDivider(horizontal: true),
            verticalSpace,
            Row(
              children: [
                Expanded(
                  child: GenericButtonWithLoader(
                    "LOGOUT",
                    (BuildContext context) async {
                      context.read<GenericButtonWithLoaderState>().change(true);

                      try {
                        await context.read<UserState>().logout();
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
            verticalSpace,
            Row(
              children: [
                Expanded(
                    child: GenericButtonWithLoader(
                  AppLocalizations.of(context)!.changeLanguageButton,
                  (BuildContext context) async {
                    String? locale =
                        await ModalBottomSheet.showNutmegModalBottomSheet(
                            context,
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!
                                            .languageModalTitle,
                                        style: TextPalette.h2,
                                      ),
                                      SizedBox(height: 24.0),
                                      InkWell(
                                        onTap: () =>
                                            Navigator.pop(context, "en"),
                                        child: Row(children: [
                                          CircleFlag("us", size: 24),
                                          SizedBox(width: 16),
                                          Text("English")
                                        ]),
                                      ),
                                      SizedBox(height: 24.0),
                                      InkWell(
                                        onTap: () =>
                                            Navigator.pop(context, "pt"),
                                        child: Row(children: [
                                          CircleFlag("pt", size: 24),
                                          SizedBox(width: 16),
                                          Text("Português")
                                        ]),
                                      ),
                                      SizedBox(height: 24.0),
                                      InkWell(
                                        onTap: () =>
                                            Navigator.pop(context, "it"),
                                        child: Row(children: [
                                          CircleFlag("it", size: 24),
                                          SizedBox(width: 16),
                                          Text("Italiano")
                                        ]),
                                      ),
                                      SizedBox(height: 24.0),
                                      InkWell(
                                        onTap: () =>
                                            Navigator.pop(context, "es"),
                                        child: Row(children: [
                                          CircleFlag("es", size: 24),
                                          SizedBox(width: 16),
                                          Text("Español")
                                        ]),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ));
                    if (locale != null) {
                      context.read<UserState>().editUser({"language": locale});
                    }
                  },
                  Primary(),
                ))
              ],
            ),
          ])),
        ),
        if (userDetails.getIsAdmin())
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
                  Expanded(
                      child: Text("It allows to see in the UI test matches"))
                ],
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
    }

    return PageTemplate(
      initState: () => myInitState(),
      refreshState: () => refreshPageState(),
      widgets: [
        Center(
          child: Container(
            width: 700,
            child: Column(children: widgets),
          ),
        )
      ]
      // widgets
      ,
      appBar: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BackButton(
              color: Palette.black, onPressed: () => Navigator.pop(context)),
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
          NutmegDivider(horizontal: true)
        ]),
      ),
    );
  }
}

class UserInfoBox extends StatelessWidget {
  final String? content;
  final String? description;
  final Widget? bottom;
  final Widget? rightBadge;

  // final Widget badge;
  const UserInfoBox(
      {Key? key, this.content, this.description, this.bottom, this.rightBadge})
      // this.badge
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget icContent = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          (content == null)
              ? SkeletonLine(
                  style: SkeletonLineStyle(
                      alignment: AlignmentDirectional.center,
                      width: 80,
                      height: 12,
                      borderRadius: BorderRadius.circular(8.0)))
              : (rightBadge != null)
                  ? Badge(
                      badgeColor: Colors.transparent,
                      borderSide: BorderSide.none,
                      shape: BadgeShape.circle,
                      position: BadgePosition(end: 0, bottom: 0),
                      elevation: 0,
                      badgeContent: rightBadge,
                      child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: Text(content!,
                              style: TextPalette.getStats(Palette.black))))
                  : Text(
                      content!,
                      style: TextPalette.getStats(Palette.black),
                    ),
        ]),
        SizedBox(height: 4),
        Text(description!, style: TextPalette.bodyText),
        if (bottom != null) SizedBox(height: 4),
        if (bottom != null) bottom!
      ],
    );
    return InfoContainer(child: icContent);
  }
}

class UserScoreBox extends StatelessWidget {
  final UserDetails userDetails;

  const UserScoreBox({Key? key, required this.userDetails}) : super(key: key);

  static Widget deltaBadge(UserDetails userDetails) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Icon(
            userDetails.getDeltaFromLastScore() > 0
                ? Icons.arrow_drop_up_outlined
                : Icons.arrow_drop_down_outlined,
            size: 14,
            color: userDetails.getDeltaFromLastScore() > 0
                ? Colors.green
                : Colors.red,
          ),
          Text(userDetails.getDeltaFromLastScore().abs().toStringAsFixed(2),
              style: GoogleFonts.roboto(
                  color: userDetails.getDeltaFromLastScore() > 0
                      ? Colors.green
                      : Colors.red,
                  fontSize: 11,
                  fontWeight: FontWeight.w400))
        ],
      );

  @override
  Widget build(BuildContext context) {
    return UserInfoBox(
        content: (userDetails.getScoreMatches() == null)
            ? "-"
            : userDetails.getScoreMatches()!.toStringAsFixed(2),
        description: AppLocalizations.of(context)!.averageScoreBoxTitle,
        rightBadge: userDetails.getDeltaFromLastScore() < 0.01
            ? null
            : deltaBadge(userDetails));
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
        await launchUrl(
            Uri.parse(getStripeUrl(isTest, userState.currentUserId!)));
      },
    );
  }
}
