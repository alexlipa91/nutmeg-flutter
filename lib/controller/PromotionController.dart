import 'package:nutmeg/db/MiscFirestore.dart';


class PromotionController {

  static Future<int> giveFreeCreditsAtLogin() async {
    var data = await MiscFirestore.getDocument("promotion_free_credits_at_login");
    return (data == null) ? 0 : data["numCredits"];
  }
}
