import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/state/MatchState.dart';
import 'package:nutmeg/state/UsersState.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/config/app_config.dart';
import 'package:nutmeg/widgets/Buttons.dart';
import 'package:nutmeg/widgets/ModalBottomSheet.dart';
import 'package:provider/provider.dart';
import 'package:nutmeg/l10n/app_localizations.dart';

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

    // Read all data from the outer context (providers aren't available inside modal)
    var organizerDetails = match?.organizerId != null
        ? context.read<UsersState>().getUserDetail(match!.organizerId!)
        : null;
    var organizerName =
        organizerDetails?.name?.split(" ").first ?? "the organizer";
    var paymentInfo = organizerDetails?.paymentInfo;
    var showReminder = isManualPayment &&
        !isOrganizer &&
        match?.organizerId != null &&
        ConfigsUtils.allowUsersToMarkPayments;

    await ModalBottomSheet.showNutmegModalBottomSheet(
        context,
        Container(
            child: Padding(
          padding: GenericInfoModal.padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Builder(builder: (context) {
                var gif = context.read<LoadOnceState>().getRandomGif();
                return CircleAvatar(
                  radius: 100,
                  backgroundColor: Palette.greyLighter,
                  backgroundImage:
                      gif != null ? CachedNetworkImageProvider(gif) : null,
                  child: gif == null
                      ? Icon(Icons.celebration, size: 60, color: Palette.primary)
                      : null,
                );
              }),
              Padding(
                  padding: EdgeInsets.only(top: 30),
                  child: Text(
                      AppLocalizations.of(context)!.joinMatchSuccessTitle,
                      style: TextPalette.h1Default)),
              Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(AppLocalizations.of(context)!.joinedMatchText,
                      style: TextPalette.bodyText)),
              if (showReminder)
                _PaymentReminder(
                  organizerName: organizerName,
                  paymentInfo: paymentInfo,
                  onToggle: () async {
                    var currentStatus =
                        match!.getPaymentStatus(loggedUserId!);
                    var newStatus =
                        currentStatus == "paid" ? "not_yet_paid" : "paid";
                    await matchState.setManualPaymentStatus(
                        loggedUserId, newStatus);
                  },
                ),
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
  final String organizerName;
  final String? paymentInfo;
  final Future<void> Function() onToggle;

  const _PaymentReminder({
    Key? key,
    required this.organizerName,
    required this.paymentInfo,
    required this.onToggle,
  }) : super(key: key);

  @override
  State<_PaymentReminder> createState() => _PaymentReminderState();
}

class _PaymentReminderState extends State<_PaymentReminder> {
  bool _hasPaid = false;

  Future<void> _toggleStatus() async {
    await widget.onToggle();
    setState(() {
      _hasPaid = !_hasPaid;
    });
  }

  @override
  Widget build(BuildContext context) {
    var organizerName = widget.organizerName;
    var paymentInfo = widget.paymentInfo;

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
                    AppLocalizations.of(context)!.dontForgetToPay(organizerName),
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
