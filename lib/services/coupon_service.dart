import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/coupon.dart';

class CouponService {
  static final SupabaseClient _client = Supabase.instance.client;

  // ✅ YENİ: Kupon doğrularken hangi markette denendiğini kontrol et
  static Future<Coupon?> validateCoupon(String code, String marketId) async {
    final response = await _client
        .from('coupons')
        .select()
        .eq('code', code)
        .eq('is_active', true)
        .eq('market_id', marketId) // <-- Başka marketin kuponu burada geçmez
        .limit(1)
        .maybeSingle();

    if (response == null) return null;

    return Coupon.fromJson(response);
  }

  // ✅ YENİ: Sadece o marketin kuponlarını listele (Kampanyalar sayfası için)
  static Future<List<Coupon>> fetchAllCoupons(String marketId) async {
    try {
      final response = await _client
          .from('coupons')
          .select()
          .eq('market_id', marketId); // <-- Filtre

      final data = response as List<dynamic>;
      return data.map((e) => Coupon.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Kuponlar alınamadı: $e');
    }
  }

  // ✅ YENİ: Kupon eklerken market_id ekle
  static Future<void> addCoupon(Coupon coupon, String marketId) async {
    try {
      await _client.from('coupons').insert({
        'code': coupon.code,
        'type': coupon.type,
        'value': coupon.value,
        'min_amount': coupon.minAmount,
        'description': coupon.description,
        'is_active': coupon.isActive,
        'market_id': marketId, // <-- Kayıt
      });
    } catch (e) {
      throw Exception('Kupon eklenemedi: $e');
    }
  }

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