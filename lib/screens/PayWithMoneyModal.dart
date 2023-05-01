import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../state/UserState.dart';

class PayWithMoneyButton extends StatelessWidget {
  final String matchId;

  const PayWithMoneyButton(
      {Key? key, required this.matchId})
      : super(key: key);

  @override
  Widget build(BuildContext context) => GenericButtonWithLoader(
        AppLocalizations.of(context)!.continueToPayment,
        (BuildContext context) async {
          context.read<GenericButtonWithLoaderState>().change(true);

          var userState = context.read<UserState>();

          var uri =
              Uri.parse(CloudFunctionsClient().getUrl("payments/checkout?"
                  "user_id=${userState.currentUserId}&match_id=$matchId&v=2"));

          if (kIsWeb)
            await launchUrl(uri, webOnlyWindowName: "_self");
          else
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        Primary(),
      );
}
