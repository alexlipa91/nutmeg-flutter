// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get topHeader => 'Encuentra partidos de fútbol cerca';

  @override
  String get upcoming => 'Próximamente';

  @override
  String get going => 'Assistiendo';

  @override
  String get past => 'Pasados';

  @override
  String get myMatches => 'Mis partidos';

  @override
  String spotsLeft(int numSpots) {
    return '$numSpots lugares restantes';
  }

  @override
  String get thisWeek => 'ESTA SEMANA';

  @override
  String get nextWeek => 'LA PRÓXIMA SEMANA';

  @override
  String get moreThanTwoWeeks => 'EN MÁS DE DOS SEMANAS';

  @override
  String get cancelledStatus => 'Cancelado';

  @override
  String get fullStatus => 'Lleno';

  @override
  String get votes => 'votos';

  @override
  String get matchDetailsScreen =>
      '*****************************************************************************************************';

  @override
  String cancellationInfo(String date, String hour, int n) {
    return 'El partido se cancelará automáticamente el $date a las $hour si se han unido menos de $n jugadores.';
  }

  @override
  String get paymentPolicyHeader => 'Política de pago';

  @override
  String get organizedBy => 'Organizado por';

  @override
  String get editAction => 'Editar';

  @override
  String get shareAction => 'Compartir';

  @override
  String get linkCopiedToClipboard => 'Enlace copiado al portapapeles';

  @override
  String get shareMatchStats => 'Compartir estadísticas de partidos';

  @override
  String get shareMatchStatsText =>
      '¡Mira las estadísticas de mi último partido con Nutmeg! ⚽️ 🔥';

  @override
  String get cancelMatchAction => 'Cancelar partido';

  @override
  String get joinAction => 'Unirse';

  @override
  String get player => 'Jugador';

  @override
  String get showMore => 'MOSTRAR MÁS';

  @override
  String get showLess => 'MOSTRAR MENOS';

  @override
  String get statsWaiting => 'Estadísticas disponibles próximamente';

  @override
  String get statsNotEnoughRatings =>
      'No hay suficientes valoraciones para calcular las estadísticas';

  @override
  String get statsNotEnoughRatingsTitle => 'No se calcularon las puntuaciones';

  @override
  String get statsNotEnoughRatingsSubtitle =>
      'Esta partida no recibió suficientes valoraciones de todos los jugadores para calcular las puntuaciones finales.';

  @override
  String get statsRatingsUnavailableSubtitle =>
      'No se pudieron finalizar las valoraciones de esta partida. Vuelve a intentarlo más tarde o contacta con soporte si continúa.';

  @override
  String get statsRatingsUnavailableTitle => 'Estadísticas no disponibles';

  @override
  String statsAvailableAt(String date) {
    return 'Las estadísticas de este partido estarán disponibles\n$date';
  }

  @override
  String courtType(Object t) {
    return '$t Tipo de tribunal';
  }

  @override
  String get changingRooms => 'Vestuarios disponibles';

  @override
  String courtNumber(Object x) {
    return 'Juzgado número $x';
  }

  @override
  String get artificialGrass => 'Césped';

  @override
  String get matchOnStatus => 'El partido está en marcha';

  @override
  String get matchSavedStatus => 'Partido guardado';

  @override
  String get inProgressStatus => 'En curso';

  @override
  String waitingForPlayersStatus(Object x) {
    return 'Esperando a $x jugadores más';
  }

  @override
  String get locationHeader => 'Ubicación';

  @override
  String listOfPlayersHeader(int x, int y) {
    return 'Jugadores ($x/$y)';
  }

  @override
  String get joinMatchSuccessTitle => '¡Estas dentro!';

  @override
  String joinMatchBarSubtitle(int x) {
    return '$x jugadores yendo';
  }

  @override
  String get joinButtonText => 'ÚNETE AL PARTIDO';

  @override
  String get leaveButtonText => 'SALIR DEL PARTIDO';

  @override
  String get joinThisMatchTitle => 'Únete a este partido';

  @override
  String get joinMatchInfo => 'Si abandonas el partido recibirás un reembolso';

  @override
  String get leaveThisMatchTitle => '¿Abandonar este partido?';

  @override
  String get removePlayerTitle => '¿Quitar jugador?';

  @override
  String removePlayerSubtitle(String name) {
    return 'Esto quitará a $name del partido.';
  }

  @override
  String get removePlayerRefundInfo =>
      'Si el jugador pagó, se emitirá un reembolso.';

  @override
  String removePlayerRefundMessage(String name) {
    return '$name será reembolsado en el método de pago que utilizó.';
  }

  @override
  String get leaveMatchRefundTitle => 'Reembolso';

  @override
  String get leaveMatchCreditsRefundTitle => 'Reembolso de créditos';

  @override
  String get leaveMatchInfo =>
      'Le reembolsaremos el importe a través del método de pago que utilizó para pagar.';

  @override
  String leaveMatchServiceFeeInfo(String f) {
    return 'La tarifa de servicio de <x>\$0.50<x> no será reembolsada';
  }

  @override
  String get leaveMatchNoMoneyInfo =>
      'Por favor, confirma si deseas ser eliminado de la lista de jugadores.';

  @override
  String get paymentFailedTitle => '¡Pago fallido!';

  @override
  String get paymentFailedSubtitle => 'Por favor, inténtalo de nuevo';

  @override
  String get manageButton => 'ADMINISTRAR';

  @override
  String get cancelMatchTitle =>
      '¿Estás seguro que deseas cancelar el partido?';

  @override
  String get cancelMatchSubtitle =>
      'Si los jugadores pagaron con Nutmeg, recibirán un reembolso completo.';

  @override
  String get serviceFee => 'Tarifa de servicio';

  @override
  String get subtotal => 'Total parcial';

  @override
  String get continueToPayment => 'CONTINUAR CON EL PAGO';

  @override
  String get joinedMatchText => 'Te has unido al partido.';

  @override
  String continueWithButton(String p) {
    return 'CONTINUAR CON $p';
  }

  @override
  String get noMatchesHere => 'No hay coincidencias aquí';

  @override
  String get browseOrCreateText =>
      'Explora coincidencias o crea la tuya propia';

  @override
  String get createNewMatchActionText => 'CREAR NUEVA PARTIDA';

  @override
  String get newMatchTitle => 'Nuevo partido';

  @override
  String get editMatchTitle => 'Editar partido';

  @override
  String get crudMatchGeneralTitle => 'General';

  @override
  String get dateInputLabel => 'Fecha';

  @override
  String get startTimeInputLabel => 'Hora de inicio';

  @override
  String get endTimeInputLabel => 'Fin de los tiempos';

  @override
  String get repeatInputLabel => 'Repetir';

  @override
  String get requiredError => 'Requerido';

  @override
  String get doesNotRepeatLabel => 'No se repite';

  @override
  String repeatForWeeks(int n) {
    return 'Semanalmente durante $n semanas';
  }

  @override
  String lastMatchOn(String d) {
    return 'Último partido el 22/10/2022';
  }

  @override
  String get courtSectionTitle => 'Corte';

  @override
  String get locationSectionTitle => 'Ubicación';

  @override
  String get courtNumberLabel => 'Número de tribunal (opcional)';

  @override
  String get numberOfPlayersSectionTitle => 'Número de jugadores';

  @override
  String get numberOfPlayersInfo =>
      'Esta es la cantidad mínima y máxima de jugadores que pueden unirse al partido.';

  @override
  String get paymentSectionTitle => 'Pago';

  @override
  String get paymentEnableInfo =>
      'Permitir a los usuarios pagar el partido a través de Nutmeg';

  @override
  String get paymentNotPossibleInfo =>
      'Todavía no podemos procesar pagos en esta ubicación.';

  @override
  String get invalidAmountError => 'Cantidad no válida';

  @override
  String get minimumAmountError => 'El importe mínimo es de 0,50€';

  @override
  String get pricePerPlayerLabel => 'Precio por jugador';

  @override
  String nutmegFeeInfo(String a) {
    return 'Nutmeg retendrá una tarifa de servicio de $a por jugador';
  }

  @override
  String get youWillGetLabel => 'Usted recibirá';

  @override
  String get usersWillPayLabel => 'Los usuarios pagarán';

  @override
  String get usersWillPayText => '(incluida la tarifa de nuez moscada)';

  @override
  String get paymentExplanationText =>
      'Nutmeg libera el dinero 24 horas después del partido. Recibirás el pago entre 3 y 5 días hábiles después de eso a través de';

  @override
  String get policiesSectionTitle => 'Políticas';

  @override
  String get privateMatchInfo =>
      'La partida es privada. Los usuarios solo pueden unirse a través del enlace compartido.';

  @override
  String get privateMatchDesc => 'Partida privada';

  @override
  String get automaticCancellationInfo =>
      'Cancelar automáticamente el partido si no se alcanza el número mínimo de jugadores';

  @override
  String automaticCancellationExplanation(int x, String y) {
    return 'Cancelaremos el partido si al menos $x jugadores no se han unido $y horas antes del inicio.\nSi los jugadores pagaron a través de Nutmeg, recibirán un reembolso completo.';
  }

  @override
  String teamNameLabelText(String x) {
    return 'EQUIPO $x';
  }

  @override
  String get hoursLabel => 'Horas';

  @override
  String get youWantToLeaveTitle => '¿Estás seguro que deseas salir?';

  @override
  String get youWantToLeaveSubtitle =>
      'Si sale, se perderán todos los cambios que no haya guardado.';

  @override
  String get leftMatchTitle => 'Abandonaste el partido';

  @override
  String get leftMatchContactOrganizerForRefund =>
      'Contacta al organizador para cualquier reembolso';

  @override
  String get finalScoreSubmitText => '¿Cuál fue el resultado final?';

  @override
  String get submitScoreButton => 'ENVIAR PUNTUACIÓN';

  @override
  String get editScoreButton => 'EDITAR PUNTUACIÓN';

  @override
  String get cancelScoreButton => 'CANCELAR';

  @override
  String get skipText => 'SALTAR';

  @override
  String get nextText => 'PRÓXIMO';

  @override
  String get yes => 'Sí';

  @override
  String get cancel => 'Cancelar';

  @override
  String get createButtonText => 'CREAR';

  @override
  String get confirmButtonText => 'CONFIRMAR';

  @override
  String get popularCourtsTitle => 'Tribunales populares';

  @override
  String get yourCourtsTitle => 'Tus Tribunales';

  @override
  String get courtsTitle => 'Tribunales';

  @override
  String get matchStatsTitle => 'Jugadores de alto rendimiento';

  @override
  String matchStatsSubTitle(int n) {
    return '$n votantes';
  }

  @override
  String get createNewCourtText => 'Crear un nuevo Tribunal';

  @override
  String get pictureTitleText => 'Imagen';

  @override
  String get informationTitleText => 'Información';

  @override
  String get typeTitleText => 'Tipo';

  @override
  String get courtInfoText => 'Información de la corte';

  @override
  String get courtLocationLabel => 'Ubicación de la corte';

  @override
  String get courtTypeTitleText => 'Tipo de corte';

  @override
  String get surfaceLabelText => 'Superficie';

  @override
  String imageTooSmallError(int minWidth, int minHeight) {
    return 'Imagen demasiado pequeña. Usa al menos ${minWidth}x${minHeight}px.';
  }

  @override
  String get invalidImageRatioError =>
      'Relación de imagen no válida. Usa una imagen cercana a 2:1 (por ejemplo 1200x600).';

  @override
  String get indoorTitle => 'Interior';

  @override
  String get indoorDesc => 'Botas sin tacos';

  @override
  String get grassTitle => 'Césped';

  @override
  String get grassDesc => 'Para botas que requieren tacos';

  @override
  String get sizeTitle => 'Tamaño';

  @override
  String get facilitiesTitle => 'Instalaciones';

  @override
  String get changeRoomsAvailableLabel => 'Vestuarios disponibles';

  @override
  String get searchLocationTitle => 'Buscar ubicación';

  @override
  String get searchLocationInputFieldLabel => 'Buscar';

  @override
  String get currentLocationLabel => 'UBICACIÓN ACTUAL';

  @override
  String get currentLocationInfo =>
      'Tu ubicación nos ayuda a mejorar tu experiencia con recomendaciones aproximadas de coincidencias.';

  @override
  String get manualSplitTeamCheckBoxLabel => 'División manual';

  @override
  String get teamStrenghtLabel => 'Fuerza del equipo';

  @override
  String get manualSplitTeamInfo =>
      'Por defecto, dividimos los equipos equitativamente según el rendimiento de los jugadores y la fuerza general del equipo. Puedes dividir los equipos manualmente.';

  @override
  String get doneButtonText => 'HECHO';

  @override
  String get modifyButtonText => 'MODIFICAR';

  @override
  String get genericErrorMessage => 'Algo salió mal';

  @override
  String get genericErrorDesc =>
      'Por favor póngase en contacto con nosotros para obtener ayuda.';

  @override
  String get ratePlayersTitle => 'Califica a los jugadores';

  @override
  String get ratePlayersButtonText => 'CALIFICAR A LOS JUGADORES';

  @override
  String get updateRatesPlayersButtonText => 'CAMBIAR VOTOS';

  @override
  String get submitRatesButtonText => 'ENTREGAR';

  @override
  String get accountTitle => 'Cuenta';

  @override
  String get performanceTitle => 'ACTUACIÓN';

  @override
  String get creditsBoxTitle => 'Créditos';

  @override
  String get numMatchesShortTitle => 'Partidos';

  @override
  String get numMatchesTitle => 'Partidos';

  @override
  String get numPlayersOfTheMatchBoxTitle => 'POTM';

  @override
  String get numMatchesDrawBoxTitle => 'Empates';

  @override
  String get numMatchesWonBoxTitle => 'Victorias';

  @override
  String get numMatchesLostBoxTitle => 'Derrotas';

  @override
  String get averageScoreBoxTitle => 'Puntuación media';

  @override
  String get organiserSectionTitle => 'ORGANIZADOR';

  @override
  String get goToStripeDashboardText => 'IR A MI PANEL DE CONTROL DE STRIPE';

  @override
  String get organizedMatchesBoxTitle => 'Partidos organizados';

  @override
  String get playedInYourGamesBoxTitle => 'Jugaron en tus partidos';

  @override
  String get playedWithYouBoxTitle => 'Jugaron contigo';

  @override
  String get followOnIg => 'Síguenos en Instagram';

  @override
  String get feedback => 'Envíanos tus comentarios';

  @override
  String collectedAmountText(String amount, String count, String total) {
    return '$amount recaudados ($count/$total pagaron)';
  }

  @override
  String releaseScheduledText(String date) {
    return 'Se transferirá a tu cuenta Stripe el $date';
  }

  @override
  String releaseCompletedText(String amount) {
    return '$amount transferidos a tu cuenta Stripe';
  }

  @override
  String get nutmegPayCollectedSoFarSubtitle =>
      'Este es el dinero recaudado hasta ahora de los jugadores.';

  @override
  String get changeLanguageButton => 'CAMBIAR IDIOMA';

  @override
  String get languageModalTitle => 'Idioma';

  @override
  String get preMatchNotificationTitle => '¿Listos para el partido? u\"⚽️';

  @override
  String preMatchNotificationBody(String d, Object s) {
    return 'Tu partido de hoy es a las $d a las $s. ¡Toca aquí para ver tu equipo!';
  }

  @override
  String get leaderboardNoData => 'No hay datos disponibles';

  @override
  String get matchAwardsTitle => 'Premios del partido';

  @override
  String get matchAwardsSubtitle =>
      'Vota por las actuaciones destacadas del partido';

  @override
  String get selectPlayerText => 'Seleccionar jugador';

  @override
  String get bestGoalAwardName => 'Mejor gol';

  @override
  String get bestGoalAwardDesc => 'El gol más impresionante del partido';

  @override
  String get bestStrikerAwardName => 'Mejor delantero';

  @override
  String get bestStrikerAwardDesc => 'El jugador de ataque más impactante';

  @override
  String get bestGoalkeeperAwardName => 'Mejor portero';

  @override
  String get bestGoalkeeperAwardDesc =>
      'Las paradas y jugadas defensivas más cruciales';

  @override
  String get bestDefenderAwardName => 'Mejor defensor';

  @override
  String get bestDefenderAwardDesc => 'La actuación defensiva más sólida';

  @override
  String get ratePlayersThanksText => '¡Gracias por calificar!';

  @override
  String get ratePlayersTitleText => 'Califica a los jugadores';

  @override
  String get updateRatesPlayersTitleText => 'Cambiar votos';

  @override
  String ratesCloseInText(Object hours) {
    return 'Las calificaciones cierran en $hours horas';
  }

  @override
  String get locationErrorTitle => '¡No se pudo obtener la ubicación!';

  @override
  String get locationErrorDescription =>
      'Por favor, inténtelo de nuevo más tarde.';

  @override
  String get setPaymentInfo => 'Configurar info de pago';

  @override
  String get showPlayersPaymentInfo =>
      'Mostrar a los jugadores info para el pago';

  @override
  String get paymentInfoHeader => 'Info de pago';

  @override
  String get yourPaymentInfo => 'Tu info de pago';

  @override
  String get noPaymentInfoYet => 'No hay info de pago configurada';

  @override
  String get addPaymentInfo => 'AGREGAR INFO DE PAGO';

  @override
  String get paymentInfoPlayersHint =>
      'Los jugadores que se unan verán esta info para saber cómo pagarte';

  @override
  String get paymentInfoShownToPlayers =>
      'Esto se mostrará a los jugadores que se unan a tus partidos';

  @override
  String get paymentInfoPlaceholder => 'ej. Revolut @username, IBAN ES123...';

  @override
  String get paymentInfoProfileDesc =>
      'Agrega tus datos de pago (ej. Revolut, IBAN) para que los jugadores sepan cómo pagarte';

  @override
  String get save => 'Guardar';

  @override
  String sharedPaymentDetails(String name) {
    return '$name compartió esta info de pago:';
  }

  @override
  String get markedAsPaid => 'Marcaste como pagado';

  @override
  String get manualPaymentDisclaimer =>
      'El estado del pago es declarado por los jugadores';

  @override
  String get undo => 'Deshacer';

  @override
  String get iPaid => 'Marcar como pagado';

  @override
  String get notYet => 'Aún no';

  @override
  String get payOutsideNutmeg => 'Pago Manual';

  @override
  String get payThroughNutmeg => 'Nutmeg Pay';

  @override
  String get payWithStripe => 'PAGAR CON STRIPE';

  @override
  String get paid => 'Pagado';

  @override
  String get comingSoon => 'PRÓXIMAMENTE';

  @override
  String get payOutsideNutmegTitle => 'Pagar fuera de Nutmeg';

  @override
  String get payWithNutmegTitle => 'Pagar con Nutmeg';

  @override
  String get stripeIntegrationActive => 'Ver cómo funciona';

  @override
  String get goToStripeDashboardButton => 'IR A TU PANEL DE STRIPE';

  @override
  String get payWithNutmegNotConfigured =>
      'Configuración necesaria. Toca para configurar.';

  @override
  String get howPayWithNutmegWorks => 'Cómo funciona Pagar con Nutmeg';

  @override
  String get stripeStep1 =>
      'Crea una cuenta Stripe Connected con tus datos bancarios.';

  @override
  String get stripeStep2 =>
      'Crea un partido con un precio (ej. 5 €). Los jugadores pagan por Stripe para unirse.';

  @override
  String get stripeStep3 =>
      'Después del partido, Nutmeg transfiere los pagos menos una comisión de 0,50 € por jugador a tu cuenta Stripe. Ej. 10 jugadores pagan 5 €, recibes 45 €.';

  @override
  String get stripeStep4 => 'Stripe envía el dinero a tu banco en pocos días.';

  @override
  String get stripeInfoRefund =>
      'Los jugadores pueden cancelar y obtener un reembolso completo hasta 24h antes del partido.';

  @override
  String get stripeInfoFee =>
      'La comisión de Nutmeg ayuda a cubrir los costes de transacción de Stripe.';

  @override
  String get setupStripeIntegration => 'CONFIGURAR INTEGRACIÓN CON STRIPE';

  @override
  String get stripeSetupInProgress =>
      'Configuración en curso. Toca para continuar.';

  @override
  String get stripeVerifying => 'Verificando tu cuenta de Stripe…';

  @override
  String get stripeVerified =>
      '¡Todo listo! Tu integración con Stripe está activa.';

  @override
  String get stripeVerificationPending =>
      'La configuración de Stripe no está completa. Toca \'Paga con Nutmeg\' arriba para terminarla y empezar a recibir pagos.';

  @override
  String get stripeSetupRequired =>
      'Necesitas configurar Stripe antes de crear un partido de pago. Completa la configuración primero.';

  @override
  String get stripeNutmegFeeLabel => 'Comisión Nutmeg';

  @override
  String get stripePayoutExplanation =>
      'El dinero se transfiere a tu cuenta Stripe 24h después del partido y luego Stripe lo envía a tu banco.';

  @override
  String get deleteCourtTitle => 'Eliminar cancha';

  @override
  String get deleteCourtConfirmation =>
      '¿Estás seguro de que quieres eliminar esta cancha de tu lista?';

  @override
  String get deleteCourt => 'Eliminar';

  @override
  String get playersPerSideLabel => 'Jugadores por equipo';

  @override
  String get customOption => 'Personalizado';

  @override
  String get customPlayersPerSideHint =>
      'Introduce el número de jugadores por equipo';

  @override
  String get totalPlayersLabel => 'jugadores en total';

  @override
  String get totalLabel => 'Total';

  @override
  String freeCancellationPolicy(Object hours) {
    return 'Cancelación gratuita hasta ${hours}h antes del partido';
  }

  @override
  String get addPlayerLabel => 'AÑADIR';

  @override
  String get addGuestLabel => 'Añadir invitado';

  @override
  String get addGuestTitle => 'Añadir jugador invitado';

  @override
  String get addGuestSubtitle =>
      'Introduce el nombre visible del jugador invitado';

  @override
  String get guestNameHint => 'Nombre del invitado';

  @override
  String get pickFromPlayersSubtitle =>
      'Elige entre los jugadores con los que has jugado';

  @override
  String get searchByNameHint => 'Buscar por nombre';

  @override
  String get noPlayersAvailable => 'No hay jugadores disponibles para añadir';

  @override
  String get noResults => 'Sin resultados';

  @override
  String dontForgetToPay(Object name, Object amount) {
    return '¡No te olvides de pagar a $name $amount!';
  }

  @override
  String get androidInstallBannerMessage =>
      'Instala la app de Nutmeg para disfrutar de una mejor experiencia.';

  @override
  String get androidInstallBannerDownload => 'Descargar';

  @override
  String get androidInstallBannerLater => 'Más tarde';
}
