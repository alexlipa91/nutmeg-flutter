import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/state/MatchState.dart';
import 'package:nutmeg/state/UsersState.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/Buttons.dart';
import 'package:nutmeg/widgets/ModalBottomSheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../state/LoadOnceState.dart';

class PaymentDetailsDescription {
  static Future<void> communicateSuccessToUser(
      BuildContext? context, String matchId) async {
    var matchState = context!.read<MatchState>();
    var match = matchState.match;
    var userState = context.read<UserState>();
    var loggedUserId = userState.getLoggedUserId();
    var isManualPayment = match?.isManualPayment ?? false;
    var isOrganizer = match?.organizerId == loggedUserId;

    await ModalBottomSheet.showNutmegModalBottomSheet(
        context,
        Container(
            child: Padding(
          padding: GenericInfoModal.padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 100,
                backgroundColor: Palette.greyLighter,
                backgroundImage: CachedNetworkImageProvider(
                    (context.read<LoadOnceState>().getRandomGif())),
              ),
              Padding(
                  padding: EdgeInsets.only(top: 30),
                  child: Text(
                      AppLocalizations.of(context)!.joinMatchSuccessTitle,
                      style: TextPalette.h1Default)),
              Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(AppLocalizations.of(context)!.joinedMatchText,
                      style: TextPalette.bodyText)),
              if (isManualPayment && !isOrganizer && match?.organizerId != null && ConfigsUtils.allowUsersToMarkPayments())
                _PaymentReminder(match: match!, matchId: matchId),
              if ((DeviceInfo().name?.contains("ipad") ?? false))
                Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: ShareButtonWithText(matchId, Palette.primary))
            ],
          ),
        )));
  }
}

class _PaymentReminder extends StatefulWidget {
  final Match match;
  final String matchId;

  const _PaymentReminder({Key? key, required this.match, required this.matchId})
      : super(key: key);

  @override
  State<_PaymentReminder> createState() => _PaymentReminderState();
}

class _PaymentReminderState extends State<_PaymentReminder> {
  bool _hasPaid = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    var prefs = await SharedPreferences.getInstance();
    var key = "${widget.matchId}-user-paid";
    setState(() {
      _hasPaid = prefs.getBool(key) ?? false;
    });
  }

  Future<void> _toggleStatus() async {
    var newStatus = !_hasPaid;
    var prefs = await SharedPreferences.getInstance();
    var key = "${widget.matchId}-user-paid";
    await prefs.setBool(key, newStatus);
    setState(() {
      _hasPaid = newStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    var organizerDetails = context
        .watch<UsersState>()
        .getUserDetail(widget.match.organizerId!);
    var organizerName =
        organizerDetails?.name?.split(" ").first ?? "the organizer";
    var paymentInfo = organizerDetails?.paymentInfo;

    return Padding(
      padding: EdgeInsets.only(top: 20),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Palette.greyLightest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment_outlined, color: Palette.primary, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Don't forget to pay $organizerName!",
                    style: TextPalette.bodyText
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (paymentInfo != null && paymentInfo.isNotEmpty) ...[
              SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Palette.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: buildLinkedText(
                    paymentInfo, TextPalette.getBodyText(Palette.black)),
              ),
            ],
            SizedBox(height: 12),
            Center(
              child: InkWell(
                onTap: _toggleStatus,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _hasPaid
                        ? Palette.green.withOpacity(0.15)
                        : Palette.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _hasPaid ? Palette.green : Palette.greyLight,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_hasPaid)
                        Padding(
                          padding: EdgeInsets.only(right: 6),
                          child:
                              Icon(Icons.check, color: Palette.green, size: 16),
                        ),
                      Text(
                        _hasPaid
                            ? AppLocalizations.of(context)!.paid
                            : AppLocalizations.of(context)!.iPaid,
                        style: TextPalette.getBodyText(
                                _hasPaid ? Palette.green : Palette.greyDark)
                            .copyWith(
                                fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
