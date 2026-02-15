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
import 'package:nutmeg/widgets/FeedbackBottomModal.dart';
import 'package:nutmeg/widgets/PageTemplate.dart';
import 'package:nutmeg/widgets/PlayerBottomModal.dart';
import 'package:nutmeg/widgets/Section.dart';
import 'package:nutmeg/widgets/Skeletons.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nutmeg/l10n/app_localizations.dart';

import '../state/UserState.dart';
import '../state/UsersState.dart';
import '../utils/InfoModals.dart';
import '../widgets/ModalBottomSheet.dart';

final logger = CrashlyticsLogger('UserPage');

class UserPage extends StatefulWidget {
  final bool stripeOnboardingComplete;

  const UserPage({Key? key, this.stripeOnboardingComplete = false}) : super(key: key);

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
        _UserProfileWithStats(userDetails: userDetails),
        if (userDetails.playedWith != null &&
            userDetails.playedWith!.isNotEmpty) ...[
          verticalSpace,
          Row(children: [
            Expanded(
              child: _PlayersPlayedWithYou(
                  playerCounts: userDetails.playedWith),
            ),
          ]),
        ],
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

              widgets.add(Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      child: _PlayersInYourGames(
                          playerCounts: userDetails.organizerPlayers),
                    ),
                  ]));

              widgets.addAll([
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
    if (widget.stripeOnboardingComplete) {
      _checkStripeStatus();
    }
  }

  Future<void> _checkStripeStatus() async {
    setState(() => _isVerifying = true);
    try {
      var userId = widget.userDetails.documentId;
      var result = await CloudFunctionsClient().get(
        'stripe/account/status',
        args: {'user_id': userId},
      );
      var chargesEnabled = result?['charges_enabled'] == true;
      setState(() {
        _stripeVerificationResult = chargesEnabled;
        _isVerifying = false;
      });
      // Refresh user details so the rest of the UI updates
      if (chargesEnabled && mounted) {
        context.read<UserState>().fetchLoggedUserDetails();
      }
    } catch (e) {
      setState(() {
        _stripeVerificationResult = false;
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var userDetails = widget.userDetails;
    var hasPaymentInfo = userDetails.paymentInfo != null &&
        userDetails.paymentInfo!.isNotEmpty;
    var stripeEnabled = userDetails.areChargesEnabled(AppConfig.testMode);

    return InfoContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Pay outside Nutmeg ---
          InkWell(
            onTap: () => _showEditPaymentInfoModal(context),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    color: Palette.primary, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.payOutsideNutmegTitle, style: TextPalette.h3),
                      SizedBox(height: 4),
                      hasPaymentInfo
                          ? buildLinkedText(
                              userDetails.paymentInfo!,
                              TextPalette.getBodyText(Palette.black),
                            )
                          : Text(
                              AppLocalizations.of(context)!
                                  .paymentInfoProfileDesc,
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

          // --- Pay with Nutmeg ---
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Palette.greyLighter),
          ),
          if (ConfigsUtils.allowNutmegManagedPayments())
            InkWell(
              onTap: stripeEnabled ? null : () => _showHowItWorksModal(context),
              child: Row(
                children: [
                  Icon(Icons.credit_card_outlined,
                      color: stripeEnabled ? Palette.primary : Palette.greyLight,
                      size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.payWithNutmegTitle,
                            style: TextPalette.getH3(stripeEnabled
                                ? Palette.black
                                : Palette.greyDark)),
                        SizedBox(height: 4),
                        if (stripeEnabled)
                          Text(AppLocalizations.of(context)!.stripeIntegrationActive,
                              style: TextPalette.getBodyText(Palette.green))
                        else
                          Text(
                              AppLocalizations.of(context)!.payWithNutmegNotConfigured,
                              style:
                                  TextPalette.getBodyText(Palette.greyDark)),
                      ],
                    ),
                  ),
                  if (!stripeEnabled) ...[
                    SizedBox(width: 8),
                    Icon(Icons.info_outline,
                        color: Palette.primary, size: 20),
                  ],
                  if (stripeEnabled) ...[
                    SizedBox(width: 8),
                    Icon(Icons.check_circle,
                        color: Palette.green, size: 20),
                  ],
                ],
              ),
            )
          else
            Row(
              children: [
                Icon(Icons.credit_card_outlined,
                    color: Palette.greyLight, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.payWithNutmegTitle,
                          style: TextPalette.getH3(Palette.greyDark)),
                      SizedBox(height: 4),
                      Text(AppLocalizations.of(context)!.comingSoon,
                          style: TextPalette.getBodyText(Palette.greyDark)),
                    ],
                  ),
                ),
              ],
            ),

          // --- Verification banner (shown after returning from Stripe) ---
          if (_isVerifying || _stripeVerificationResult != null) ...[
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
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
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

    // charges not yet enabled
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_top, color: Colors.orange.shade700, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(AppLocalizations.of(context)!.stripeVerificationPending,
                style: TextPalette.getBodyText(Colors.orange.shade700)),
          ),
        ],
      ),
    );
  }

  void _showHowItWorksModal(BuildContext context) {
    ModalBottomSheet.showNutmegModalBottomSheet(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppLocalizations.of(context)!.howPayWithNutmegWorks, style: TextPalette.h2),
          SizedBox(height: 20),
          _stepRow("1", AppLocalizations.of(context)!.stripeStep1),
          SizedBox(height: 14),
          _stepRow("2", AppLocalizations.of(context)!.stripeStep2),
          SizedBox(height: 14),
          _stepRow("3", AppLocalizations.of(context)!.stripeStep3),
          SizedBox(height: 14),
          _stepRow("4", AppLocalizations.of(context)!.stripeStep4),
          SizedBox(height: 16),
          _infoRow(AppLocalizations.of(context)!.stripeInfoRefund),
          SizedBox(height: 10),
          _infoRow(AppLocalizations.of(context)!.stripeInfoFee),
          SizedBox(height: 24),
          Row(children: [
            Expanded(
                child: GenericButtonWithLoader(
                    AppLocalizations.of(context)!.setupStripeIntegration, (_) async {
              await completeAccountAction(context, AppConfig.testMode);
              Navigator.pop(context);
            }, Primary()))
          ]),
        ],
      ),
    );
  }

  static Widget _stepRow(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Palette.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(number, style: TextPalette.getH3(Palette.white)),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(text, style: TextPalette.bodyText),
        ),
      ],
    );
  }

  static Widget _infoRow(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Center(
            child: Icon(Icons.info_outline, color: Palette.greyLight, size: 22),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(text, style: TextPalette.bodyText),
        ),
      ],
    );
  }

  void _showEditPaymentInfoModal(BuildContext context) {
    var controller =
        TextEditingController(text: widget.userDetails.paymentInfo ?? "");

    ModalBottomSheet.showNutmegModalBottomSheet(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppLocalizations.of(context)!.payOutsideNutmegTitle, style: TextPalette.h2),
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
                child: GenericButtonWithLoader(
                    AppLocalizations.of(context)!.save, (_) async {
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

class _PlayersInYourGames extends StatelessWidget {
  final Map<String, int>? playerCounts;

  const _PlayersInYourGames({required this.playerCounts});

  @override
  Widget build(BuildContext context) {
    var count = playerCounts?.length;

    return InkWell(
      onTap: (playerCounts != null && playerCounts!.isNotEmpty)
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => _PlayerCountsPage(
                        title: "PLAYED IN YOUR GAMES",
                        playerCounts: playerCounts!)),
              )
          : null,
      child: UserInfoBox(
        content: count?.toString(),
        description: "Played in your games",
        rightBadge: (playerCounts != null && playerCounts!.isNotEmpty)
            ? Icon(Icons.chevron_right, color: Palette.primary, size: 18)
            : null,
      ),
    );
  }
}

class _PlayersPlayedWithYou extends StatelessWidget {
  final Map<String, int>? playerCounts;

  const _PlayersPlayedWithYou({required this.playerCounts});

  @override
  Widget build(BuildContext context) {
    var count = playerCounts?.length;

    return InkWell(
      onTap: (playerCounts != null && playerCounts!.isNotEmpty)
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => _PlayerCountsPage(
                        title: "PLAYED WITH YOU",
                        playerCounts: playerCounts!)),
              )
          : null,
      child: UserInfoBox(
        content: count?.toString(),
        description: "Played with you",
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

  const _PlayerCountsPage(
      {required this.title, required this.playerCounts});

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
              color: Palette.black,
              onPressed: () => Navigator.pop(context)),
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

// --- Stats card widgets ---

class _UserProfileWithStats extends StatelessWidget {
  final UserDetails userDetails;
  static const double _avatarRadius = 50;

  const _UserProfileWithStats({required this.userDetails});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Stats card, pushed down to make room for the avatar
        Padding(
          padding: EdgeInsets.only(top: _avatarRadius),
          child: InfoContainer(
            padding: EdgeInsets.only(
              top: _avatarRadius + 16,
              left: 16,
              right: 16,
              bottom: 24,
            ),
            child: Column(
              children: [
                Text(userDetails.name ?? "N/A",
                    style: TextPalette.getH2(Palette.black)),
                if (userDetails.location != null) ...[
                  SizedBox(height: 4),
                  Text(userDetails.location!.getText(),
                      style: TextPalette.bodyText),
                ],
                SizedBox(height: 24),
                UserStatsCard.buildStatsContent(context, userDetails),
              ],
            ),
          ),
        ),
        // Avatar overlapping the top edge
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
                size: 12.0, color: Palette.white),
            showBadge: true,
            badgeStyle: BadgeStyle(
              badgeColor: Palette.primary,
              padding: EdgeInsets.all(4),
            ),
            position: BadgePosition.custom(bottom: -2.0, end: -2.0),
            child: UserAvatar(_avatarRadius, userDetails),
          ),
        ),
      ],
    );
  }
}

class UserStatsCard extends StatelessWidget {
  final UserDetails userDetails;

  const UserStatsCard({Key? key, required this.userDetails}) : super(key: key);

  static Widget buildStatsContent(
      BuildContext context, UserDetails userDetails) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatItemWithIcon(
                icon: Icons.sports_soccer,
                backgroundColor: Color(0xFF4CAF50),
                label: AppLocalizations.of(context)!.numMatchesTitle,
                value: userDetails.getNumJoinedMatches().toString(),
              ),
            ),
            Expanded(
              child: _StatItemWithIcon(
                icon: Icons.star,
                backgroundColor: Palette.primary,
                label: AppLocalizations.of(context)!.averageScoreBoxTitle,
                value: (userDetails.getScoreMatches() == null)
                    ? "-"
                    : userDetails.getScoreMatches()!.toStringAsFixed(1),
              ),
            ),
            Expanded(
              child: _StatItemWithIcon(
                icon: Icons.emoji_events,
                backgroundColor: Palette.accent,
                label:
                    AppLocalizations.of(context)!.numPlayersOfTheMatchBoxTitle,
                value: userDetails.getNumManOfTheMatch().toString(),
              ),
            ),
          ],
        ),
        SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: _SimpleStatItem(
                label: AppLocalizations.of(context)!.numMatchesWonBoxTitle,
                value: (userDetails.numWin ?? 0).toString(),
              ),
            ),
            Expanded(
              child: _SimpleStatItem(
                label: AppLocalizations.of(context)!.numMatchesDrawBoxTitle,
                value: (userDetails.numDraw ?? 0).toString(),
              ),
            ),
            Expanded(
              child: _SimpleStatItem(
                label: AppLocalizations.of(context)!.numMatchesLostBoxTitle,
                value: (userDetails.numLoss ?? 0).toString(),
              ),
            ),
          ],
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

  const _StatItemWithIcon({
    required this.icon,
    required this.backgroundColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomPaint(
          painter: _HexagonPainter(color: backgroundColor),
          child: SizedBox(
            width: 52,
            height: 56,
            child: Center(
              child: Icon(icon, color: Colors.white, size: 24,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]),
            ),
          ),
        ),
        SizedBox(height: 12),
        Text(label, style: TextPalette.bodyText),
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

class _SimpleStatItem extends StatelessWidget {
  final String label;
  final String value;

  const _SimpleStatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextPalette.bodyText),
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
      Offset(w * 0.5, 0),       // top
      Offset(w, h * 0.25),      // top-right
      Offset(w, h * 0.75),      // bottom-right
      Offset(w * 0.5, h),       // bottom
      Offset(0, h * 0.75),      // bottom-left
      Offset(0, h * 0.25),      // top-left
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
