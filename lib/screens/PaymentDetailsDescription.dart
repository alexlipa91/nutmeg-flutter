import 'package:flutter/material.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/screens/PayWithCreditsModal.dart';
import 'package:nutmeg/screens/PayWithMoneyModal.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/Buttons.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';


class PaymentDetailsDescription extends StatelessWidget {
  final Match match;
  final PaymentRecap paymentRecap;

  const PaymentDetailsDescription({Key key, this.match, this.paymentRecap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          CircleAvatar(
              backgroundImage: NetworkImage(
                  context.watch<UserState>().getUserDetails().getPhotoUrl()),
              radius: 15),
          SizedBox(width: 10),
          Text("1x player", style: TextPalette.h3),
          Expanded(
              child: Text(
            formatCurrency(match.pricePerPersonInCents),
            style: TextPalette.h3,
            textAlign: TextAlign.end,
          ))
        ]),
        if (paymentRecap.creditsInCentsUsed > 0)
          Row(
            children: [
              // adding this here as a trick to align the rows
              CircleAvatar(backgroundColor: Colors.transparent, radius: 15),
              SizedBox(width: 10),
              Text('Credits', style: TextPalette.bodyText),
              Expanded(
                  child: Text(
                "- " + formatCurrency(paymentRecap.creditsInCentsUsed),
                style: TextPalette.bodyText,
                textAlign: TextAlign.end,
              ))
            ],
          ),
        if (paymentRecap.creditsInCentsUsed > 0) Divider(),
        if (paymentRecap.creditsInCentsUsed > 0)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Subtotal", style: TextPalette.h3),
                Text(
                  formatCurrency(paymentRecap.finalPriceToPayInCents()),
                  style: TextPalette.h3,
                )
              ],
            ),
          ),
        Divider(),
        Row(
          children: [
            Expanded(
                child: (paymentRecap.finalPriceToPayInCents() == 0)
                    ? PayWithCreditsButton(
                        match: match, paymentRecap: paymentRecap)
                    : PayWithMoneyButton(match: match, paymentRecap: paymentRecap))
          ],
        )
      ],
    );
  }

  static Future<void> communicateSuccessToUser(
      BuildContext context, String matchId) async {
    await showModalBottomSheet(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        isScrollControlled: true,
        context: context,
        builder: (context) => Container(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 100,
                    backgroundColor: Palette.lightGrey,
                    backgroundImage: FadeInImage.memoryNetwork(
                      placeholder: kTransparentImage,
                      image: context.read<LoadOnceState>().getRandomGif(),
                    ).image,
                  ),
                  Padding(
                      padding: EdgeInsets.only(top: 30),
                      child: Text("You are in!", style: TextPalette.h1Default)),
                  Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text("You have joined the match.",
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
