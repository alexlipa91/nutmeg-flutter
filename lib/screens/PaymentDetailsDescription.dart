import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/Buttons.dart';
import 'package:nutmeg/widgets/ModalBottomSheet.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../state/LoadOnceState.dart';

class PaymentDetailsDescription {
  static Future<void> communicateSuccessToUser(BuildContext? context,
      String matchId) async {
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
                    (context!.read<LoadOnceState>().getRandomGif())),
              ),
              Padding(
                  padding: EdgeInsets.only(top: 30),
                  child: Text(AppLocalizations.of(context)!.joinMatchSuccessTitle,
                      style: TextPalette.h1Default)),
              Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(AppLocalizations.of(context)!.joinedMatchText,
                      style: TextPalette.bodyText)),
              if (!DeviceInfo().name.contains("ipad"))
                Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: ShareButtonWithText(matchId, Palette.primary))
            ],
          ),
        )));
  }
}
