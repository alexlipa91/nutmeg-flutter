// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get topHeader => 'Encontre jogos de futebol perto de';

  @override
  String get upcoming => 'Próximas';

  @override
  String get going => 'Vou';

  @override
  String get past => 'Fui';

  @override
  String get myMatches => 'Organizadas por mim';

  @override
  String spotsLeft(int numSpots) {
    return '$numSpots vagas restantes';
  }

  @override
  String get thisWeek => 'ESSA SEMANA';

  @override
  String get nextWeek => 'PRÓXIMA SEMANA';

  @override
  String get moreThanTwoWeeks => 'EM MAIS DE DUAS SEMANAS';

  @override
  String get notPublishedStatus => 'Não publicado';

  @override
  String get cancelledStatus => 'Cancelado';

  @override
  String get fullStatus => 'Cheio';

  @override
  String get votes => 'votos';

  @override
  String get matchDetailsScreen =>
      '*****************************************************************************************************';

  @override
  String cancellationInfo(String date, String hour, int n) {
    return 'A partida será cancelada automaticamente às $date às $hour se menos de $n jogadores tiverem entrado.';
  }

  @override
  String get fullRefund => 'um reembolso total';

  @override
  String get refundWithoutFee =>
      'um reembolso (excluindo a taxa de serviço da Nutmeg)';

  @override
  String get paymentPolicyHeader => 'Política de Pagamento';

  @override
  String refundInfo(String info) {
    return 'Se você sair da partida, receberá $info.\nSe a partida for cancelada, você receberá um reembolso integral.\nSe você não comparecer, não receberá reembolso.';
  }

  @override
  String get organizedBy => 'Organizado por';

  @override
  String get editAction => 'Editar';

  @override
  String get shareAction => 'Compartilhar';

  @override
  String get linkCopiedToClipboard =>
      'Link copiado para a área de transferência';

  @override
  String get shareMatchStats => 'Compartilhe estatísticas da partida';

  @override
  String get shareMatchStatsText =>
      'Confira as estatísticas da minha última partida com Nutmeg! ⚽️ 🔥';

  @override
  String get cancelMatchAction => 'Cancelar partida';

  @override
  String get joinAction => 'Participar';

  @override
  String get player => 'Jogador';

  @override
  String get showMore => 'MOSTRAR MAIS';

  @override
  String get showLess => 'MOSTRAR MENOS';

  @override
  String get statsWaiting => 'Estatísticas disponíveis em breve';

  @override
  String get statsNotEnoughRatings =>
      'Não há avaliações suficientes para calcular as estatísticas';

  @override
  String statsAvailableAt(String date) {
    return 'As estatísticas desta partida estarão disponíveis\n$date';
  }

  @override
  String courtType(Object t) {
    return 'Tipo $t';
  }

  @override
  String get changingRooms => 'Vestiários disponíveis';

  @override
  String courtNumber(Object x) {
    return 'Número do campo / quadra $x';
  }

  @override
  String get artificialGrass => 'Grama';

  @override
  String get matchOnStatus => 'Confirmado';

  @override
  String get inProgressStatus => 'Em andamento';

  @override
  String waitingForPlayersStatus(Object x) {
    return 'Esperando por mais $x jogadores';
  }

  @override
  String get locationHeader => 'Localização';

  @override
  String listOfPlayersHeader(int x, int y) {
    return 'Jogadores ($x/$y)';
  }

  @override
  String get joinMatchSuccessTitle => 'Você está dentro!';

  @override
  String joinMatchBarSubtitle(int x) {
    return '$x jogadores indo';
  }

  @override
  String get joinButtonText => 'PARTICIPE DA PARTIDA';

  @override
  String get leaveButtonText => 'DEIXE O JOGO';

  @override
  String get joinThisMatchTitle => 'Participar da partida';

  @override
  String get joinMatchInfo =>
      'Se você sair da partida, você receberá um reembolso';

  @override
  String get leaveThisMatchTitle => 'Sair desta partida?';

  @override
  String get removePlayerTitle => 'Remover jogador?';

  @override
  String removePlayerSubtitle(String name) {
    return 'Isto irá remover $name do jogo.';
  }

  @override
  String get removePlayerRefundInfo =>
      'Se o jogador pagou, será emitido um reembolso.';

  @override
  String get leaveMatchRefundTitle => 'Reembolso';

  @override
  String get leaveMatchCreditsRefundTitle => 'Reembolso de Créditos';

  @override
  String get leaveMatchInfo =>
      'Nós reembolsaremos você no método de pagamento que você utilizou.';

  @override
  String leaveMatchServiceFeeInfo(String f) {
    return 'A taxa de serviço de $f não será reembolsada';
  }

  @override
  String get leaveMatchNoMoneyInfo =>
      'Por favor confirme se você deseja ser removido da lista de jogadores';

  @override
  String get paymentFailedTitle => 'Falha no pagamento!';

  @override
  String get paymentFailedSubtitle => 'Por favor, tente novamente';

  @override
  String get manageButton => 'GERENCIAR';

  @override
  String get cancelMatchTitle =>
      'Tem certeza de que deseja cancelar a partida?';

  @override
  String get cancelMatchSubtitle =>
      'Os jogadores que se inscreveram receberão um reembolso total.';

  @override
  String get serviceFee => 'Taxa de serviço';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get continueToPayment => 'CONTINUAR PARA O PAGAMENTO';

  @override
  String get joinedMatchText => 'Você entrou na partida.';

  @override
  String continueWithButton(String p) {
    return 'CONTINUAR COM $p';
  }

  @override
  String get noMatchesHere => 'Nenhuma partida aqui';

  @override
  String get browseOrCreateText =>
      'Navegue pelas partidas ou crie a sua própria partida';

  @override
  String get createNewMatchActionText => 'CRIAR NOVA PARTIDA';

  @override
  String get newMatchTitle => 'Nova partida';

  @override
  String get editMatchTitle => 'Editar partida';

  @override
  String get crudMatchGeneralTitle => 'Em geral';

  @override
  String get dateInputLabel => 'Data';

  @override
  String get startTimeInputLabel => 'Hora de início';

  @override
  String get endTimeInputLabel => 'Fim dos tempos';

  @override
  String get repeatInputLabel => 'Repita';

  @override
  String get requiredError => 'Obrigatório';

  @override
  String get doesNotRepeatLabel => 'Não se repete';

  @override
  String repeatForWeeks(int n) {
    return 'Semanalmente por $n semanas';
  }

  @override
  String lastMatchOn(String d) {
    return 'Última partida em $d';
  }

  @override
  String get courtSectionTitle => 'Campo / Quadra';

  @override
  String get locationSectionTitle => 'Localização';

  @override
  String get courtNumberLabel => 'Número do campo / quadra (opcional)';

  @override
  String get numberOfPlayersSectionTitle => 'Número de jogadores';

  @override
  String get numberOfPlayersInfo =>
      'Esta é a quantidade mínima e máxima de jogadores que podem participar da partida.';

  @override
  String get paymentSectionTitle => 'Pagamento';

  @override
  String get paymentEnableInfo =>
      'Permitir que os usuários paguem pela partida através da Nutmeg';

  @override
  String get paymentNotPossibleInfo =>
      'Ainda não podemos processar pagamentos neste local';

  @override
  String get invalidAmountError => 'Quantidade inválida';

  @override
  String get minimumAmountError => 'O valor mínimo é € 0,50';

  @override
  String get pricePerPlayerLabel => 'Preço por jogador';

  @override
  String nutmegFeeInfo(String a) {
    return 'A Nutmeg reterá uma taxa de serviço de $a por jogador';
  }

  @override
  String get youWillGetLabel => 'Você vai conseguir';

  @override
  String get usersWillPayLabel => 'Os usuários pagarão';

  @override
  String get usersWillPayText => '(incluindo taxa de Nutmeg)';

  @override
  String get paymentExplanationText =>
      'A Nutmeg libera o dinheiro 24 horas após a partida. Você receberá o pagamento em 3 a 5 dias úteis após isso.';

  @override
  String get policiesSectionTitle => 'Políticas';

  @override
  String get privateMatchInfo =>
      'A partida é privada. Os usuários podem entrar na partida apenas por meio do link compartilhado';

  @override
  String get privateMatchDesc => 'Partida privada';

  @override
  String get automaticCancellationInfo =>
      'Cancelar automaticamente a partida se o número mínimo de jogadores não for atingido';

  @override
  String automaticCancellationExplanation(int x, String y) {
    return 'Cancelaremos a partida se pelo menos $x jogadores não tiverem entrado $y horas antes do início da partida.\nSe os jogadores tiverem pago através da Nutmeg, receberão o reembolso integral.';
  }

  @override
  String teamNameLabelText(String x) {
    return 'EQUIPE $x';
  }

  @override
  String get hoursLabel => 'Horas';

  @override
  String get youWantToLeaveTitle => 'Tem certeza de que quer sair?';

  @override
  String get youWantToLeaveSubtitle =>
      'Se você sair, todas as alterações não salvas serão perdidas.';

  @override
  String get leftMatchTitle => 'Você saiu da partida';

  @override
  String get finalScoreSubmitText => 'Qual foi o placar final?';

  @override
  String get submitScoreButton => 'ENVIAR PONTUAÇÃO';

  @override
  String get editScoreButton => 'EDITAR PONTUAÇÃO';

  @override
  String get cancelScoreButton => 'CANCELAR';

  @override
  String get skipText => 'PULAR';

  @override
  String get nextText => 'PRÓXIMO';

  @override
  String get yes => 'Sim';

  @override
  String get cancel => 'Cancelar';

  @override
  String get createButtonText => 'CRIAR';

  @override
  String get confirmButtonText => 'CONFIRMAR';

  @override
  String get popularCourtsTitle => 'Campos / quadras Populares';

  @override
  String get yourCourtsTitle => 'Seus campos / quadras';

  @override
  String get matchStatsTitle => 'Jogadores de melhor desempenho';

  @override
  String matchStatsSubTitle(int n) {
    return '$n eleitores';
  }

  @override
  String get createNewCourtText => 'Criar novo campo / quadra';

  @override
  String get courtInfoText => 'Informações do campo / quadra';

  @override
  String get courtLocationLabel => 'Localização';

  @override
  String get courtTypeTitleText => 'Tipo';

  @override
  String get surfaceLabelText => 'Superfície';

  @override
  String get indoorTitle => 'Quadra';

  @override
  String get indoorDesc => 'Botas sem tachas';

  @override
  String get grassTitle => 'Grama';

  @override
  String get grassDesc => 'Para botas que exigem tachas';

  @override
  String get sizeTitle => 'Tamanho';

  @override
  String get facilitiesTitle => 'Instalações';

  @override
  String get changeRoomsAvailableLabel => 'Vestiários disponíveis';

  @override
  String get searchLocationTitle => 'Procurar localização';

  @override
  String get searchLocationInputFieldLabel => 'Procurar';

  @override
  String get currentLocationLabel => 'USAR MINHA LOCALIZAÇÃO';

  @override
  String get currentLocationInfo =>
      'Sua localização nos ajuda a melhorar sua experiência com recomendações aproximadas de partidas.';

  @override
  String get manualSplitTeamCheckBoxLabel => 'Divisão manual';

  @override
  String get teamStrenghtLabel => 'Força da equipe';

  @override
  String get manualSplitTeamInfo =>
      'Por padrão, dividimos as equipes de forma justa com base no desempenho dos jogadores e na força geral da equipe. Você pode dividir as equipes manualmente.';

  @override
  String get doneButtonText => 'FEITO';

  @override
  String get modifyButtonText => 'MODIFICAR';

  @override
  String get genericErrorMessage => 'Algo deu errado';

  @override
  String get genericErrorDesc => 'Entre em contato conosco para obter suporte.';

  @override
  String get ratePlayersTitle => 'Avalie os jogadores';

  @override
  String get ratePlayersButtonText => 'AVALIE OS JOGADORES';

  @override
  String get updateRatesPlayersButtonText => 'ALTERAR VOTOS';

  @override
  String get submitRatesButtonText => 'ENVIAR';

  @override
  String get accountTitle => 'Perfil';

  @override
  String get performanceTitle => 'DESEMPENHO';

  @override
  String get creditsBoxTitle => 'Créditos';

  @override
  String get numMatchesShortTitle => 'Partidas';

  @override
  String get numMatchesTitle => 'Partidas';

  @override
  String get numPlayersOfTheMatchBoxTitle => 'POTM';

  @override
  String get numMatchesDrawBoxTitle => 'Empates';

  @override
  String get numMatchesWonBoxTitle => 'Vitórias';

  @override
  String get numMatchesLostBoxTitle => 'Derrotas';

  @override
  String get averageScoreBoxTitle => 'Pontuação média';

  @override
  String get organiserSectionTitle => 'ORGANIZADOR';

  @override
  String get goToStripeDashboardText => 'IR PARA O MEU PAINEL STRIPE';

  @override
  String get organizedMatchesBoxTitle => 'Partidas Organizadas';

  @override
  String get followOnIg => 'Siga-nos no Instagram';

  @override
  String get feedback => 'Dê-nos um feedback';

  @override
  String payoutInfoSuccessText(String a, String d) {
    return 'O pagamento de $a foi transferido em $d';
  }

  @override
  String payoutInfoOnItsWayText(String a, String d) {
    return 'O pagamento de $a está a caminho e deve chegar em $d';
  }

  @override
  String get changeLanguageButton => 'ALTERAR IDIOMA';

  @override
  String get languageModalTitle => 'Linguagem';

  @override
  String get preMatchNotificationTitle => 'Pronto para a partida? u\"⚽️';

  @override
  String preMatchNotificationBody(String d, Object s) {
    return 'Sua partida de hoje é às $d às $s. Toque aqui para conferir seu time!';
  }

  @override
  String get leaderboardNoData => 'Nenhum dado disponível';

  @override
  String get matchAwardsTitle => 'Prêmios de Partida';

  @override
  String get matchAwardsSubtitle =>
      'Vote nas atuações mais destacadas da partida';

  @override
  String get selectPlayerText => 'Selecione o jogador';

  @override
  String get bestGoalAwardName => 'Melhor Gol';

  @override
  String get bestGoalAwardDesc => 'O gol mais impressionante da partida';

  @override
  String get bestStrikerAwardName => 'Melhor Atacante';

  @override
  String get bestStrikerAwardDesc => 'Jogador de ataque mais impactante';

  @override
  String get bestGoalkeeperAwardName => 'Melhor Goleiro';

  @override
  String get bestGoalkeeperAwardDesc =>
      'Defesas e jogadas defensivas mais cruciais';

  @override
  String get bestDefenderAwardName => 'Melhor Defensor';

  @override
  String get bestDefenderAwardDesc => 'Desempenho defensivo mais sólido';

  @override
  String get ratePlayersThanksText => 'Obrigado pela avaliação!';

  @override
  String get ratePlayersTitleText => 'Avalie os jogadores';

  @override
  String get updateRatesPlayersTitleText => 'Alterar votos';

  @override
  String ratesCloseInText(Object hours) {
    return 'As avaliações fecham em $hours horas';
  }

  @override
  String get locationErrorTitle => 'Falha ao obter a localização!';

  @override
  String get locationErrorDescription => 'Tente novamente mais tarde.';

  @override
  String get setPaymentInfo => 'Definir info de pagamento';

  @override
  String get showPlayersPaymentInfo =>
      'Mostrar aos jogadores info para pagamento';

  @override
  String get paymentInfoHeader => 'Info de pagamento';

  @override
  String get yourPaymentInfo => 'Suas info de pagamento';

  @override
  String get noPaymentInfoYet => 'Nenhuma info de pagamento definida';

  @override
  String get addPaymentInfo => 'ADICIONAR INFO DE PAGAMENTO';

  @override
  String get paymentInfoPlayersHint =>
      'Os jogadores que entrarem verão estas info para saber como te pagar';

  @override
  String get paymentInfoShownToPlayers =>
      'Isto será mostrado aos jogadores que entrarem nas suas partidas';

  @override
  String get paymentInfoPlaceholder => 'ex. Revolut @username, IBAN PT123...';

  @override
  String get paymentInfoProfileDesc =>
      'Adicione os seus dados de pagamento (ex. Revolut, IBAN) para que os jogadores saibam como te pagar';

  @override
  String get save => 'Salvar';

  @override
  String sharedPaymentDetails(String name) {
    return '$name compartilhou estas info de pagamento:';
  }

  @override
  String get markedAsPaid => 'Você marcou como pago';

  @override
  String get undo => 'Desfazer';

  @override
  String get iPaid => 'Marcar como pago';

  @override
  String get notYet => 'Ainda não';

  @override
  String get payOutsideNutmeg => 'Pagar fora do Nutmeg';

  @override
  String get payThroughNutmeg => 'Pagar pelo Nutmeg';

  @override
  String get paid => 'Pago';

  @override
  String get comingSoon => 'EM BREVE';

  @override
  String get payOutsideNutmegTitle => 'Pagar fora do Nutmeg';

  @override
  String get payWithNutmegTitle => 'Pagar com Nutmeg';

  @override
  String get stripeIntegrationActive => 'Integração Stripe ativa';

  @override
  String get payWithNutmegNotConfigured =>
      'Não configurado. Toque para saber mais.';

  @override
  String get howPayWithNutmegWorks => 'Como funciona Pagar com Nutmeg';

  @override
  String get stripeStep1 =>
      'Crie uma conta Stripe Connected com os seus dados bancários.';

  @override
  String get stripeStep2 =>
      'Crie um jogo com um preço (ex. 5 €). Os jogadores pagam via Stripe para participar.';

  @override
  String get stripeStep3 =>
      'Após o jogo, o Nutmeg transfere os pagamentos menos uma taxa de 0,50 € por jogador para a sua conta Stripe. Ex. 10 jogadores pagam 5 €, recebe 45 €.';

  @override
  String get stripeStep4 =>
      'O Stripe envia o dinheiro para o seu banco em poucos dias.';

  @override
  String get stripeInfoRefund =>
      'Os jogadores podem cancelar e obter reembolso total até 24h antes do jogo.';

  @override
  String get stripeInfoFee =>
      'A taxa do Nutmeg ajuda a cobrir os custos de transação do Stripe.';

  @override
  String get setupStripeIntegration => 'CONFIGURAR INTEGRAÇÃO STRIPE';

  @override
  String get stripeSetupInProgress =>
      'Configuração em curso. Toque para continuar.';

  @override
  String get stripeVerifying => 'A verificar a sua conta Stripe…';

  @override
  String get stripeVerified =>
      'Tudo pronto! A sua integração Stripe está ativa.';

  @override
  String get stripeVerificationPending =>
      'A sua conta está configurada mas a verificação ainda está em curso. Poderá receber pagamentos quando o Stripe concluir a revisão.';

  @override
  String get stripeSetupRequired =>
      'Precisa de configurar o Stripe antes de criar um jogo pago. Complete a configuração primeiro.';

  @override
  String get stripeNutmegFeeLabel => 'Taxa Nutmeg';

  @override
  String get stripePayoutExplanation =>
      'O dinheiro é transferido para a sua conta Stripe 24h após o jogo, e depois o Stripe envia para o seu banco.';

  @override
  String get deleteCourtTitle => 'Remover campo';

  @override
  String get deleteCourtConfirmation =>
      'Tem certeza que deseja remover este campo da sua lista?';

  @override
  String get deleteCourt => 'Remover';

  @override
  String get playersPerSideLabel => 'Jogadores por equipa';

  @override
  String get customOption => 'Personalizado';

  @override
  String get customPlayersPerSideHint =>
      'Insira o número de jogadores por equipa';

  @override
  String get totalPlayersLabel => 'jogadores no total';
}
