import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:nutmeg/config/app_config.dart';
import 'package:nutmeg/controller/LaunchController.dart';
import 'package:nutmeg/utils/CrashlyticsLogger.dart';

final logger = CrashlyticsLogger('CloudFunctionsUtils');

class ServerException implements Exception {
  final int statusCode;
  final String message;

  ServerException(this.statusCode, this.message);

  @override
  String toString() => 'ServerException($statusCode): $message';
}

class CloudFunctionsClient {
  static final CloudFunctionsClient _singleton =
      CloudFunctionsClient._internal();
  static const appEngineBaseUrl = AppConfig.backendUrl;

  factory CloudFunctionsClient() {
    return _singleton;
  }

  CloudFunctionsClient._internal() {
    logger.info("Backend URL: $appEngineBaseUrl");
  }

  String _extractErrorMessage(String body) {
    try {
      var decoded = jsonDecode(body);
      if (decoded is Map) {
        return decoded["error"] ?? decoded["message"] ?? body;
      }
    } catch (_) {}
    return body;
  }

  Future<Map<String, String>> _headers() async {
    String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Bearer ' + token,
      if (LaunchController.appVersion != null)
        'App-Version': LaunchController.appVersion ?? "n/a",
      'X-Test-Mode': AppConfig.testMode.toString(),
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

    if (r.statusCode >= 400) {
      var errorMsg = _extractErrorMessage(r.body);
      logger.severe("Server error (${r.statusCode}) on POST $name: $errorMsg");
      throw ServerException(r.statusCode, errorMsg);
    }

    var responseBody = r.body;
    try {
      return jsonDecode(responseBody)["data"];
    } catch (e) {
      var message = "Failed to decode response body: $responseBody";
      logger.severe(message, e);
      throw ServerException(500, message);
    }
  }

  Future<Map<String, dynamic>?> get(String name,
      {Map<String, dynamic> args = const {}}) async {
    var fullResponse = await getFullResponse(name, args: args);
    return fullResponse?["data"];
  }

  Future<Map<String, dynamic>?> getFullResponse(String name,
      {Map<String, dynamic> args = const {}}) async {
    logger.info("GET $name with args ${args.toString()}");

    var baseUri = Uri.parse("$appEngineBaseUrl/$name");
    Uri uri;
    if (args.isNotEmpty) {
      uri = baseUri.replace(
          queryParameters:
              args.map((key, value) => MapEntry(key, value.toString())));
    } else {
      uri = baseUri;
    }

    var r = await http.get(uri, headers: await _headers());
    if (r.statusCode >= 400) {
      var errorMsg = _extractErrorMessage(r.body);
      logger.severe("Server error (${r.statusCode}) on GET $name: $errorMsg");
      throw ServerException(r.statusCode, errorMsg);
    }

    return Map<String, dynamic>.from(jsonDecode(r.body));
  }

  Future<void> delete(String name) async {
    logger.info("DELETE $name");

    var r = await http.delete(
      Uri.parse("$appEngineBaseUrl/$name"),
      headers: await _headers(),
    );

    if (r.statusCode >= 400) {
      var errorMsg = _extractErrorMessage(r.body);
      logger.severe(
          "Server error (${r.statusCode}) on DELETE $name: $errorMsg");
      throw ServerException(r.statusCode, errorMsg);
    }
  }

  String getUrl(String path) => "$appEngineBaseUrl/$path";
}
