import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/utils/Utils.dart';

var apiKey = (isTestPaymentMode) ?
  "pk_test_51HyCDAGRb87bTNwH1dlHJXwdDSIUhxqPZS3zeytnO7T9dHBxzhwiWO5E0kFYLkVdZbZ2t0LEHxjuPmKFZ32fiMjO00dWLo1DqE" :
"pk_live_51HyCDAGRb87bTNwHHFjJ2aRfC6SlNbAaaxOrdaPZ136H3gVdP3BYP9xW4rS0CZnImV5MrlqZWjjJ18smw7zJBhQH00mZP1Fqtm";


enum Status {
  success,
  paymentCanceled,
  paymentFailed,
  paymentSuccessButJoinFailed
}

class PaymentOutcome {
  final Status status;
  final PaymentRecap recap;

  PaymentOutcome(this.status, this.recap);
}
