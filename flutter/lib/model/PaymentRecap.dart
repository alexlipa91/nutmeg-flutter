class PaymentRecap {

  PaymentRecap(this.matchPriceInCents, this.creditsInCentsUsed, this.fee);

  int matchPriceInCents;   // includes fee
  int creditsInCentsUsed;
  int fee;

  finalPriceToPayInCents() => matchPriceInCents - creditsInCentsUsed;

  onlyCreditsUsed() => matchPriceInCents == creditsInCentsUsed;
}
