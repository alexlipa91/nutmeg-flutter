class PaymentRecap {

  PaymentRecap(this.matchPriceInCents, this.creditsInCentsUsed);

  int matchPriceInCents;   // includes fee
  int creditsInCentsUsed;
  int fee = 50;

  finalPriceToPayInCents() => matchPriceInCents - creditsInCentsUsed;

  onlyCreditsUsed() => matchPriceInCents == creditsInCentsUsed;
}
