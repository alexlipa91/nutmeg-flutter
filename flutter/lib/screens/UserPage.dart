import 'dart:math' show pi;

import 'package:badges/badges.dart';
import 'package:circle_flags/circle_flags.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:google_fonts/google_fonts.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/config/app_config.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/model/UserDetails.dart';
import 'package:nutmeg/utils/CrashlyticsLogger.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:nutmeg/widgets/FifaCard.dart';
import 'package:nutmeg/widgets/FeedbackBottomModal.dart';
import 'package:nutmeg/widgets/PageTemplate.dart';
import 'package:nutmeg/widgets/PlayerBottomModal.dart';
import 'package:nutmeg/widgets/Section.dart';
import 'package:nutmeg/widgets/Skeletons.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nutmeg/l10n/app_localizations.dart';
import 'package:nutmeg/utils/navigate_url.dart';
import 'package:nutmeg/widgets/PayOutsideNutmegRow.dart';
import 'package:nutmeg/widgets/PayThroughNutmegRow.dart';

import 'CreateMatch.dart';
import '../state/UserState.dart';
import '../state/UsersState.dart';
import '../utils/InfoModals.dart';
import '../widgets/ModalBottomSheet.dart';

final logger = CrashlyticsLogger('UserPage');

class UserPage extends StatefulWidget {
  final bool stripeOnboardingComplete;

  const UserPage({Key? key, this.stripeOnboardingComplete = false})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return UserPageState();
  }
}

class UserPageState extends State<UserPage> {
  final verticalSpace = SizedBox(height: 20);

  String? appVersion;
  int _versionTapCount = 0;

  Future<void> _onVersionTap() async {
    _versionTapCount += 1;
    if (_versionTapCount < 5) return;

    final nextRuntimeMode = !AppConfig.runtimeTestMode;

    await AppConfig.setRuntimeTestModePersisted(nextRuntimeMode);
    context.read<UserState>().setTestMode(AppConfig.testMode);
    _versionTapCount = 0;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(nextRuntimeMode ? "Test mode enabled" : "Test mode disabled"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> myInitState() async {
    await AppConfig.loadRuntimeOverrides();
    context.read<UserState>().setTestMode(AppConfig.testMode);

    await FirebaseAnalytics.instance.logEvent(name: "open_user_page");
    appVersion = await getVersion();
    await refreshPageState();
  }

  Future<void> refreshPageState() async => Future.wait([
        context.read<UserState>().fetchLoggedUserDetails(),
        context.read<UserState>().fetchLoggedUserSportCenters(),
      ]);

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
        _UserProfileWithStats(userDetails: userDetails),
        verticalSpace,
        Row(children: [
          Expanded(
            child: _PlayersPlayedWithYou(playerCounts: userDetails.playedWith),
          ),
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

              widgets.add(IntrinsicHeight(
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    Expanded(child: Builder(builder: (BuildContext context) {
                      int n = userDetails.createdMatches!.length;
                      var dashboardWidgets = List<Widget>.from([]);

                      if (userDetails.isOrganiser(AppConfig.testMode) &&
                          userDetails.areChargesEnabled(AppConfig.testMode))
                        dashboardWidgets.addAll([
                          Row(children: [
                            Expanded(
                                child: GenericButtonWithLoader(
                                    AppLocalizations.of(context)!
                                        .goToStripeDashboardText, (_) async {
                              var url = CloudFunctionsClient().getUrl(
                                  "stripe/account?is_test=${AppConfig.testMode}&user_id=${userDetails.documentId}");

                              await launchUrl(Uri.parse(url),
                                  mode: LaunchMode.externalApplication);
                            }, Primary()))
                          ]),
                        ]);

                      return UserInfoBox(
                        content: (loadSkeleton) ? null : n.toString(),
                        description: AppLocalizations.of(context)!
                            .organizedMatchesBoxTitle,
                        bottom: Column(children: dashboardWidgets),
                      );
                    })),
                    SizedBox(width: 20),
                    Expanded(
                      child: _YourCourtsCard(),
                    ),
                  ])));

              widgets.addAll([
                verticalSpace,
                Row(
                  children: [
                    Expanded(
                      child: _PlayersInYourGames(
                          playerCounts: userDetails.organizerPlayers),
                    ),
                  ],
                ),
                verticalSpace,
                _PaymentMethodsCard(
                  userDetails: userDetails,
                  stripeOnboardingComplete: widget.stripeOnboardingComplete,
                ),
              ]);

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
        if (appVersion != null)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Center(
              child: InkWell(
                onTap: () async => _onVersionTap(),
                child: Container(
                  child: Text(
                    "v $appVersion",
                    style: TextPalette.bodyText,
                    textAlign: TextAlign.right,
                  ),
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
      // top level tab: the bottom bar is the navigation, no back arrow
      showTopBar: false,
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
        Text(description!,
            style: TextPalette.bodyText, textAlign: TextAlign.center),
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

class _PaymentMethodsCard extends StatefulWidget {
  final UserDetails userDetails;
  final bool stripeOnboardingComplete;

  const _PaymentMethodsCard({
    Key? key,
    required this.userDetails,
    this.stripeOnboardingComplete = false,
  }) : super(key: key);

  @override
  State<_PaymentMethodsCard> createState() => _PaymentMethodsCardState();
}

class _PaymentMethodsCardState extends State<_PaymentMethodsCard> {
  /// null = not checking, true = verified, false = still pending
  bool? _stripeVerificationResult;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    var alreadyEnabled =
        widget.userDetails.areChargesEnabled(AppConfig.testMode);
    if (!alreadyEnabled) {
      var hasAccount = widget.userDetails
              .getStripeInfo(AppConfig.testMode)
              .connectedAccountId !=
          null;
      if (hasAccount) {
        _stripeVerificationResult = false;
      }

      listenForStripeReturn(() {
        if (mounted) _checkStripeStatus();
      });
      if (widget.stripeOnboardingComplete) {
        _checkStripeStatus();
      }
    }
  }

  Future<void> _checkStripeStatus() async {
    setState(() => _isVerifying = true);
    try {
      // Refresh user details from Firestore (webhook may have already updated charges_enabled)
      await context.read<UserState>().fetchLoggedUserDetails();
      var updated = context.read<UserState>().getLoggedUserDetails();
      var chargesEnabled =
          updated?.areChargesEnabled(AppConfig.testMode) ?? false;
      if (mounted) {
        setState(() {
          _stripeVerificationResult = chargesEnabled;
          _isVerifying = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _stripeVerificationResult = false;
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InfoContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Pay outside Nutmeg ---
          PayOutsideNutmegRow(),

          // --- Pay with Nutmeg ---
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Palette.greyLighter),
          ),
          PayThroughNutmegRow(),

          // --- Verification banner (shown after returning from Stripe) ---
          if (_isVerifying || _stripeVerificationResult == true) ...[
            SizedBox(height: 12),
            _buildVerificationBanner(context),
          ],
        ],
      ),
    );
  }

  Widget _buildVerificationBanner(BuildContext context) {
    if (_isVerifying) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
            ),
            SizedBox(width: 10),
            Text(AppLocalizations.of(context)!.stripeVerifying,
                style: TextPalette.getBodyText(Colors.blue.shade700)),
          ],
        ),
      );
    }

    if (_stripeVerificationResult == true) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Palette.green, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(AppLocalizations.of(context)!.stripeVerified,
                  style: TextPalette.getBodyText(Palette.green)),
            ),
          ],
        ),
      );
    }

    return SizedBox.shrink();
  }
}

class _PlayersInYourGames extends StatelessWidget {
  final Map<String, int>? playerCounts;

  const _PlayersInYourGames({required this.playerCounts});

  @override
  Widget build(BuildContext context) {
    var count = playerCounts?.length ?? 0;

    return InkWell(
      onTap: (playerCounts != null && playerCounts!.isNotEmpty)
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => _PlayerCountsPage(
                        title: AppLocalizations.of(context)!
                            .playedInYourGamesBoxTitle
                            .toUpperCase(),
                        playerCounts: playerCounts!)),
              )
          : null,
      child: UserInfoBox(
        content: count.toString(),
        description: AppLocalizations.of(context)!.playedInYourGamesBoxTitle,
        rightBadge: (playerCounts != null && playerCounts!.isNotEmpty)
            ? Icon(Icons.chevron_right, color: Palette.primary, size: 18)
            : null,
      ),
    );
  }
}

class _YourCourtsCard extends StatelessWidget {
  const _YourCourtsCard();

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserState>();
    final courts = userState.getSportCenters();
    final count = courts?.length ?? 0;

    return InkWell(
      onTap: () async {
        await context.read<UserState>().fetchLoggedUserSportCenters();
        await ModalBottomSheet.showNutmegModalBottomSheet(
            context, LocationsBottomSheet());
      },
      child: UserInfoBox(
        content: count.toString(),
        description: AppLocalizations.of(context)!.courtsTitle,
        rightBadge: Icon(Icons.chevron_right, color: Palette.primary, size: 18),
      ),
    );
  }
}

class _PlayersPlayedWithYou extends StatelessWidget {
  final Map<String, int>? playerCounts;

  const _PlayersPlayedWithYou({required this.playerCounts});

  @override
  Widget build(BuildContext context) {
    var count = playerCounts?.length ?? 0;

    return InkWell(
      onTap: (playerCounts != null && playerCounts!.isNotEmpty)
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => _PlayerCountsPage(
                        title: AppLocalizations.of(context)!
                            .playedWithYouBoxTitle
                            .toUpperCase(),
                        playerCounts: playerCounts!)),
              )
          : null,
      child: UserInfoBox(
        content: count.toString(),
        description: AppLocalizations.of(context)!.playedWithYouBoxTitle,
        rightBadge: (playerCounts != null && playerCounts!.isNotEmpty)
            ? Icon(Icons.chevron_right, color: Palette.primary, size: 18)
            : null,
      ),
    );
  }
}

class _PlayerCountsPage extends StatefulWidget {
  final String title;
  final Map<String, int> playerCounts;

  const _PlayerCountsPage({required this.title, required this.playerCounts});

  @override
  State<_PlayerCountsPage> createState() => _PlayerCountsPageState();
}

class _PlayerCountsPageState extends State<_PlayerCountsPage> {
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
              color: Palette.black, onPressed: () => Navigator.pop(context)),
        ],
      ),
      widgets: [
        Text(widget.title, style: TextPalette.h4),
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
                      child: ud == null
                          ? Skeletons.lText
                          : Text(
                              UserDetails.getDisplayName(ud),
                              style: TextPalette.getBodyText(Palette.black),
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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

// --- Stats card widgets ---

/// The profile header: the player as a card, with the FIFA-style attributes
/// once enough teammates have given them traits, and the usual stats below.
class _UserProfileWithStats extends StatefulWidget {
  final UserDetails userDetails;

  const _UserProfileWithStats({required this.userDetails});

  @override
  State<_UserProfileWithStats> createState() => _UserProfileWithStatsState();
}

class _UserProfileWithStatsState extends State<_UserProfileWithStats> {
  UserDetails get userDetails => widget.userDetails;

  // the card's OVR, the same as in the group's All time table; asked for
  // separately because it needs the player's matches
  int? _score;
  int? _winPercent;

  @override
  void initState() {
    super.initState();
    _loadScore();
  }

  Future<void> _loadScore() async {
    try {
      var r = await CloudFunctionsClient()
          .get("users/${userDetails.documentId}/all_time_score");
      if (mounted) {
        setState(() {
          _score = (r?["all_time_score"] as num?)?.toInt();
          var played = (r?["played"] as num?)?.toInt() ?? 0;
          var wins = (r?["wins"] as num?)?.toInt() ?? 0;
          if (played > 0) _winPercent = (100 * wins / played).round();
        });
      }
    } catch (e) {
      logger.warning("Could not load the all time score: $e");
    }
  }

  Future<void> _changePicture(BuildContext context) async {
    try {
      await UserController.updloadPicture(context, userDetails);
    } catch (e, s) {
      logger.severe("Error updating profile picture", e, s);
    }
  }

  /// The title of the card: a role from the player's best attribute, once they
  /// have attributes and one clearly stands out; the app's name before that.
  static const _roles = {
    "PAC": "SPEEDSTER",
    "SHO": "FINISHER",
    "PAS": "PLAYMAKER",
    "DRI": "DRIBBLER",
    "DEF": "ROCK",
    "PHY": "POWERHOUSE",
    "GK": "KEEPER",
  };
  static const _minRoleValue = 65;

  static String _title(Map<String, int> attributes) {
    if (attributes.isEmpty) return "NUTMEG";
    var best = attributes.entries.reduce((a, b) => b.value > a.value ? b : a);
    return best.value >= _minRoleValue
        ? _roles[best.key] ?? "NUTMEG"
        : "NUTMEG";
  }

  /// Attributes in the order FIFA shows them, three to a line.
  static const _attributes = ["PAC", "SHO", "PAS", "DRI", "DEF", "PHY"];

  FifaCard _card(BuildContext context,
      {required double maxWidth, required bool editable}) {
    final attributes = userDetails.traitAttributes ?? {};
    final hasAttributes = attributes.isNotEmpty;
    return FifaCard(
      user: userDetails,
      score: _score,
      title: _title(attributes),
      theme: FifaTheme.gold,
      maxWidth: maxWidth,
      layout: hasAttributes ? FifaStatsLayout.grid : FifaStatsLayout.columns,
      stats: hasAttributes
          ? [for (var a in _attributes) FifaStat(a, "${attributes[a] ?? "–"}")]
          : [
              FifaStat("MATCHES", "${userDetails.numJoinedMatches ?? 0}"),
              FifaStat("WINS", "${userDetails.numWin ?? 0}"),
              FifaStat(
                  "AVG SCORE",
                  userDetails.averageScore == null
                      ? "–"
                      : userDetails.averageScore!.toStringAsFixed(2)),
            ],
      // goalkeeping only shows for players who are given it
      extra: attributes.containsKey("GK") ? "GK ${attributes["GK"]}" : null,
      onPictureTap: !editable ? null : () => _changePicture(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasAttributes = (userDetails.traitAttributes ?? {}).isNotEmpty;
    return Column(
      children: [
        _card(context, maxWidth: 240, editable: true),
        SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          TextButton.icon(
            onPressed: () => _changePicture(context),
            icon: Icon(Icons.camera_alt_outlined, size: 18),
            label: Text(l10n.changePhotoAction),
          ),
          SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => showFifaCard(
                context, _card(context, maxWidth: 260, editable: false)),
            icon: Icon(Icons.ios_share, size: 18),
            label: Text(l10n.shareAction),
          ),
        ]),
        if (!hasAttributes)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(l10n.profileCardAttributesHint,
                textAlign: TextAlign.center,
                style: TextPalette.getBodyText(Palette.greyDark)
                    .copyWith(fontSize: 12)),
          ),
        SizedBox(height: 16),
        InfoContainer(
            child: UserStatsCard.buildStatsContent(context, userDetails,
                winPercent: _winPercent)),
      ],
    );
  }
}

class UserStatsCard extends StatelessWidget {
  final UserDetails userDetails;

  const UserStatsCard({Key? key, required this.userDetails}) : super(key: key);

  /// Two stats to a row. `winPercent` is the share of games won; without it,
  /// it is worked out from the player's record.
  static Widget buildStatsContent(BuildContext context, UserDetails userDetails,
      {int? winPercent}) {
    final l10n = AppLocalizations.of(context)!;
    final wins = userDetails.numWin ?? 0;
    final games =
        wins + (userDetails.numDraw ?? 0) + (userDetails.numLoss ?? 0);
    final percent =
        winPercent ?? (games == 0 ? null : (100 * wins / games).round());
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatItemWithIcon(
                  icon: Icons.sports_soccer,
                  backgroundColor: Color(0xFF4CAF50),
                  label: l10n.numMatchesTitle,
                  value: userDetails.getNumJoinedMatches().toString(),
                ),
              ),
              Expanded(
                child: _StatItemWithIcon(
                  icon: Icons.star,
                  backgroundColor: Palette.primary,
                  label: l10n.averageScoreBoxTitle,
                  value: (userDetails.getScoreMatches() == null)
                      ? "-"
                      : userDetails.getScoreMatches()!.toStringAsFixed(1),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 28),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatItemWithIcon(
                  icon: Icons.emoji_events,
                  backgroundColor: Palette.accent,
                  label: l10n.numPlayersOfTheMatchBoxTitle,
                  value: userDetails.getNumManOfTheMatch().toString(),
                ),
              ),
              Expanded(
                child: _StatItemWithIcon(
                  icon: Icons.percent_rounded,
                  backgroundColor: Palette.green,
                  // a ring filled to the win rate in place of the hexagon
                  progress: percent == null ? 0 : percent / 100,
                  label: l10n.winPercentBoxTitle,
                  value: percent == null ? "-" : "$percent%",
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return InfoContainer(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: buildStatsContent(context, userDetails),
    );
  }
}

class _StatItemWithIcon extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final String label;
  final String value;
  // 0 to 1: a ring filled that far, in place of the hexagon
  final double? progress;

  const _StatItemWithIcon({
    required this.icon,
    required this.backgroundColor,
    required this.label,
    required this.value,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (progress != null)
          CustomPaint(
            painter: _RingPainter(progress: progress!, color: backgroundColor),
            child: SizedBox(
              width: 56,
              height: 56,
              child:
                  Center(child: Icon(icon, color: backgroundColor, size: 22)),
            ),
          )
        else
          CustomPaint(
            painter: _HexagonPainter(color: backgroundColor),
            child: SizedBox(
              width: 52,
              height: 56,
              child: Center(
                child: Icon(icon, color: Colors.white, size: 24, shadows: [
                  Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2))
                ]),
              ),
            ),
          ),
        SizedBox(height: 12),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: Text(label,
                style: TextPalette.bodyText, textAlign: TextAlign.center),
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.roboto(
            color: Palette.black,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// A ring filled clockwise from the top to `progress` (0 to 1), like a gauge.
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final rect = Rect.fromCircle(
        center: size.center(Offset.zero),
        radius: (size.shortestSide - stroke) / 2);
    canvas.drawArc(
        rect,
        0,
        2 * pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = Palette.greyLighter);
    canvas.drawArc(
        rect,
        -pi / 2,
        2 * pi * progress.clamp(0.0, 1.0),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

class _HexagonPainter extends CustomPainter {
  final Color color;

  _HexagonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final r = w * 0.08; // corner radius

    // Hexagon vertices (pointy-top)
    final points = [
      Offset(w * 0.5, 0), // top
      Offset(w, h * 0.25), // top-right
      Offset(w, h * 0.75), // bottom-right
      Offset(w * 0.5, h), // bottom
      Offset(0, h * 0.75), // bottom-left
      Offset(0, h * 0.25), // top-left
    ];

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final prev = points[(i - 1 + points.length) % points.length];
      final curr = points[i];
      final next = points[(i + 1) % points.length];

      // Points pulled inward along the edges by radius amount
      final inFromPrev = _lerpOffset(curr, prev, r / (curr - prev).distance);
      final inToNext = _lerpOffset(curr, next, r / (curr - next).distance);

      if (i == 0) {
        path.moveTo(inFromPrev.dx, inFromPrev.dy);
      } else {
        path.lineTo(inFromPrev.dx, inFromPrev.dy);
      }
      path.quadraticBezierTo(curr.dx, curr.dy, inToNext.dx, inToNext.dy);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  Offset _lerpOffset(Offset a, Offset b, double t) {
    return Offset(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
