import 'package:badges/badges.dart';
import 'package:circle_flags/circle_flags.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/model/UserDetails.dart';
import 'package:nutmeg/utils/CrashlyticsLogger.dart';
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
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../state/UserState.dart';
import '../state/UsersState.dart';
import '../utils/InfoModals.dart';
import '../widgets/ModalBottomSheet.dart';

final logger = CrashlyticsLogger('UserPage');

class UserPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return UserPageState();
  }
}

class UserPageState extends State<UserPage> {
  final verticalSpace = SizedBox(height: 20);

  String? appVersion;

  Future<void> myInitState() async {
    await FirebaseAnalytics.instance.logEvent(name: "open_user_page");
    appVersion = await getVersion();
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
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(height: 4),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 80,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
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
            InkWell(
                onTap: (loadSkeleton)
                    ? null
                    : () async {
                        try {
                          await UserController.updloadPicture(
                              context, userDetails);
                        } catch (e, s) {
                          logger.severe("Error updating profile picture", e, s);
                        }
                      },
                child: Badge(
                    badgeContent: Icon(Icons.camera_alt_outlined,
                        size: 16.0, color: Palette.white),
                    badgeStyle: BadgeStyle(
                      badgeColor: Palette.primary,
                    ),
                    position: BadgePosition.bottomEnd(bottom: -5.0, end: -5.0),
                    child: UserAvatar(30, userDetails))),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 12,
                        width: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      )),
                  const SizedBox(height: 10),
                  Container(
                      height: 12,
                      width: 100,
                      decoration: BoxDecoration(
                          color: Colors.white,
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
            InkWell(
                onTap: () async {
                  try {
                    await UserController.updloadPicture(context, userDetails);
                  } catch (e, s) {
                    logger.severe("Error updating profile picture", e, s);
                  }
                },
                child: Badge(
                    badgeContent: Icon(Icons.camera_alt_outlined,
                        size: 16.0, color: Palette.white),
                    showBadge: true,
                    badgeStyle: BadgeStyle(
                      badgeColor: Palette.primary,
                    ),
                    position: BadgePosition.custom(bottom: -5.0, end: -5.0),
                    child: UserAvatar(30, userDetails))),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(userDetails.name ?? "N/A", style: TextPalette.h2),
                  SizedBox(height: 10),
                  Text(formatEmail(userDetails.email),
                      style: TextPalette.bodyText)
                ],
              ),
            )
          ],
        )),
        verticalSpace,
        if (userDetails.createdMatches != null && userDetails.createdMatches!.isNotEmpty) ...[
          PaymentInfoEditor(userDetails: userDetails),
          verticalSpace,
        ],
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
                      child: PerformanceGraph(userDetails: userDetails)))),
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
                          child: CompleteOrganiserAccountWidget(isTest: isTest))
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
                      var dashboardWidgets = List<Widget>.from([]);

                      void addGotoDashboard(bool isTest) {
                        if (userDetails.isOrganiser(isTest) &&
                            userDetails.areChargesEnabled(isTest))
                          dashboardWidgets.addAll([
                            if (dashboardWidgets.isNotEmpty) verticalSpace,
                            Row(children: [
                              Expanded(
                                  child: GenericButtonWithLoader(
                                      AppLocalizations.of(context)!
                                              .goToStripeDashboardText +
                                          (isTest ? " TEST" : ""), (_) async {
                                var url = CloudFunctionsClient().getUrl(
                                    "stripe/account?is_test?$isTest&user_id=${userDetails.documentId}");

                                await launchUrl(Uri.parse(url),
                                    mode: LaunchMode.externalApplication);
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
                        bottom: Column(children: dashboardWidgets),
                      );
                    })),
                    SizedBox(width: 20),
                    Expanded(
                      child: _PlayersPlayedWithYou(
                          userId: userDetails.documentId),
                    ),
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
                              () => UserController.logout(context));
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
                        await UserController.logout(context);
                      } catch (e, stackTrace) {
                        logger.severe("Error logging out", e, stackTrace);
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
        if (appVersion != null)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Center(
              child: Container(
                child: Text(
                  "v $appVersion",
                  style: TextPalette.bodyText,
                  textAlign: TextAlign.right,
                ),
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
              ? Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 80,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ))
              : (rightBadge != null)
                  ? Badge(
                      badgeStyle: BadgeStyle(
                        badgeColor: Colors.transparent,
                        borderSide: BorderSide.none,
                        shape: BadgeShape.circle,
                      ),
                      position: BadgePosition.custom(end: 0, bottom: 0),
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
    return WarningWidget(
      title: "Create your " + (this.isTest ? "Test " : "") + "Stripe account",
      body:
          "To start receiving payments, you need to create your Stripe account",
      textAction: "GO TO STRIPE",
      action: () => completeAccountAction(context, isTest),
    );
  }
}

class PaymentInfoEditor extends StatelessWidget {
  final UserDetails userDetails;

  const PaymentInfoEditor({Key? key, required this.userDetails})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var hasPaymentInfo = userDetails.paymentInfo != null &&
        userDetails.paymentInfo!.isNotEmpty;

    return InkWell(
      onTap: () => _showEditModal(context),
      child: InfoContainer(
        child: Row(
          children: [
            Icon(Icons.payment_outlined, color: Palette.primary, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.paymentInfoHeader, style: TextPalette.h3),
                  SizedBox(height: 4),
                  hasPaymentInfo
                      ? buildLinkedText(
                          userDetails.paymentInfo!,
                          TextPalette.getBodyText(Palette.black),
                        )
                      : Text(
                          AppLocalizations.of(context)!.paymentInfoProfileDesc,
                          style: TextPalette.getBodyText(Palette.greyDark),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                ],
              ),
            ),
            SizedBox(width: 8),
            Icon(
              hasPaymentInfo ? Icons.edit_outlined : Icons.add,
              color: Palette.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditModal(BuildContext context) {
    var controller =
        TextEditingController(text: userDetails.paymentInfo ?? "");

    ModalBottomSheet.showNutmegModalBottomSheet(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppLocalizations.of(context)!.paymentInfoHeader, style: TextPalette.h2),
          SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.paymentInfoShownToPlayers,
            style: TextPalette.bodyText,
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: controller,
            maxLines: 4,
            minLines: 2,
            autofocus: true,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.paymentInfoPlaceholder,
              hintStyle: TextPalette.getBodyText(Palette.greyDark),
              filled: true,
              fillColor: Palette.greyLighter,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GenericButtonWithLoader(AppLocalizations.of(context)!.save, (_) async {
                  var text = controller.text.trim();
                  await context.read<UserState>().editUser({
                    "paymentInfo": text.isEmpty ? null : text,
                  });
                  Navigator.pop(context);
                }, Primary()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayersPlayedWithYou extends StatefulWidget {
  final String userId;

  const _PlayersPlayedWithYou({required this.userId});

  @override
  State<_PlayersPlayedWithYou> createState() => _PlayersPlayedWithYouState();
}

class _PlayersPlayedWithYouState extends State<_PlayersPlayedWithYou> {
  Map<String, int>? _playerCounts;

  @override
  void initState() {
    super.initState();
    _fetchPlayers();
  }

  Future<void> _fetchPlayers() async {
    var resp = await CloudFunctionsClient()
        .get("users/${widget.userId}/organizer/players");
    if (resp != null && mounted) {
      var raw = Map<String, dynamic>.from(resp["players_joined"] ?? {});
      var counts = raw.map((k, v) => MapEntry(k, (v as num).toInt()));
      setState(() => _playerCounts = counts);
    }
  }

  @override
  Widget build(BuildContext context) {
    var count = _playerCounts?.length;

    return InkWell(
      onTap: (_playerCounts != null && _playerCounts!.isNotEmpty)
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => _PlayersPlayedWithYouPage(
                        playerCounts: _playerCounts!)),
              )
          : null,
      child: UserInfoBox(
        content: count?.toString(),
        description: "Played with you",
        rightBadge: (_playerCounts != null && _playerCounts!.isNotEmpty)
            ? Icon(Icons.chevron_right, color: Palette.primary, size: 18)
            : null,
      ),
    );
  }
}

class _PlayersPlayedWithYouPage extends StatefulWidget {
  final Map<String, int> playerCounts;

  const _PlayersPlayedWithYouPage({required this.playerCounts});

  @override
  State<_PlayersPlayedWithYouPage> createState() =>
      _PlayersPlayedWithYouPageState();
}

class _PlayersPlayedWithYouPageState extends State<_PlayersPlayedWithYouPage> {
  late List<MapEntry<String, int>> _sorted;

  @override
  void initState() {
    super.initState();
    _sorted = widget.playerCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    var usersState = context.read<UsersState>();
    for (var entry in _sorted) {
      usersState.fetchUserDetails(entry.key);
    }
  }

  @override
  Widget build(BuildContext context) {
    var usersState = context.watch<UsersState>();

    return PageTemplate(
      appBar: Row(
        children: [
          BackButton(
              color: Palette.black,
              onPressed: () => Navigator.pop(context)),
        ],
      ),
      widgets: [
        Text("PLAYED WITH YOU", style: TextPalette.h4),
        SizedBox(height: 4),
        Text(
          "${_sorted.length} players",
          style: TextPalette.bodyText,
        ),
        SizedBox(height: 16),
        InfoContainer(
          child: Column(
            children: _sorted.map((entry) {
              var ud = usersState.getUserDetail(entry.key);
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    UserAvatar(20, ud),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        UserDetails.getDisplayName(ud),
                        style: TextPalette.getBodyText(Palette.black),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Palette.greyLighter,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${entry.value}x",
                        style: TextPalette.getBodyText(Palette.greyDark),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
