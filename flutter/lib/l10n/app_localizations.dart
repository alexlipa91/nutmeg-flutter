import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('it'),
    Locale('pt')
  ];

  /// No description provided for @topHeader.
  ///
  /// In en, this message translates to:
  /// **'Find football matches near'**
  String get topHeader;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @going.
  ///
  /// In en, this message translates to:
  /// **'Going'**
  String get going;

  /// No description provided for @past.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get past;

  /// No description provided for @myMatches.
  ///
  /// In en, this message translates to:
  /// **'My Matches'**
  String get myMatches;

  /// No description provided for @spotsLeft.
  ///
  /// In en, this message translates to:
  /// **'{numSpots} spots left'**
  String spotsLeft(int numSpots);

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'THIS WEEK'**
  String get thisWeek;

  /// No description provided for @nextWeek.
  ///
  /// In en, this message translates to:
  /// **'NEXT WEEK'**
  String get nextWeek;

  /// No description provided for @moreThanTwoWeeks.
  ///
  /// In en, this message translates to:
  /// **'IN MORE THAN TWO WEEKS'**
  String get moreThanTwoWeeks;

  /// No description provided for @notPublishedStatus.
  ///
  /// In en, this message translates to:
  /// **'Not Published'**
  String get notPublishedStatus;

  /// No description provided for @cancelledStatus.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledStatus;

  /// No description provided for @fullStatus.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get fullStatus;

  /// No description provided for @votes.
  ///
  /// In en, this message translates to:
  /// **'votes'**
  String get votes;

  /// No description provided for @matchDetailsScreen.
  ///
  /// In en, this message translates to:
  /// **'*****************************************************************************************************'**
  String get matchDetailsScreen;

  /// No description provided for @cancellationInfo.
  ///
  /// In en, this message translates to:
  /// **'The match will be automatically canceled on {date} at {hour} if less than {n} players have joined.'**
  String cancellationInfo(String date, String hour, int n);

  /// No description provided for @fullRefund.
  ///
  /// In en, this message translates to:
  /// **'a full refund'**
  String get fullRefund;

  /// No description provided for @refundWithoutFee.
  ///
  /// In en, this message translates to:
  /// **'a refund (excluding Nutmeg service fee)'**
  String get refundWithoutFee;

  /// No description provided for @paymentPolicyHeader.
  ///
  /// In en, this message translates to:
  /// **'Payment Policy'**
  String get paymentPolicyHeader;

  /// No description provided for @refundInfo.
  ///
  /// In en, this message translates to:
  /// **'If you leave the match you will get {info}.\nIf the match is cancelled you will get a full refund.\nIf you don\'t show up you won\'t get a refund.'**
  String refundInfo(String info);

  /// No description provided for @organizedBy.
  ///
  /// In en, this message translates to:
  /// **'Organized By'**
  String get organizedBy;

  /// No description provided for @editAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editAction;

  /// No description provided for @shareAction.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareAction;

  /// No description provided for @linkCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get linkCopiedToClipboard;

  /// No description provided for @shareMatchStats.
  ///
  /// In en, this message translates to:
  /// **'Share Match Stats'**
  String get shareMatchStats;

  /// No description provided for @shareMatchStatsText.
  ///
  /// In en, this message translates to:
  /// **'Check out the stats of my last match with Nutmeg! ⚽️ 🔥'**
  String get shareMatchStatsText;

  /// No description provided for @cancelMatchAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel Match'**
  String get cancelMatchAction;

  /// No description provided for @joinAction.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinAction;

  /// No description provided for @player.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get player;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'SHOW MORE'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'SHOW LESS'**
  String get showLess;

  /// No description provided for @statsWaiting.
  ///
  /// In en, this message translates to:
  /// **'Stats available soon'**
  String get statsWaiting;

  /// No description provided for @statsNotEnoughRatings.
  ///
  /// In en, this message translates to:
  /// **'Not enough ratings to compute stats'**
  String get statsNotEnoughRatings;

  /// No description provided for @statsAvailableAt.
  ///
  /// In en, this message translates to:
  /// **'Statistics for this match will be available\n{date}'**
  String statsAvailableAt(String date);

  /// No description provided for @courtType.
  ///
  /// In en, this message translates to:
  /// **'{t} Court Type'**
  String courtType(Object t);

  /// No description provided for @changingRooms.
  ///
  /// In en, this message translates to:
  /// **'Changing rooms available'**
  String get changingRooms;

  /// No description provided for @courtNumber.
  ///
  /// In en, this message translates to:
  /// **'Court number {x}'**
  String courtNumber(Object x);

  /// No description provided for @artificialGrass.
  ///
  /// In en, this message translates to:
  /// **'Grass'**
  String get artificialGrass;

  /// No description provided for @matchOnStatus.
  ///
  /// In en, this message translates to:
  /// **'Match is on'**
  String get matchOnStatus;

  /// No description provided for @inProgressStatus.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgressStatus;

  /// No description provided for @waitingForPlayersStatus.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {x} more players'**
  String waitingForPlayersStatus(Object x);

  /// No description provided for @locationHeader.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationHeader;

  /// No description provided for @listOfPlayersHeader.
  ///
  /// In en, this message translates to:
  /// **'Players ({x}/{y})'**
  String listOfPlayersHeader(int x, int y);

  /// No description provided for @joinMatchSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'You are in!'**
  String get joinMatchSuccessTitle;

  /// No description provided for @joinMatchBarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{x} players going'**
  String joinMatchBarSubtitle(int x);

  /// No description provided for @joinButtonText.
  ///
  /// In en, this message translates to:
  /// **'JOIN MATCH'**
  String get joinButtonText;

  /// No description provided for @leaveButtonText.
  ///
  /// In en, this message translates to:
  /// **'LEAVE MATCH'**
  String get leaveButtonText;

  /// No description provided for @joinThisMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Join this match'**
  String get joinThisMatchTitle;

  /// No description provided for @joinMatchInfo.
  ///
  /// In en, this message translates to:
  /// **'If you leave the match you will get a refund'**
  String get joinMatchInfo;

  /// No description provided for @leaveThisMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave this match?'**
  String get leaveThisMatchTitle;

  /// No description provided for @removePlayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove player?'**
  String get removePlayerTitle;

  /// No description provided for @removePlayerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This will remove {name} from the match.'**
  String removePlayerSubtitle(String name);

  /// No description provided for @removePlayerRefundInfo.
  ///
  /// In en, this message translates to:
  /// **'If the player paid, a refund will be issued.'**
  String get removePlayerRefundInfo;

  /// No description provided for @leaveMatchRefundTitle.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get leaveMatchRefundTitle;

  /// No description provided for @leaveMatchCreditsRefundTitle.
  ///
  /// In en, this message translates to:
  /// **'Credits Refund'**
  String get leaveMatchCreditsRefundTitle;

  /// No description provided for @leaveMatchInfo.
  ///
  /// In en, this message translates to:
  /// **'We will refund you on the payment method you used to pay.'**
  String get leaveMatchInfo;

  /// No description provided for @leaveMatchServiceFeeInfo.
  ///
  /// In en, this message translates to:
  /// **'The service fee of {f} will not be refunded'**
  String leaveMatchServiceFeeInfo(String f);

  /// No description provided for @leaveMatchNoMoneyInfo.
  ///
  /// In en, this message translates to:
  /// **'Please confirm if you want to be removed from the players list'**
  String get leaveMatchNoMoneyInfo;

  /// No description provided for @paymentFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Failed!'**
  String get paymentFailedTitle;

  /// No description provided for @paymentFailedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please try again'**
  String get paymentFailedSubtitle;

  /// No description provided for @manageButton.
  ///
  /// In en, this message translates to:
  /// **'MANAGE'**
  String get manageButton;

  /// No description provided for @cancelMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel the match?'**
  String get cancelMatchTitle;

  /// No description provided for @cancelMatchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The players that joined will get a full refund.'**
  String get cancelMatchSubtitle;

  /// No description provided for @serviceFee.
  ///
  /// In en, this message translates to:
  /// **'Service Fee'**
  String get serviceFee;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @continueToPayment.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE TO PAYMENT'**
  String get continueToPayment;

  /// No description provided for @joinedMatchText.
  ///
  /// In en, this message translates to:
  /// **'You have joined the match.'**
  String get joinedMatchText;

  /// No description provided for @continueWithButton.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE WITH {p}'**
  String continueWithButton(String p);

  /// No description provided for @noMatchesHere.
  ///
  /// In en, this message translates to:
  /// **'No matches here'**
  String get noMatchesHere;

  /// No description provided for @browseOrCreateText.
  ///
  /// In en, this message translates to:
  /// **'Browse matches or create your own match'**
  String get browseOrCreateText;

  /// No description provided for @createNewMatchActionText.
  ///
  /// In en, this message translates to:
  /// **'CREATE NEW MATCH'**
  String get createNewMatchActionText;

  /// No description provided for @newMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'New Match'**
  String get newMatchTitle;

  /// No description provided for @editMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Match'**
  String get editMatchTitle;

  /// No description provided for @crudMatchGeneralTitle.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get crudMatchGeneralTitle;

  /// No description provided for @dateInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateInputLabel;

  /// No description provided for @startTimeInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTimeInputLabel;

  /// No description provided for @endTimeInputLabel.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTimeInputLabel;

  /// No description provided for @repeatInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeatInputLabel;

  /// No description provided for @requiredError.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredError;

  /// No description provided for @doesNotRepeatLabel.
  ///
  /// In en, this message translates to:
  /// **'Does not repeat'**
  String get doesNotRepeatLabel;

  /// No description provided for @repeatForWeeks.
  ///
  /// In en, this message translates to:
  /// **'Weekly for {n} weeks'**
  String repeatForWeeks(int n);

  /// No description provided for @lastMatchOn.
  ///
  /// In en, this message translates to:
  /// **'Last Match On {d}'**
  String lastMatchOn(String d);

  /// No description provided for @courtSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Court'**
  String get courtSectionTitle;

  /// No description provided for @locationSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationSectionTitle;

  /// No description provided for @courtNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Court number (optional)'**
  String get courtNumberLabel;

  /// No description provided for @numberOfPlayersSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Number of Players'**
  String get numberOfPlayersSectionTitle;

  /// No description provided for @numberOfPlayersInfo.
  ///
  /// In en, this message translates to:
  /// **'This is the minimum and maximum amount of player that can join the match.'**
  String get numberOfPlayersInfo;

  /// No description provided for @paymentSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentSectionTitle;

  /// No description provided for @paymentEnableInfo.
  ///
  /// In en, this message translates to:
  /// **'Allow users to pay for the match through Nutmeg'**
  String get paymentEnableInfo;

  /// No description provided for @paymentNotPossibleInfo.
  ///
  /// In en, this message translates to:
  /// **'We cannot process payments in this location yet'**
  String get paymentNotPossibleInfo;

  /// No description provided for @invalidAmountError.
  ///
  /// In en, this message translates to:
  /// **'Invalid Amount'**
  String get invalidAmountError;

  /// No description provided for @minimumAmountError.
  ///
  /// In en, this message translates to:
  /// **'Minimum amount is € 0.50'**
  String get minimumAmountError;

  /// No description provided for @pricePerPlayerLabel.
  ///
  /// In en, this message translates to:
  /// **'Price per Player'**
  String get pricePerPlayerLabel;

  /// No description provided for @nutmegFeeInfo.
  ///
  /// In en, this message translates to:
  /// **'Nutmeg will withhold a service fee of {a} per player'**
  String nutmegFeeInfo(String a);

  /// No description provided for @youWillGetLabel.
  ///
  /// In en, this message translates to:
  /// **'You will get'**
  String get youWillGetLabel;

  /// No description provided for @usersWillPayLabel.
  ///
  /// In en, this message translates to:
  /// **'Users will pay'**
  String get usersWillPayLabel;

  /// No description provided for @usersWillPayText.
  ///
  /// In en, this message translates to:
  /// **'(including Nutmeg fee)'**
  String get usersWillPayText;

  /// No description provided for @paymentExplanationText.
  ///
  /// In en, this message translates to:
  /// **'Nutmeg releases the money 24 hours after the match. You will get paid in 3 to 5 business days after that through'**
  String get paymentExplanationText;

  /// No description provided for @policiesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get policiesSectionTitle;

  /// No description provided for @privateMatchInfo.
  ///
  /// In en, this message translates to:
  /// **'Match is private. Users can join the match only through the shared link'**
  String get privateMatchInfo;

  /// No description provided for @privateMatchDesc.
  ///
  /// In en, this message translates to:
  /// **'Private match'**
  String get privateMatchDesc;

  /// No description provided for @automaticCancellationInfo.
  ///
  /// In en, this message translates to:
  /// **'Automatically cancel the match if minimum amount of players is not reached'**
  String get automaticCancellationInfo;

  /// No description provided for @automaticCancellationExplanation.
  ///
  /// In en, this message translates to:
  /// **'We will cancel the match if at least {x} players haven\'t joined {y} hours before the kick-off of the match.\nIf players have paid through Nutmeg, they will get a full refund'**
  String automaticCancellationExplanation(int x, String y);

  /// No description provided for @teamNameLabelText.
  ///
  /// In en, this message translates to:
  /// **'TEAM {x}'**
  String teamNameLabelText(String x);

  /// No description provided for @hoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hoursLabel;

  /// No description provided for @youWantToLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave?'**
  String get youWantToLeaveTitle;

  /// No description provided for @youWantToLeaveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'If you leave, all your unsaved changes will be lost.'**
  String get youWantToLeaveSubtitle;

  /// No description provided for @leftMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'You left the match'**
  String get leftMatchTitle;

  /// No description provided for @finalScoreSubmitText.
  ///
  /// In en, this message translates to:
  /// **'What was the final score?'**
  String get finalScoreSubmitText;

  /// No description provided for @submitScoreButton.
  ///
  /// In en, this message translates to:
  /// **'SUBMIT SCORE'**
  String get submitScoreButton;

  /// No description provided for @editScoreButton.
  ///
  /// In en, this message translates to:
  /// **'EDIT SCORE'**
  String get editScoreButton;

  /// No description provided for @cancelScoreButton.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancelScoreButton;

  /// No description provided for @skipText.
  ///
  /// In en, this message translates to:
  /// **'SKIP'**
  String get skipText;

  /// No description provided for @nextText.
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get nextText;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @createButtonText.
  ///
  /// In en, this message translates to:
  /// **'CREATE'**
  String get createButtonText;

  /// No description provided for @confirmButtonText.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM'**
  String get confirmButtonText;

  /// No description provided for @popularCourtsTitle.
  ///
  /// In en, this message translates to:
  /// **'Popular Courts'**
  String get popularCourtsTitle;

  /// No description provided for @yourCourtsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Courts'**
  String get yourCourtsTitle;

  /// No description provided for @matchStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Top Performing Players'**
  String get matchStatsTitle;

  /// No description provided for @matchStatsSubTitle.
  ///
  /// In en, this message translates to:
  /// **'{n} voters'**
  String matchStatsSubTitle(int n);

  /// No description provided for @createNewCourtText.
  ///
  /// In en, this message translates to:
  /// **'Create new Court'**
  String get createNewCourtText;

  /// No description provided for @courtInfoText.
  ///
  /// In en, this message translates to:
  /// **'Court Information'**
  String get courtInfoText;

  /// No description provided for @courtLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Court Location'**
  String get courtLocationLabel;

  /// No description provided for @courtTypeTitleText.
  ///
  /// In en, this message translates to:
  /// **'Court Type'**
  String get courtTypeTitleText;

  /// No description provided for @surfaceLabelText.
  ///
  /// In en, this message translates to:
  /// **'Surface'**
  String get surfaceLabelText;

  /// No description provided for @indoorTitle.
  ///
  /// In en, this message translates to:
  /// **'Indoor'**
  String get indoorTitle;

  /// No description provided for @indoorDesc.
  ///
  /// In en, this message translates to:
  /// **'Boots without studs'**
  String get indoorDesc;

  /// No description provided for @grassTitle.
  ///
  /// In en, this message translates to:
  /// **'Grass'**
  String get grassTitle;

  /// No description provided for @grassDesc.
  ///
  /// In en, this message translates to:
  /// **'For boots that require studs'**
  String get grassDesc;

  /// No description provided for @sizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get sizeTitle;

  /// No description provided for @facilitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Facilities'**
  String get facilitiesTitle;

  /// No description provided for @changeRoomsAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Change Rooms Available'**
  String get changeRoomsAvailableLabel;

  /// No description provided for @searchLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Location'**
  String get searchLocationTitle;

  /// No description provided for @searchLocationInputFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchLocationInputFieldLabel;

  /// No description provided for @currentLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'CURRENT LOCATION'**
  String get currentLocationLabel;

  /// No description provided for @currentLocationInfo.
  ///
  /// In en, this message translates to:
  /// **'Your location helps us improve your experience with approximate recommendations of matches.'**
  String get currentLocationInfo;

  /// No description provided for @manualSplitTeamCheckBoxLabel.
  ///
  /// In en, this message translates to:
  /// **'Manual split'**
  String get manualSplitTeamCheckBoxLabel;

  /// No description provided for @teamStrenghtLabel.
  ///
  /// In en, this message translates to:
  /// **'Team strength'**
  String get teamStrenghtLabel;

  /// No description provided for @manualSplitTeamInfo.
  ///
  /// In en, this message translates to:
  /// **'By default, we split the teams fairly based on players performance and overall team strength. You can manually split the teams yourself.'**
  String get manualSplitTeamInfo;

  /// No description provided for @doneButtonText.
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get doneButtonText;

  /// No description provided for @modifyButtonText.
  ///
  /// In en, this message translates to:
  /// **'MODIFY'**
  String get modifyButtonText;

  /// No description provided for @genericErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get genericErrorMessage;

  /// No description provided for @genericErrorDesc.
  ///
  /// In en, this message translates to:
  /// **'Please contact us for support.'**
  String get genericErrorDesc;

  /// No description provided for @ratePlayersTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate Players'**
  String get ratePlayersTitle;

  /// No description provided for @ratePlayersButtonText.
  ///
  /// In en, this message translates to:
  /// **'RATE PLAYERS'**
  String get ratePlayersButtonText;

  /// No description provided for @updateRatesPlayersButtonText.
  ///
  /// In en, this message translates to:
  /// **'CHANGE VOTES'**
  String get updateRatesPlayersButtonText;

  /// No description provided for @submitRatesButtonText.
  ///
  /// In en, this message translates to:
  /// **'SUBMIT'**
  String get submitRatesButtonText;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @performanceTitle.
  ///
  /// In en, this message translates to:
  /// **'PERFORMANCE'**
  String get performanceTitle;

  /// No description provided for @creditsBoxTitle.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get creditsBoxTitle;

  /// No description provided for @numMatchesShortTitle.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get numMatchesShortTitle;

  /// No description provided for @numMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get numMatchesTitle;

  /// No description provided for @numPlayersOfTheMatchBoxTitle.
  ///
  /// In en, this message translates to:
  /// **'POTM'**
  String get numPlayersOfTheMatchBoxTitle;

  /// No description provided for @numMatchesDrawBoxTitle.
  ///
  /// In en, this message translates to:
  /// **'Draws'**
  String get numMatchesDrawBoxTitle;

  /// No description provided for @numMatchesWonBoxTitle.
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get numMatchesWonBoxTitle;

  /// No description provided for @numMatchesLostBoxTitle.
  ///
  /// In en, this message translates to:
  /// **'Losses'**
  String get numMatchesLostBoxTitle;

  /// No description provided for @averageScoreBoxTitle.
  ///
  /// In en, this message translates to:
  /// **'Avg. Score'**
  String get averageScoreBoxTitle;

  /// No description provided for @organiserSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'ORGANISER'**
  String get organiserSectionTitle;

  /// No description provided for @goToStripeDashboardText.
  ///
  /// In en, this message translates to:
  /// **'GO TO MY STRIPE DASHBOARD'**
  String get goToStripeDashboardText;

  /// No description provided for @organizedMatchesBoxTitle.
  ///
  /// In en, this message translates to:
  /// **'Organized Matches'**
  String get organizedMatchesBoxTitle;

  /// No description provided for @followOnIg.
  ///
  /// In en, this message translates to:
  /// **'Follow us on Instagram'**
  String get followOnIg;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Give us feedback'**
  String get feedback;

  /// No description provided for @payoutInfoSuccessText.
  ///
  /// In en, this message translates to:
  /// **'Payment of {a} has been transferred on {d}'**
  String payoutInfoSuccessText(String a, String d);

  /// No description provided for @payoutInfoOnItsWayText.
  ///
  /// In en, this message translates to:
  /// **'Payment of {a} is on its way and should arrive on {d}'**
  String payoutInfoOnItsWayText(String a, String d);

  /// No description provided for @changeLanguageButton.
  ///
  /// In en, this message translates to:
  /// **'CHANGE LANGUAGE'**
  String get changeLanguageButton;

  /// No description provided for @languageModalTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageModalTitle;

  /// No description provided for @preMatchNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready for the match? u\"⚽️'**
  String get preMatchNotificationTitle;

  /// No description provided for @preMatchNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Your match today is at {d} at {s}. Tap here to check your team!'**
  String preMatchNotificationBody(String d, Object s);

  /// No description provided for @leaderboardNoData.
  ///
  /// In en, this message translates to:
  /// **'No available data'**
  String get leaderboardNoData;

  /// No description provided for @matchAwardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Match Awards'**
  String get matchAwardsTitle;

  /// No description provided for @matchAwardsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Vote for outstanding performances of the match'**
  String get matchAwardsSubtitle;

  /// No description provided for @selectPlayerText.
  ///
  /// In en, this message translates to:
  /// **'Select player'**
  String get selectPlayerText;

  /// No description provided for @bestGoalAwardName.
  ///
  /// In en, this message translates to:
  /// **'Best Goal'**
  String get bestGoalAwardName;

  /// No description provided for @bestGoalAwardDesc.
  ///
  /// In en, this message translates to:
  /// **'Most impressive goal of the match'**
  String get bestGoalAwardDesc;

  /// No description provided for @bestStrikerAwardName.
  ///
  /// In en, this message translates to:
  /// **'Best Striker'**
  String get bestStrikerAwardName;

  /// No description provided for @bestStrikerAwardDesc.
  ///
  /// In en, this message translates to:
  /// **'Most impactful attacking player'**
  String get bestStrikerAwardDesc;

  /// No description provided for @bestGoalkeeperAwardName.
  ///
  /// In en, this message translates to:
  /// **'Best Goalkeeper'**
  String get bestGoalkeeperAwardName;

  /// No description provided for @bestGoalkeeperAwardDesc.
  ///
  /// In en, this message translates to:
  /// **'Most crucial saves and defensive plays'**
  String get bestGoalkeeperAwardDesc;

  /// No description provided for @bestDefenderAwardName.
  ///
  /// In en, this message translates to:
  /// **'Best Defender'**
  String get bestDefenderAwardName;

  /// No description provided for @bestDefenderAwardDesc.
  ///
  /// In en, this message translates to:
  /// **'Most solid defensive performance'**
  String get bestDefenderAwardDesc;

  /// No description provided for @ratePlayersThanksText.
  ///
  /// In en, this message translates to:
  /// **'Thanks for rating!'**
  String get ratePlayersThanksText;

  /// No description provided for @ratePlayersTitleText.
  ///
  /// In en, this message translates to:
  /// **'Rate players'**
  String get ratePlayersTitleText;

  /// No description provided for @updateRatesPlayersTitleText.
  ///
  /// In en, this message translates to:
  /// **'Change votes'**
  String get updateRatesPlayersTitleText;

  /// No description provided for @ratesCloseInText.
  ///
  /// In en, this message translates to:
  /// **'Ratings close in {hours} hours'**
  String ratesCloseInText(Object hours);

  /// No description provided for @locationErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to get location!'**
  String get locationErrorTitle;

  /// No description provided for @locationErrorDescription.
  ///
  /// In en, this message translates to:
  /// **'Please try again later.'**
  String get locationErrorDescription;

  /// No description provided for @setPaymentInfo.
  ///
  /// In en, this message translates to:
  /// **'Set Payment Info'**
  String get setPaymentInfo;

  /// No description provided for @showPlayersPaymentInfo.
  ///
  /// In en, this message translates to:
  /// **'Show players info for payments'**
  String get showPlayersPaymentInfo;

  /// No description provided for @paymentInfoHeader.
  ///
  /// In en, this message translates to:
  /// **'Payment Info'**
  String get paymentInfoHeader;

  /// No description provided for @yourPaymentInfo.
  ///
  /// In en, this message translates to:
  /// **'Your payment info'**
  String get yourPaymentInfo;

  /// No description provided for @noPaymentInfoYet.
  ///
  /// In en, this message translates to:
  /// **'No payment info set yet'**
  String get noPaymentInfoYet;

  /// No description provided for @addPaymentInfo.
  ///
  /// In en, this message translates to:
  /// **'ADD PAYMENT INFO'**
  String get addPaymentInfo;

  /// No description provided for @paymentInfoPlayersHint.
  ///
  /// In en, this message translates to:
  /// **'Players who join will see this so they know how to pay you'**
  String get paymentInfoPlayersHint;

  /// No description provided for @paymentInfoShownToPlayers.
  ///
  /// In en, this message translates to:
  /// **'This will be shown to players who join your matches'**
  String get paymentInfoShownToPlayers;

  /// No description provided for @paymentInfoPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. Revolut @username, IBAN IT123...'**
  String get paymentInfoPlaceholder;

  /// No description provided for @paymentInfoProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Add your payment details (e.g. Revolut, IBAN) so players know how to pay you'**
  String get paymentInfoProfileDesc;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @sharedPaymentDetails.
  ///
  /// In en, this message translates to:
  /// **'{name} shared these payment details:'**
  String sharedPaymentDetails(String name);

  /// No description provided for @markedAsPaid.
  ///
  /// In en, this message translates to:
  /// **'You marked this as paid'**
  String get markedAsPaid;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @iPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as Paid'**
  String get iPaid;

  /// No description provided for @notYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get notYet;

  /// No description provided for @payOutsideNutmeg.
  ///
  /// In en, this message translates to:
  /// **'Pay outside Nutmeg'**
  String get payOutsideNutmeg;

  /// No description provided for @payThroughNutmeg.
  ///
  /// In en, this message translates to:
  /// **'Pay through Nutmeg'**
  String get payThroughNutmeg;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'COMING SOON'**
  String get comingSoon;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'it', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'it':
      return AppLocalizationsIt();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
