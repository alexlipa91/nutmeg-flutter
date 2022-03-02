import 'package:cloud_functions/cloud_functions.dart';


class CloudFunctionsClient {
  static final CloudFunctionsClient _singleton = CloudFunctionsClient._internal();

  FirebaseFunctions _client = FirebaseFunctions.instanceFor(region: "europe-central2");

  factory CloudFunctionsClient() {
    return _singleton;
  }

  CloudFunctionsClient._internal();

  Future<Map<String, dynamic>> callFunction(String name, Map<String, dynamic> data) async {
    HttpsCallable callable = _client.httpsCallable(name);
    var resp = await callable(data);
    return resp.data;
  }
}
