import 'package:flutter_test/flutter_test.dart';
import 'package:nutmeg/utils/LocationUtils.dart';

void main() {

  test('Distance is fetched correctly', () async {
    expect("4.2 km",
        await LocationUtils.getDistanceInKm(52.36443255411427, 4.932104112581562, "ChIJ3zv5cYsJxkcRAr4WnAOlCT4"));
  });
}