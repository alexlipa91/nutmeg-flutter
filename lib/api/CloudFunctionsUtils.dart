import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_performance/firebase_performance.dart';


class CloudFunctionsClient {
  static final CloudFunctionsClient _singleton = CloudFunctionsClient._internal();

  FirebaseFunctions _client = FirebaseFunctions.instanceFor(region: "europe-central2");

  factory CloudFunctionsClient() {
    return _singleton;
  }

  CloudFunctionsClient._internal();

  Future<Map<String, dynamic>> callFunction(String name, Map<String, dynamic> data) async {
    print("Calling " + name + " with data " + data.toString());

    var trace = FirebasePerformance.instance.newTrace("api-call");
    await trace.start();
    trace.putAttribute("function_name", name);
    final Stopwatch stopwatch = Stopwatch();

    HttpsCallable callable = _client.httpsCallable(name);
    var resp = await callable(data);

    trace.setMetric("duration_ms", stopwatch.elapsed.inMilliseconds);
    trace.stop();

    return resp.data;
  }
}
