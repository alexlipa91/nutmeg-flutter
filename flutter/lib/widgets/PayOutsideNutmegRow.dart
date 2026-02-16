import 'package:flutter/material.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:nutmeg/widgets/ModalBottomSheet.dart';
import 'package:provider/provider.dart';
import 'package:nutmeg/l10n/app_localizations.dart';

import '../state/UserState.dart';

class PayOutsideNutmegRow extends StatelessWidget {
  const PayOutsideNutmegRow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var userDetails = context.watch<UserState>().getLoggedUserDetails();
    var hasPaymentInfo = userDetails?.paymentInfo != null &&
        userDetails!.paymentInfo!.isNotEmpty;

    return InkWell(
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
                Text(AppLocalizations.of(context)!.payOutsideNutmegTitle,
                    style: TextPalette.h3),
                SizedBox(height: 4),
                hasPaymentInfo
                    ? buildLinkedText(
                        userDetails!.paymentInfo!,
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
    );
  }

  void _showEditPaymentInfoModal(BuildContext context) {
    var userDetails = context.read<UserState>().getLoggedUserDetails();
    var controller =
        TextEditingController(text: userDetails?.paymentInfo ?? "");

    ModalBottomSheet.showNutmegModalBottomSheet(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppLocalizations.of(context)!.payOutsideNutmegTitle,
              style: TextPalette.h2),
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
