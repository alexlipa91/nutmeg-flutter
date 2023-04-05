import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:http/http.dart' as http;


class CloudFunctionsClient {
  static final CloudFunctionsClient _singleton = CloudFunctionsClient._internal();

  FirebaseFunctions _client = FirebaseFunctions.instanceFor(region: "europe-central2");

  factory CloudFunctionsClient() {
    return _singleton;
  }

  CloudFunctionsClient._internal();

  var appEngineBaseUrl = "https://nutmeg-9099c.ew.r.appspot.com";
  // var appEngineBaseUrl = "http://localhost:8080";

  Future<Map<String, dynamic>?> callFunction(String name, Map<String, dynamic> data) async {
    print("Calling " + name + " with data " + data.toString());

    var trace = FirebasePerformance.instance.newTrace("api-call");
    trace.start();
    trace.putAttribute("function_name", name);
    trace.putAttribute("source", "functions");

    final Stopwatch stopwatch = Stopwatch();

    HttpsCallable callable = _client.httpsCallable(name);
    var resp = await callable(data);

    trace.setMetric("duration_ms", stopwatch.elapsed.inMilliseconds);
    trace.stop();

    return resp.data;
  }

  Future<Map<String, dynamic>?> callLocal(String name, Map<String, dynamic> data) async {
    print("Calling local " + name + " with data " + data.toString());

    var client = FirebaseFunctions.instanceFor(region: "europe-central2");
    client.useFunctionsEmulator("localhost", 8080);

    HttpsCallable callable = client.httpsCallable(name);
    var resp = await callable(data);

    // trace.setMetric("duration_ms", stopwatch.elapsed.inMilliseconds);
    // trace.stop();

    return resp.data;
  }

  Future<Map<String, dynamic>?> post(String name, Map<String, dynamic> data) async {
    print("POST AppEngine " + name + " with data " + data.toString());

    var trace = FirebasePerformance.instance.newTrace("api-call");
    trace.start();
    trace.putAttribute("path_name", name);
    trace.putAttribute("source", "app_engine");

    final Stopwatch stopwatch = Stopwatch();

    var r = await http.post(
      Uri.parse("$appEngineBaseUrl/$name"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(data),
    );

    trace.setMetric("duration_ms", stopwatch.elapsed.inMilliseconds);
    trace.stop();

    return jsonDecode(r.body)["data"];
  }

  Future<Map<String, dynamic>?> get(String name,
      {Map<String, dynamic> args = const {}}) async {
    print("GET AppEngine " + name + " with args " + args.toString());

    var trace = FirebasePerformance.instance.newTrace("api-call");
    trace.start();
    trace.putAttribute("path_name", name);
    trace.putAttribute("source", "app_engine");

    final Stopwatch stopwatch = Stopwatch();

    var argsString = args.entries.map((e) => "${e.key}=${e.value}").join("&");
    var url = "$appEngineBaseUrl/$name";
    if (argsString.isNotEmpty)
      url = "$url?$argsString";

    var r = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      }
    );

    trace.setMetric("duration_ms", stopwatch.elapsed.inMilliseconds);
    trace.stop();

    return jsonDecode(r.body)["data"];
  }
}
