// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get topHeader => 'Trova partite di calcio vicino';

  @override
  String get upcoming => 'Future';

  @override
  String get going => 'Iscritto';

  @override
  String get past => 'Passate';

  @override
  String get myMatches => 'Le mie partite';

  @override
  String spotsLeft(int numSpots) {
    return '$numSpots posti rimasti';
  }

  @override
  String get thisWeek => 'QUESTA SETTIMANA';

  @override
  String get nextWeek => 'LA PROSSIMA SETTIMANA';

  @override
  String get moreThanTwoWeeks => 'IN PIÙ DI DUE SETTIMANE';

  @override
  String get notPublishedStatus => 'In attesa: non abbastanza giocatori';

  @override
  String get cancelledStatus => 'Annullato';

  @override
  String get fullStatus => 'Pieno';

  @override
  String get votes => 'voti';

  @override
  String get matchDetailsScreen =>
      '*****************************************************************************************************';

  @override
  String cancellationInfo(String date, String hour, int n) {
    return 'La partita verrà automaticamente annullata il $date alle $hour se si saranno uniti meno di $n giocatori.';
  }

  @override
  String get paymentPolicyHeader => 'Regole';

  @override
  String get organizedBy => 'Organizzato da';

  @override
  String get editAction => 'Modificare';

  @override
  String get shareAction => 'Condividi';

  @override
  String get linkCopiedToClipboard => 'Link copiato negli appunti';

  @override
  String get shareMatchStats => 'Condividi le statistiche della partita';

  @override
  String get shareMatchStatsText =>
      'Dai un\'occhiata alle statistiche della mia ultima partita con Nutmeg! ⚽️ 🔥';

  @override
  String get cancelMatchAction => 'Annulla partita';

  @override
  String get joinAction => 'Unisciti';

  @override
  String get player => 'Giocatore';

  @override
  String get showMore => 'MOSTRA DI PIÙ';

  @override
  String get showLess => 'MOSTRA MENO';

  @override
  String get statsWaiting => 'Statistiche disponibili a breve';

  @override
  String get statsNotEnoughRatings =>
      'Non ci sono abbastanza valutazioni per calcolare le statistiche';

  @override
  String statsAvailableAt(String date) {
    return 'Le statistiche per questa partita saranno disponibili\n$date';
  }

  @override
  String courtType(Object t) {
    return 'Tipo di campo: $t';
  }

  @override
  String get changingRooms => 'Spogliatoi disponibili';

  @override
  String courtNumber(Object x) {
    return 'Campo numero $x';
  }

  @override
  String get artificialGrass => 'Erba';

  @override
  String get matchOnStatus => 'Partita confermata';

  @override
  String get matchSavedStatus => 'Partita salvata';

  @override
  String get inProgressStatus => 'In corso';

  @override
  String waitingForPlayersStatus(Object x) {
    return 'In attesa di altri $x giocatori';
  }

  @override
  String get locationHeader => 'Luogo';

  @override
  String listOfPlayersHeader(int x, int y) {
    return 'Giocatori ($x/$y)';
  }

  @override
  String get joinMatchSuccessTitle => 'Sei dentro!';

  @override
  String joinMatchBarSubtitle(int x) {
    return '$x giocatori nella partita';
  }

  @override
  String get joinButtonText => 'UNISCITI ALLA PARTITA';

  @override
  String get leaveButtonText => 'LASCIA LA PARTITA';

  @override
  String get joinThisMatchTitle => 'Unisciti a questa partita';

  @override
  String get joinMatchInfo => 'Se abbandoni la partita riceverai un rimborso';

  @override
  String get leaveThisMatchTitle => 'Vuoi abbandonare questa partita?';

  @override
  String get removePlayerTitle => 'Rimuovere il giocatore?';

  @override
  String removePlayerSubtitle(String name) {
    return 'Questo rimuoverà $name dalla partita.';
  }

  @override
  String get removePlayerRefundInfo =>
      'Se il giocatore ha pagato, verrà emesso un rimborso.';

  @override
  String removePlayerRefundMessage(String name) {
    return '$name verrà rimborsato sul metodo di pagamento utilizzato.';
  }

  @override
  String get leaveMatchRefundTitle => 'Rimborso';

  @override
  String get leaveMatchCreditsRefundTitle => 'Rimborso crediti';

  @override
  String get leaveMatchInfo =>
      'Ti rimborseremo tramite lo stesso metodo di pagamento utilizzato per il pagamento.';

  @override
  String leaveMatchServiceFeeInfo(String f) {
    return 'La commissione di servizio di <x>\$0.50<x> non verrà rimborsata';
  }

  @override
  String get leaveMatchNoMoneyInfo =>
      'Per favore conferma se vuoi essere rimosso dall\'elenco dei giocatori';

  @override
  String get paymentFailedTitle => 'Pagamento non riuscito!';

  @override
  String get paymentFailedSubtitle => 'Per favore riprova';

  @override
  String get manageButton => 'GESTISCI';

  @override
  String get cancelMatchTitle => 'Sei sicuro di voler annullare la partita?';

  @override
  String get cancelMatchSubtitle =>
      'Se i giocatori hanno pagato con Nutmeg, riceveranno un rimborso completo.';

  @override
  String get serviceFee => 'Commissione di servizio';

  @override
  String get subtotal => 'Subtotale';

  @override
  String get continueToPayment => 'CONTINUA CON IL PAGAMENTO';

  @override
  String get joinedMatchText => 'Ti sei unito alla partita.';

  @override
  String continueWithButton(String p) {
    return 'CONTINUA CON $p';
  }

  @override
  String get noMatchesHere => 'Nessuna partita';

  @override
  String get browseOrCreateText =>
      'Cerca altre partite o organizza una tua partita';

  @override
  String get createNewMatchActionText => 'CREA NUOVA PARTITA';

  @override
  String get newMatchTitle => 'Nuova partita';

  @override
  String get editMatchTitle => 'Modifica partita';

  @override
  String get crudMatchGeneralTitle => 'Generale';

  @override
  String get dateInputLabel => 'Data';

  @override
  String get startTimeInputLabel => 'Dalle ore';

  @override
  String get endTimeInputLabel => 'Alle ore';

  @override
  String get repeatInputLabel => 'Ripetere';

  @override
  String get requiredError => 'Obbligatorio';

  @override
  String get doesNotRepeatLabel => 'Non si ripete';

  @override
  String repeatForWeeks(int n) {
    return 'Settimanale per $n settimane';
  }

  @override
  String lastMatchOn(String d) {
    return 'Ultima partita il $d';
  }

  @override
  String get courtSectionTitle => 'Campo';

  @override
  String get locationSectionTitle => 'Posizione';

  @override
  String get courtNumberLabel => 'Numero del campo (facoltativo)';

  @override
  String get numberOfPlayersSectionTitle => 'Numero di giocatori';

  @override
  String get numberOfPlayersInfo =>
      'Questo è il numero minimo e massimo di giocatori che possono partecipare alla partita.';

  @override
  String get paymentSectionTitle => 'Pagamento';

  @override
  String get paymentEnableInfo =>
      'Consentire agli utenti di pagare la partita tramite Nutmeg';

  @override
  String get paymentNotPossibleInfo =>
      'Non possiamo ancora elaborare i pagamenti in questa sede';

  @override
  String get invalidAmountError => 'Importo non valido';

  @override
  String get minimumAmountError => 'L\'importo minimo è di € 0,50';

  @override
  String get pricePerPlayerLabel => 'Prezzo per giocatore';

  @override
  String nutmegFeeInfo(String a) {
    return 'Nutmeg tratterrà una commissione di servizio di $a per giocatore';
  }

  @override
  String get youWillGetLabel => 'Riceverai';

  @override
  String get usersWillPayLabel => 'Gli utenti pagheranno';

  @override
  String get usersWillPayText => '(inclusa Nutmeg fee)';

  @override
  String get paymentExplanationText =>
      'Nutmeg rilascia il denaro 24 ore dopo la partita. Riceverai il pagamento entro 3-5 giorni lavorativi tramite';

  @override
  String get policiesSectionTitle => 'Cancellazione';

  @override
  String get privateMatchInfo =>
      'La partita è privata. Gli utenti possono partecipare solo tramite il link condiviso.';

  @override
  String get privateMatchDesc => 'Partita privata';

  @override
  String get automaticCancellationInfo =>
      'Annulla automaticamente la partita se non viene raggiunto il numero minimo di giocatori';

  @override
  String automaticCancellationExplanation(int x, String y) {
    return 'Annulleremo la partita se almeno $x giocatori non si saranno uniti $y ore prima del calcio d\'inizio.\nSe i giocatori hanno pagato tramite Nutmeg, riceveranno un rimborso completo.';
  }

  @override
  String teamNameLabelText(String x) {
    return 'SQUADRA $x';
  }

  @override
  String get hoursLabel => 'Ore';

  @override
  String get youWantToLeaveTitle => 'Sei sicuro di voler uscire?';

  @override
  String get youWantToLeaveSubtitle =>
      'Se esci, tutte le modifiche non salvate andranno perse.';

  @override
  String get leftMatchTitle => 'Hai abbandonato la partita';

  @override
  String get leftMatchContactOrganizerForRefund =>
      'Contatta l\'organizzatore per eventuali rimborsi';

  @override
  String get finalScoreSubmitText => 'Qual è stato il punteggio finale?';

  @override
  String get submitScoreButton => 'INVIA PUNTEGGIO';

  @override
  String get editScoreButton => 'MODIFICA PARTITURA';

  @override
  String get cancelScoreButton => 'CANCELLARE';

  @override
  String get skipText => 'SALTARE';

  @override
  String get nextText => 'PROSSIMO';

  @override
  String get yes => 'SÌ';

  @override
  String get cancel => 'Cancellare';

  @override
  String get createButtonText => 'CREA PARTITA';

  @override
  String get confirmButtonText => 'CONFERMARE';

  @override
  String get popularCourtsTitle => 'Campi popolari';

  @override
  String get yourCourtsTitle => 'I tuoi campi';

  @override
  String get matchStatsTitle => 'Giocatori più performanti';

  @override
  String matchStatsSubTitle(int n) {
    return '$n elettori';
  }

  @override
  String get createNewCourtText => 'Crea nuovo campo';

  @override
  String get courtInfoText => 'Informazioni sul campo';

  @override
  String get courtLocationLabel => 'Posizione del campo';

  @override
  String get courtTypeTitleText => 'Tipo di campo';

  @override
  String get surfaceLabelText => 'Superficie';

  @override
  String get indoorTitle => 'Indoor';

  @override
  String get indoorDesc => 'Scarpette senza tacchetti';

  @override
  String get grassTitle => 'Erbetta';

  @override
  String get grassDesc => 'Scarpette con tacchetti';

  @override
  String get sizeTitle => 'Misura Campo';

  @override
  String get facilitiesTitle => 'Strutture';

  @override
  String get changeRoomsAvailableLabel => 'Spogliatoi disponibili';

  @override
  String get searchLocationTitle => 'Cerca posizione';

  @override
  String get searchLocationInputFieldLabel => 'Ricerca';

  @override
  String get currentLocationLabel => 'POSIZIONE ATTUALE';

  @override
  String get currentLocationInfo =>
      'La tua posizione ci aiuta a migliorare la tua esperienza con consigli migliori sulle partite.';

  @override
  String get manualSplitTeamCheckBoxLabel => 'Manuale';

  @override
  String get teamStrenghtLabel => 'Forza della squadra';

  @override
  String get manualSplitTeamInfo =>
      'Di default, dividiamo le squadre equamente in base alle prestazioni dei giocatori e alla forza complessiva della squadra. Puoi dividere le squadre manualmente.';

  @override
  String get doneButtonText => 'FATTO';

  @override
  String get modifyButtonText => 'MODIFICARE';

  @override
  String get genericErrorMessage => 'Qualcosa è andato storto';

  @override
  String get genericErrorDesc => 'Contattaci per ricevere supporto.';

  @override
  String get ratePlayersTitle => 'Valuta i giocatori';

  @override
  String get ratePlayersButtonText => 'VALUTA I GIOCATORI';

  @override
  String get updateRatesPlayersButtonText => 'CAMBIA I VOTI';

  @override
  String get submitRatesButtonText => 'INVIA';

  @override
  String get accountTitle => 'Account';

  @override
  String get performanceTitle => 'PRESTAZIONE';

  @override
  String get creditsBoxTitle => 'Crediti';

  @override
  String get numMatchesShortTitle => 'Partite';

  @override
  String get numMatchesTitle => 'Partite';

  @override
  String get numPlayersOfTheMatchBoxTitle => 'POTM';

  @override
  String get numMatchesDrawBoxTitle => 'Pareggi';

  @override
  String get numMatchesWonBoxTitle => 'Vittorie';

  @override
  String get numMatchesLostBoxTitle => 'Sconfitte';

  @override
  String get averageScoreBoxTitle => 'Media Voto';

  @override
  String get organiserSectionTitle => 'ORGANIZZATORE';

  @override
  String get goToStripeDashboardText => 'VAI ALLA MIA DASHBOARD STRIPE';

  @override
  String get organizedMatchesBoxTitle => 'Partite organizzate';

  @override
  String get playedInYourGamesBoxTitle => 'Hanno giocato nelle tue partite';

  @override
  String get playedWithYouBoxTitle => 'Hanno giocato con te';

  @override
  String get followOnIg => 'Seguici su Instagram';

  @override
  String get feedback => 'Dacci un feedback';

  @override
  String payoutInfoSuccessText(String a, String d) {
    return 'Il pagamento di $a è stato trasferito il $d';
  }

  @override
  String payoutInfoOnItsWayText(String a, String d) {
    return 'Il pagamento di $a è in arrivo e dovrebbe arrivare il $d';
  }

  @override
  String get changeLanguageButton => 'CAMBIA LINGUA';

  @override
  String get languageModalTitle => 'Lingua';

  @override
  String get preMatchNotificationTitle => 'Pronti per la partita? u\"⚽️';

  @override
  String preMatchNotificationBody(String d, Object s) {
    return 'La tua partita di oggi è alle $d alle $s. Tocca qui per controllare la tua squadra!';
  }

  @override
  String get leaderboardNoData => 'Nessun dato disponibile';

  @override
  String get matchAwardsTitle => 'Premi di partita';

  @override
  String get matchAwardsSubtitle =>
      'Vota le prestazioni eccezionali della partita';

  @override
  String get selectPlayerText => 'Seleziona il giocatore';

  @override
  String get bestGoalAwardName => 'Miglior gol';

  @override
  String get bestGoalAwardDesc => 'Il gol più impressionante della partita';

  @override
  String get bestStrikerAwardName => 'Miglior attaccante';

  @override
  String get bestStrikerAwardDesc => 'Giocatore d\'attacco più impattante';

  @override
  String get bestGoalkeeperAwardName => 'Miglior portiere';

  @override
  String get bestGoalkeeperAwardDesc =>
      'Le parate più importanti e le azioni difensive più decisive';

  @override
  String get bestDefenderAwardName => 'Miglior difensore';

  @override
  String get bestDefenderAwardDesc => 'La prestazione difensiva più solida';

  @override
  String get ratePlayersThanksText => 'Grazie per la valutazione!';

  @override
  String get ratePlayersTitleText => 'Valuta i giocatori';

  @override
  String get updateRatesPlayersTitleText => 'Cambiare i voti';

  @override
  String ratesCloseInText(Object hours) {
    return 'Le valutazioni chiudono tra $hours ore';
  }

  @override
  String get locationErrorTitle => 'Impossibile ottenere la posizione!';

  @override
  String get locationErrorDescription => 'Riprova più tardi.';

  @override
  String get setPaymentInfo => 'Imposta info pagamento';

  @override
  String get showPlayersPaymentInfo =>
      'Mostra ai giocatori le info per il pagamento';

  @override
  String get paymentInfoHeader => 'Info pagamento';

  @override
  String get yourPaymentInfo => 'Le tue info di pagamento';

  @override
  String get noPaymentInfoYet => 'Nessuna info di pagamento impostata';

  @override
  String get addPaymentInfo => 'AGGIUNGI INFO PAGAMENTO';

  @override
  String get paymentInfoPlayersHint =>
      'I giocatori che si uniscono vedranno queste info per sapere come pagarti';

  @override
  String get paymentInfoShownToPlayers =>
      'Queste info saranno visibili ai giocatori che si uniscono alle tue partite';

  @override
  String get paymentInfoPlaceholder => 'es. Revolut @username, IBAN IT123...';

  @override
  String get paymentInfoProfileDesc =>
      'Aggiungi i tuoi dati di pagamento (es. Revolut, IBAN) per far sapere ai giocatori come pagarti';

  @override
  String get save => 'Salva';

  @override
  String sharedPaymentDetails(String name) {
    return '$name ha condiviso queste info di pagamento:';
  }

  @override
  String get markedAsPaid => 'Pagato';

  @override
  String get undo => 'Annulla';

  @override
  String get iPaid => 'Pagato';

  @override
  String get notYet => 'Non pagato';

  @override
  String get payOutsideNutmeg => 'Paga fuori da Nutmeg';

  @override
  String get payThroughNutmeg => 'Paga tramite Nutmeg';

  @override
  String get paid => 'Pagato';

  @override
  String get comingSoon => 'IN ARRIVO';

  @override
  String get payOutsideNutmegTitle => 'Paga fuori da Nutmeg';

  @override
  String get payWithNutmegTitle => 'Paga con Nutmeg';

  @override
  String get stripeIntegrationActive => 'Integrazione Stripe attiva';

  @override
  String get payWithNutmegNotConfigured =>
      'Configurazione necessaria. Tocca per configurare.';

  @override
  String get howPayWithNutmegWorks => 'Come funziona Paga con Nutmeg';

  @override
  String get stripeStep1 =>
      'Crea un account Stripe Connected con i tuoi dati bancari.';

  @override
  String get stripeStep2 =>
      'Crea una partita con un prezzo (es. 5 €). I giocatori pagano tramite Stripe per partecipare.';

  @override
  String get stripeStep3 =>
      'Dopo la partita, Nutmeg trasferisce i pagamenti meno una commissione di 0,50 € per giocatore sul tuo account Stripe. Es. 10 giocatori pagano 5 €, ricevi 45 €.';

  @override
  String get stripeStep4 =>
      'Stripe invia il denaro alla tua banca entro pochi giorni.';

  @override
  String get stripeInfoRefund =>
      'I giocatori possono cancellare e ottenere un rimborso completo fino a 24h prima della partita.';

  @override
  String get stripeInfoFee =>
      'La commissione Nutmeg aiuta a coprire i costi di transazione di Stripe.';

  @override
  String get setupStripeIntegration => 'CONFIGURA INTEGRAZIONE STRIPE';

  @override
  String get stripeSetupInProgress =>
      'Configurazione in corso. Tocca per continuare.';

  @override
  String get stripeVerifying => 'Verifica del tuo account Stripe in corso…';

  @override
  String get stripeVerified =>
      'Tutto a posto! La tua integrazione Stripe è attiva.';

  @override
  String get stripeVerificationPending =>
      'Il tuo account è configurato ma la verifica è ancora in corso. Potrai ricevere pagamenti quando Stripe completerà la revisione.';

  @override
  String get stripeSetupRequired =>
      'Devi configurare Stripe prima di creare una partita a pagamento. Completa la configurazione.';

  @override
  String get stripeNutmegFeeLabel => 'Commissione Nutmeg';

  @override
  String get stripePayoutExplanation =>
      'Il denaro viene trasferito sul tuo account Stripe 24h dopo la partita, poi Stripe lo invia al tuo conto bancario.';

  @override
  String get deleteCourtTitle => 'Rimuovi campo';

  @override
  String get deleteCourtConfirmation =>
      'Sei sicuro di voler rimuovere questo campo dalla tua lista?';

  @override
  String get deleteCourt => 'Rimuovi';

  @override
  String get playersPerSideLabel => 'Giocatori per squadra';

  @override
  String get customOption => 'Personalizzato';

  @override
  String get customPlayersPerSideHint =>
      'Inserisci il numero di giocatori per squadra';

  @override
  String get totalPlayersLabel => 'giocatori totali';

  @override
  String get totalLabel => 'Totale';

  @override
  String freeCancellationPolicy(Object hours) {
    return 'Cancellazione gratuita fino a ${hours}h prima della partita';
  }

  @override
  String get addPlayerLabel => 'AGGIUNGI';

  @override
  String get pickFromPlayersSubtitle =>
      'Scegli tra i giocatori con cui hai giocato';

  @override
  String get searchByNameHint => 'Cerca per nome';

  @override
  String get noPlayersAvailable => 'Nessun giocatore disponibile da aggiungere';

  @override
  String get noResults => 'Nessun risultato';

  @override
  String dontForgetToPay(Object name) {
    return 'Non dimenticare di pagare $name!';
  }
}
