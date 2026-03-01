// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get topHeader => 'Find football matches near';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get going => 'Going';

  @override
  String get past => 'Past';

  @override
  String get myMatches => 'My Matches';

  @override
  String spotsLeft(int numSpots) {
    return '$numSpots spots left';
  }

  @override
  String get thisWeek => 'THIS WEEK';

  @override
  String get nextWeek => 'NEXT WEEK';

  @override
  String get moreThanTwoWeeks => 'IN MORE THAN TWO WEEKS';

  @override
  String get cancelledStatus => 'Cancelled';

  @override
  String get fullStatus => 'Full';

  @override
  String get votes => 'votes';

  @override
  String get matchDetailsScreen =>
      '*****************************************************************************************************';

  @override
  String cancellationInfo(String date, String hour, int n) {
    return 'The match will be automatically canceled on $date at $hour if less than $n players have joined.';
  }

  @override
  String get paymentPolicyHeader => 'Payment Policy';

  @override
  String get organizedBy => 'Organized By';

  @override
  String get editAction => 'Edit';

  @override
  String get shareAction => 'Share';

  @override
  String get linkCopiedToClipboard => 'Link copied to clipboard';

  @override
  String get shareMatchStats => 'Share Match Stats';

  @override
  String get shareMatchStatsText =>
      'Check out the stats of my last match with Nutmeg! ⚽️ 🔥';

  @override
  String get cancelMatchAction => 'Cancel Match';

  @override
  String get joinAction => 'Join';

  @override
  String get player => 'Player';

  @override
  String get showMore => 'SHOW MORE';

  @override
  String get showLess => 'SHOW LESS';

  @override
  String get statsWaiting => 'Stats available soon';

  @override
  String get statsNotEnoughRatings => 'Not enough ratings to compute stats';

  @override
  String statsAvailableAt(String date) {
    return 'Statistics for this match will be available\n$date';
  }

  @override
  String courtType(Object t) {
    return '$t Court Type';
  }

  @override
  String get changingRooms => 'Changing rooms available';

  @override
  String courtNumber(Object x) {
    return 'Court number $x';
  }

  @override
  String get artificialGrass => 'Grass';

  @override
  String get matchOnStatus => 'Match is on';

  @override
  String get matchSavedStatus => 'Match Saved';

  @override
  String get inProgressStatus => 'In Progress';

  @override
  String waitingForPlayersStatus(Object x) {
    return 'Waiting for $x more players';
  }

  @override
  String get locationHeader => 'Location';

  @override
  String listOfPlayersHeader(int x, int y) {
    return 'Players ($x/$y)';
  }

  @override
  String get joinMatchSuccessTitle => 'You are in!';

  @override
  String joinMatchBarSubtitle(int x) {
    return '$x players going';
  }

  @override
  String get joinButtonText => 'JOIN MATCH';

  @override
  String get leaveButtonText => 'LEAVE MATCH';

  @override
  String get joinThisMatchTitle => 'Join this match';

  @override
  String get joinMatchInfo => 'If you leave the match you will get a refund';

  @override
  String get leaveThisMatchTitle => 'Leave this match?';

  @override
  String get removePlayerTitle => 'Remove player?';

  @override
  String removePlayerSubtitle(String name) {
    return 'This will remove $name from the match.';
  }

  @override
  String get removePlayerRefundInfo =>
      'If the player paid, a refund will be issued.';

  @override
  String removePlayerRefundMessage(String name) {
    return '$name will be refunded on the payment method they used to pay.';
  }

  @override
  String get leaveMatchRefundTitle => 'Refund';

  @override
  String get leaveMatchCreditsRefundTitle => 'Credits Refund';

  @override
  String get leaveMatchInfo =>
      'We will refund you on the payment method you used to pay.';

  @override
  String leaveMatchServiceFeeInfo(String f) {
    return 'The service fee of $f will not be refunded';
  }

  @override
  String get leaveMatchNoMoneyInfo =>
      'Please confirm if you want to be removed from the players list';

  @override
  String get paymentFailedTitle => 'Payment Failed!';

  @override
  String get paymentFailedSubtitle => 'Please try again';

  @override
  String get manageButton => 'MANAGE';

  @override
  String get cancelMatchTitle => 'Are you sure you want to cancel the match?';

  @override
  String get cancelMatchSubtitle =>
      'If players paid with Nutmeg, they will get a full refund.';

  @override
  String get serviceFee => 'Service Fee';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get continueToPayment => 'CONTINUE TO PAYMENT';

  @override
  String get joinedMatchText => 'You have joined the match.';

  @override
  String continueWithButton(String p) {
    return 'CONTINUE WITH $p';
  }

  @override
  String get noMatchesHere => 'No matches here';

  @override
  String get browseOrCreateText => 'Browse matches or create your own match';

  @override
  String get createNewMatchActionText => 'CREATE NEW MATCH';

  @override
  String get newMatchTitle => 'New Match';

  @override
  String get editMatchTitle => 'Edit Match';

  @override
  String get crudMatchGeneralTitle => 'General';

  @override
  String get dateInputLabel => 'Date';

  @override
  String get startTimeInputLabel => 'Start Time';

  @override
  String get endTimeInputLabel => 'End Time';

  @override
  String get repeatInputLabel => 'Repeat';

  @override
  String get requiredError => 'Required';

  @override
  String get doesNotRepeatLabel => 'Does not repeat';

  @override
  String repeatForWeeks(int n) {
    return 'Weekly for $n weeks';
  }

  @override
  String lastMatchOn(String d) {
    return 'Last Match On $d';
  }

  @override
  String get courtSectionTitle => 'Court';

  @override
  String get locationSectionTitle => 'Location';

  @override
  String get courtNumberLabel => 'Court number (optional)';

  @override
  String get numberOfPlayersSectionTitle => 'Number of Players';

  @override
  String get numberOfPlayersInfo =>
      'This is the minimum and maximum amount of player that can join the match.';

  @override
  String get paymentSectionTitle => 'Payment';

  @override
  String get paymentEnableInfo =>
      'Allow users to pay for the match through Nutmeg';

  @override
  String get paymentNotPossibleInfo =>
      'We cannot process payments in this location yet';

  @override
  String get invalidAmountError => 'Invalid Amount';

  @override
  String get minimumAmountError => 'Minimum amount is € 0.50';

  @override
  String get pricePerPlayerLabel => 'Price per Player';

  @override
  String nutmegFeeInfo(String a) {
    return 'Nutmeg will withhold a service fee of $a per player';
  }

  @override
  String get youWillGetLabel => 'You will get';

  @override
  String get usersWillPayLabel => 'Users will pay';

  @override
  String get usersWillPayText => '(including Nutmeg fee)';

  @override
  String get paymentExplanationText =>
      'Nutmeg releases the money 24 hours after the match. You will get paid in 3 to 5 business days after that through';

  @override
  String get policiesSectionTitle => 'Policies';

  @override
  String get privateMatchInfo =>
      'Match is private. Users can join the match only through the shared link';

  @override
  String get privateMatchDesc => 'Private match';

  @override
  String get automaticCancellationInfo =>
      'Automatically cancel the match if minimum amount of players is not reached';

  @override
  String automaticCancellationExplanation(int x, String y) {
    return 'We will cancel the match if at least $x players haven\'t joined $y hours before the kick-off of the match.\nIf players have paid through Nutmeg, they will get a full refund';
  }

  @override
  String teamNameLabelText(String x) {
    return 'TEAM $x';
  }

  @override
  String get hoursLabel => 'Hours';

  @override
  String get youWantToLeaveTitle => 'Are you sure you want to leave?';

  @override
  String get youWantToLeaveSubtitle =>
      'If you leave, all your unsaved changes will be lost.';

  @override
  String get leftMatchTitle => 'You left the match';

  @override
  String get leftMatchContactOrganizerForRefund =>
      'Please contact the organizer for any refund';

  @override
  String get finalScoreSubmitText => 'What was the final score?';

  @override
  String get submitScoreButton => 'SUBMIT SCORE';

  @override
  String get editScoreButton => 'EDIT SCORE';

  @override
  String get cancelScoreButton => 'CANCEL';

  @override
  String get skipText => 'SKIP';

  @override
  String get nextText => 'NEXT';

  @override
  String get yes => 'Yes';

  @override
  String get cancel => 'Cancel';

  @override
  String get createButtonText => 'CREATE';

  @override
  String get confirmButtonText => 'CONFIRM';

  @override
  String get popularCourtsTitle => 'Popular Courts';

  @override
  String get yourCourtsTitle => 'Your Courts';

  @override
  String get matchStatsTitle => 'Top Performing Players';

  @override
  String matchStatsSubTitle(int n) {
    return '$n voters';
  }

  @override
  String get createNewCourtText => 'Create new Court';

  @override
  String get courtInfoText => 'Court Information';

  @override
  String get courtLocationLabel => 'Court Location';

  @override
  String get courtTypeTitleText => 'Court Type';

  @override
  String get surfaceLabelText => 'Surface';

  @override
  String get indoorTitle => 'Indoor';

  @override
  String get indoorDesc => 'Boots without studs';

  @override
  String get grassTitle => 'Grass';

  @override
  String get grassDesc => 'For boots that require studs';

  @override
  String get sizeTitle => 'Size';

  @override
  String get facilitiesTitle => 'Facilities';

  @override
  String get changeRoomsAvailableLabel => 'Change Rooms Available';

  @override
  String get searchLocationTitle => 'Search Location';

  @override
  String get searchLocationInputFieldLabel => 'Search';

  @override
  String get currentLocationLabel => 'CURRENT LOCATION';

  @override
  String get currentLocationInfo =>
      'Your location helps us improve your experience with approximate recommendations of matches.';

  @override
  String get manualSplitTeamCheckBoxLabel => 'Manual split';

  @override
  String get teamStrenghtLabel => 'Team strength';

  @override
  String get manualSplitTeamInfo =>
      'By default, we split the teams fairly based on players performance and overall team strength. You can manually split the teams yourself.';

  @override
  String get doneButtonText => 'DONE';

  @override
  String get modifyButtonText => 'MODIFY';

  @override
  String get genericErrorMessage => 'Something went wrong';

  @override
  String get genericErrorDesc => 'Please contact us for support.';

  @override
  String get ratePlayersTitle => 'Rate Players';

  @override
  String get ratePlayersButtonText => 'RATE PLAYERS';

  @override
  String get updateRatesPlayersButtonText => 'CHANGE VOTES';

  @override
  String get submitRatesButtonText => 'SUBMIT';

  @override
  String get accountTitle => 'Account';

  @override
  String get performanceTitle => 'PERFORMANCE';

  @override
  String get creditsBoxTitle => 'Credits';

  @override
  String get numMatchesShortTitle => 'Matches';

  @override
  String get numMatchesTitle => 'Matches';

  @override
  String get numPlayersOfTheMatchBoxTitle => 'POTM';

  @override
  String get numMatchesDrawBoxTitle => 'Draws';

  @override
  String get numMatchesWonBoxTitle => 'Wins';

  @override
  String get numMatchesLostBoxTitle => 'Losses';

  @override
  String get averageScoreBoxTitle => 'Avg. Score';

  @override
  String get organiserSectionTitle => 'ORGANISER';

  @override
  String get goToStripeDashboardText => 'GO TO MY STRIPE DASHBOARD';

  @override
  String get organizedMatchesBoxTitle => 'Organized Matches';

  @override
  String get playedInYourGamesBoxTitle => 'Played in your games';

  @override
  String get playedWithYouBoxTitle => 'Played with you';

  @override
  String get followOnIg => 'Follow us on Instagram';

  @override
  String get feedback => 'Give us feedback';

  @override
  String collectedAmountText(String amount, String count, String total) {
    return '$amount collected ($count/$total paid)';
  }

  @override
  String releaseScheduledText(String date) {
    return 'Money will be transferred to your Stripe account on $date';
  }

  @override
  String releaseCompletedText(String amount) {
    return '$amount transferred to your Stripe account';
  }

  @override
  String get changeLanguageButton => 'CHANGE LANGUAGE';

  @override
  String get languageModalTitle => 'Language';

  @override
  String get preMatchNotificationTitle => 'Ready for the match? u\"⚽️';

  @override
  String preMatchNotificationBody(String d, Object s) {
    return 'Your match today is at $d at $s. Tap here to check your team!';
  }

  @override
  String get leaderboardNoData => 'No available data';

  @override
  String get matchAwardsTitle => 'Match Awards';

  @override
  String get matchAwardsSubtitle =>
      'Vote for outstanding performances of the match';

  @override
  String get selectPlayerText => 'Select player';

  @override
  String get bestGoalAwardName => 'Best Goal';

  @override
  String get bestGoalAwardDesc => 'Most impressive goal of the match';

  @override
  String get bestStrikerAwardName => 'Best Striker';

  @override
  String get bestStrikerAwardDesc => 'Most impactful attacking player';

  @override
  String get bestGoalkeeperAwardName => 'Best Goalkeeper';

  @override
  String get bestGoalkeeperAwardDesc =>
      'Most crucial saves and defensive plays';

  @override
  String get bestDefenderAwardName => 'Best Defender';

  @override
  String get bestDefenderAwardDesc => 'Most solid defensive performance';

  @override
  String get ratePlayersThanksText => 'Thanks for rating!';

  @override
  String get ratePlayersTitleText => 'Rate players';

  @override
  String get updateRatesPlayersTitleText => 'Change votes';

  @override
  String ratesCloseInText(Object hours) {
    return 'Ratings close in $hours hours';
  }

  @override
  String get locationErrorTitle => 'Failed to get location!';

  @override
  String get locationErrorDescription => 'Please try again later.';

  @override
  String get setPaymentInfo => 'Set Payment Info';

  @override
  String get showPlayersPaymentInfo => 'Show players info for payments';

  @override
  String get paymentInfoHeader => 'Payment Info';

  @override
  String get yourPaymentInfo => 'Your payment info';

  @override
  String get noPaymentInfoYet => 'No payment info set yet';

  @override
  String get addPaymentInfo => 'ADD PAYMENT INFO';

  @override
  String get paymentInfoPlayersHint =>
      'Players who join will see this so they know how to pay you';

  @override
  String get paymentInfoShownToPlayers =>
      'This will be shown to players who join your matches';

  @override
  String get paymentInfoPlaceholder => 'e.g. Revolut @username, IBAN IT123...';

  @override
  String get paymentInfoProfileDesc =>
      'Add your payment details (e.g. Revolut, IBAN) so players know how to pay you';

  @override
  String get save => 'Save';

  @override
  String sharedPaymentDetails(String name) {
    return '$name shared these payment details:';
  }

  @override
  String get markedAsPaid => 'You marked this as paid';

  @override
  String get manualPaymentDisclaimer =>
      'Payment status is self-reported by players';

  @override
  String get undo => 'Undo';

  @override
  String get iPaid => 'Mark as Paid';

  @override
  String get notYet => 'Not yet';

  @override
  String get payOutsideNutmeg => 'Manual Payment';

  @override
  String get payThroughNutmeg => 'Nutmeg Pay';

  @override
  String get payWithStripe => 'PAY WITH STRIPE';

  @override
  String get paid => 'Paid';

  @override
  String get comingSoon => 'COMING SOON';

  @override
  String get payOutsideNutmegTitle => 'Pay outside Nutmeg';

  @override
  String get payWithNutmegTitle => 'Pay with Nutmeg';

  @override
  String get stripeIntegrationActive => 'See how it works';

  @override
  String get goToStripeDashboardButton => 'GO TO YOUR STRIPE DASHBOARD';

  @override
  String get payWithNutmegNotConfigured => 'Setup required. Tap to configure.';

  @override
  String get howPayWithNutmegWorks => 'How Pay with Nutmeg works';

  @override
  String get stripeStep1 =>
      'Create a Stripe Connected account with your bank details.';

  @override
  String get stripeStep2 =>
      'Create a game with a price (e.g. €5). Players pay via Stripe to join.';

  @override
  String get stripeStep3 =>
      'After the game, Nutmeg transfers payments minus a €0.50 fee per player to your Stripe account. E.g. 10 players pay €5, you get €45.';

  @override
  String get stripeStep4 =>
      'Stripe sends the money to your bank within a few days.';

  @override
  String get stripeInfoRefund =>
      'Players can cancel and get a full refund up to 24h before the game.';

  @override
  String get stripeInfoFee =>
      'The Nutmeg service fee helps cover Stripe transaction costs.';

  @override
  String get setupStripeIntegration => 'SETUP STRIPE INTEGRATION';

  @override
  String get stripeSetupInProgress => 'Setup in progress. Tap to continue.';

  @override
  String get stripeVerifying => 'Verifying your Stripe account…';

  @override
  String get stripeVerified => 'All good! Your Stripe integration is active.';

  @override
  String get stripeVerificationPending =>
      'Your Stripe setup is incomplete. Tap \'Pay with Nutmeg\' above to finish the setup and start receiving payments.';

  @override
  String get stripeSetupRequired =>
      'You need to set up Stripe before creating a paid game. Complete the setup first.';

  @override
  String get stripeNutmegFeeLabel => 'Nutmeg service fee';

  @override
  String get stripePayoutExplanation =>
      'Money is transferred to your Stripe account 24h after the game, then Stripe pays it out to your bank.';

  @override
  String get deleteCourtTitle => 'Remove court';

  @override
  String get deleteCourtConfirmation =>
      'Are you sure you want to remove this court from your list?';

  @override
  String get deleteCourt => 'Remove';

  @override
  String get playersPerSideLabel => 'Players per side';

  @override
  String get customOption => 'Custom';

  @override
  String get customPlayersPerSideHint => 'Enter number of players per side';

  @override
  String get totalPlayersLabel => 'players total';

  @override
  String get totalLabel => 'Total';

  @override
  String freeCancellationPolicy(Object hours) {
    return 'Free cancellation up to ${hours}h before the match';
  }

  @override
  String get addPlayerLabel => 'ADD';

  @override
  String get pickFromPlayersSubtitle => 'Pick from players who played with you';

  @override
  String get searchByNameHint => 'Search by name';

  @override
  String get noPlayersAvailable => 'No players available to add';

  @override
  String get noResults => 'No results';

  @override
  String dontForgetToPay(Object name, Object amount) {
    return 'Don\'t forget to pay $name $amount!';
  }

  @override
  String get androidInstallBannerMessage =>
      'Install the Nutmeg app for a better experience.';

  @override
  String get androidInstallBannerDownload => 'Download';

  @override
  String get androidInstallBannerLater => 'Later';
}
