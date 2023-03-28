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

  Future<Map<String, dynamic>?> callFunction(String name, Map<String, dynamic> data) async {
    if (name == "get_all_matches_v2") {
      return callAppEngine("matches", data);
    }

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

  Future<Map<String, dynamic>?> callAppEngine(String name, Map<String, dynamic> data) async {
    print("Calling AppEngine " + name + " with data " + data.toString());

    var trace = FirebasePerformance.instance.newTrace("api-call");
    trace.start();
    trace.putAttribute("path_name", name);
    trace.putAttribute("source", "app_engine");

    final Stopwatch stopwatch = Stopwatch();

    var r = await http.post(
      Uri.parse("https://nutmeg-9099c.ew.r.appspot.com/$name"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(data),
    );

    trace.setMetric("duration_ms", stopwatch.elapsed.inMilliseconds);
    trace.stop();

    return jsonDecode(r.body)["data"];
  }
}
