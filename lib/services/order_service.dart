import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import 'fee_service.dart';

class OrderService {
  static final _client = Supabase.instance.client;

  // Create an order
  static Future<void> createOrder(Order order) async {
    final userId = _client.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('Kullanıcı oturumu bulunamadı.');
    }

    // Fetch fees and calculate delivery fee
    final fees = await FeeService.getFees();
    final deliveryFeeThreshold = fees['free_delivery_amount'] ?? 1500.0;
    final deliveryFeeValue = fees['delivery_fee'] ?? 29.99;
    final deliveryFee = order.totalPrice >= deliveryFeeThreshold ? 0.0 : deliveryFeeValue;


    await _client.from('orders').insert({
      'user_id': userId,
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
    });
  }

  // Fetch orders by user ID
  static Future<List<Order>> fetchOrdersByUser(String userId) async {
    final response = await _client
        .from('orders')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);



    // Convert the response to a list of Order objects
    return (response as List<dynamic>)
        .map((map) => Order.fromMap(map))
        .toList();
  }
}
