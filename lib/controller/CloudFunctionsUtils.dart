import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';


class CloudFunctionsUtils {

  static FirebaseFunctions _client = FirebaseFunctions.instanceFor(region: "europe-central2");

  static Future<Map<String, dynamic>> callFunction
      (String name, Map<String, dynamic> data) async {
    HttpsCallable callable = _client.httpsCallable('add_user_to_match');
    var resp = await callable(data);
    return json.decode(resp.data);
  }
}
