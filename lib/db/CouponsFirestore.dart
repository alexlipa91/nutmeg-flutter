import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutmeg/model/Model.dart';


class CouponsFirestore {

  static var _ref = FirebaseFirestore.instance.collection('coupons').withConverter<Coupon>(
    fromFirestore: (snapshot, _) => Coupon.fromJson(snapshot.data(), snapshot.id),
    toFirestore: (match, _) => match.toJson(),
  );

  static Future<List<Coupon>> getCoupons() async {
    var qs = await _ref.get();
    return qs.docs.map((e) => e.data()).toList();
  }

  static Future<Coupon> getCouponDiscount(UserDetails userDetails) async {
    var doc = await _ref.get();
    var active = doc.docs.first;
    var id = active.id;

    if (userDetails.usedCoupons.where((e) => e == id).isNotEmpty) {
      return null;
    }
    return active.data();
  }
}
