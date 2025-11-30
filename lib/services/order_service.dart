import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import 'fee_service.dart';

class OrderService {
  static final _client = Supabase.instance.client;

  static Future<void> createOrder(Order order, String marketId) async {
    final userId = _client.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('Kullanıcı oturumu bulunamadı.');
    }

    // Güvenlik için ücretleri tekrar kontrol et
    final fees = await FeeService.getFees(marketId);
    final deliveryFeeThreshold = fees['free_delivery_amount'] ?? 1500.0;
    final deliveryFeeValue = fees['delivery_fee'] ?? 29.99;

    final deliveryFee = order.totalPrice >= deliveryFeeThreshold ? 0.0 : deliveryFeeValue;

    // 👇 İŞTE BURADA EKSİK ALANLARI EKLİYORUZ
    await _client.from('orders').insert({
      'user_id': userId,
      'market_id': marketId,
      'products': order.products.map((product) {
        return {
          'product_id': product['product_id'],
          'title': product['title'],
          'price': product['price'],
          'quantity': product['quantity'],
          'total': product['total'],
          'unit': product['unit'],
        };
      }).toList(),
      'total_price': order.totalPrice,
      'coupon_code': order.couponCode,
      'discount_amount': order.discountAmount,
      'final_price': order.finalPrice,
      'delivery_fee': deliveryFee,
      'payment_method': order.paymentMethod,
      'status': order.status,
      'delivery_address': order.deliveryAddress,
      'created_at': order.createdAt.toIso8601String(),
      'order_note': order.orderNote,

      // ✅ EKLENEN SNAPSHOT VERİLERİ (BUNLAR EKSİKTİ)
      'customer_name': order.customerName,
      'customer_surname': order.customerSurname,
      'customer_phone': order.customerPhone,
      'city': order.city,
      'district': order.district,
    });
  }

  // Kullanıcı Siparişleri
  static Future<List<Order>> fetchOrdersByUser(String userId) async {
    final response = await _client
        .from('orders')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((map) => Order.fromMap(map))
        .toList();
  }

  // ✅ GÜNCELLENDİ: Admin (Market Sahibi) için siparişleri çekme
  static Future<List<Map<String, dynamic>>> fetchOrdersByMarket(String marketId) async {
    // ARTIK JOIN YOK! Doğrudan orders tablosunu çekiyoruz.
    // 'users(name...)' kısmını kaldırdık çünkü veriler artık orders tablosunun içinde.
    final response = await _client
        .from('orders')
        .select('*')
        .eq('market_id', marketId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}