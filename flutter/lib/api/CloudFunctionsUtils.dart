import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:nutmeg/controller/LaunchController.dart';
import 'package:nutmeg/utils/CrashlyticsLogger.dart';

final logger = CrashlyticsLogger('CloudFunctionsUtils');

class CloudFunctionsClient {
  static final CloudFunctionsClient _singleton =
      CloudFunctionsClient._internal();
  static const appEngineBaseUrl = String.fromEnvironment("BACKEND_URL",
      defaultValue: "https://nutmeg-9099c.ew.r.appspot.com");

  factory CloudFunctionsClient() {
    return _singleton;
  }

  CloudFunctionsClient._internal() {
    logger.info("Backend URL: $appEngineBaseUrl");
  }

  Future<Map<String, String>> _headers() async {
    String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Bearer ' + token,
      if (LaunchController.appVersion != null)
        'App-Version': LaunchController.appVersion ?? "n/a"
    };
  }

  Future<Map<String, dynamic>?> post(
      String name, Map<String, dynamic> data) async {
    logger.info("POST AppEngine $name with data ${data.toString()}");

    // var trace = FirebasePerformance.instance.newTrace("api-call");
    // trace.start();
    // trace.putAttribute("path_name", name);
    // trace.putAttribute("source", "app_engine");
    // trace.putAttribute("path_wildcard_name", _getPathWildcardName(name));
    // trace.putAttribute("method", "post");
    // final Stopwatch stopwatch = Stopwatch();

    var r = await http.post(
      Uri.parse("$appEngineBaseUrl/$name"),
      headers: await _headers(),
      body: jsonEncode(data),
    );

    // trace.setMetric("duration_ms", stopwatch.elapsed.inMilliseconds);
    // trace.stop();

    if (r.statusCode == 500) {
      logger.severe("Server error (500) on POST $name: ${r.body}");
      throw Exception(r.body);
    }

    var responseBody = r.body;
    try {
      return jsonDecode(responseBody)["data"];
    } catch (e) {
      var message = "Failed to decode response body: $responseBody";
      logger.severe(message, e);
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>?> get(String name,
      {Map<String, dynamic> args = const {}}) async {
    logger.info("GET $name with args ${args.toString()}");

    // var trace = FirebasePerformance.instance.newTrace("api-call");
    // await trace.start();
    // trace.putAttribute("path_name", name);
    // trace.putAttribute("path_wildcard_name", _getPathWildcardName(name));
    // trace.putAttribute("method", "get");
    // trace.putAttribute("source", "app_engine");

    // final Stopwatch stopwatch = Stopwatch();
    // stopwatch.start();

    var argsString = args.entries.map((e) => "${e.key}=${e.value}").join("&");
    var url = "$appEngineBaseUrl/$name";
    if (argsString.isNotEmpty) url = "$url?$argsString";

    var r = await http.get(Uri.parse(url), headers: await _headers());
    if (r.statusCode == 500) {
      logger.severe("Server error (500) on GET $name: ${r.body}");
      throw Exception(r.body);
    }

    return jsonDecode(r.body)["data"];
  }

  String getUrl(String path) => "$appEngineBaseUrl/$path";
}
