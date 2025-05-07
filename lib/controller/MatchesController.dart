import 'package:nutmeg/api/CloudFunctionsUtils.dart';

class MatchesController {
  static var apiClient = CloudFunctionsClient();

  static Future<void> cancelMatch(String matchId) async {
    await apiClient.get("matches/$matchId/cancel");
  }
}
