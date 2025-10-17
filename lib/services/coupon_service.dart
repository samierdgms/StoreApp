import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/coupon.dart';

class CouponService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Kupon doğrulama
  static Future<Coupon?> validateCoupon(String code) async {
    final response = await _client
        .from('coupons')
        .select()
        .eq('code', code)
        .eq('is_active', true)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;

    return Coupon.fromJson(response);
  }

  // Kuponları çek
  static Future<List<Coupon>> fetchAllCoupons() async {
    try {
      final response = await _client.from('coupons').select();

      final data = response as List<dynamic>;
      return data.map((e) => Coupon.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Kuponlar alınamadı: $e');
    }
  }

  // Kupon ekle
  static Future<void> addCoupon(Coupon coupon) async {
    try {
      await _client.from('coupons').insert({
        'code': coupon.code,
        'type': coupon.type,
        'value': coupon.value,
        'min_amount': coupon.minAmount,
        'description': coupon.description,
        'is_active': coupon.isActive,
      });
    } catch (e) {
      throw Exception('Kupon eklenemedi: $e');
    }
  }

  // Kupon güncelle
  static Future<void> updateCoupon(Coupon coupon) async {
    try {
      await _client.from('coupons').update({
        'type': coupon.type,
        'value': coupon.value,
        'min_amount': coupon.minAmount,
        'description': coupon.description,
        'is_active': coupon.isActive,
      }).eq('code', coupon.code);
    } catch (e) {
      throw Exception('Kupon güncellenemedi: $e');
    }
  }
}
