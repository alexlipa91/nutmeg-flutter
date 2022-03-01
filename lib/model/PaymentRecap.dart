import 'package:tuple/tuple.dart';


class PaymentRecap {

  PaymentRecap(this.matchPriceInCents, this.creditsInCentsUsed);

  int matchPriceInCents;
  int creditsInCentsUsed;

  finalPriceToPayInCents() => matchPriceInCents - creditsInCentsUsed;

  onlyCreditsUsed() => matchPriceInCents == creditsInCentsUsed;
}
