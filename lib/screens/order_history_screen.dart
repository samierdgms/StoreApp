import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final _supabase = Supabase.instance.client;
  late Future<List<Order>> _orders;

  @override
  void initState() {
    super.initState();
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      _orders = OrderService.fetchOrdersByUser(userId);
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Sipariş Reddedildi (Kurye Yok)':
        return Colors.red;
      case 'Sipariş Reddedildi (Ürün Mevcut Değil)':
        return Colors.red;
      case 'Sipariş Reddedildi (İşletme Kapalı)':
        return Colors.red;
      case 'Sipariş Onayı Bekleniyor':
        return Colors.brown;
      case 'Sipariş Hazırlanıyor':
        return Colors.orange;
      case 'Sipariş Yolda':
        return Colors.orange;
      case 'Sipariş Teslim Edildi':
        return Colors.green;
      default:
        return Colors.black; // Varsayılan renk
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sipariş Geçmişi')),
      body: FutureBuilder<List<Order>>(
        future: _orders,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          final orders = snapshot.data;
          if (orders == null || orders.isEmpty) {
            return const Center(child: Text('Hiç sipariş bulunamadı.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailScreen(order: order.toJson()),
                    ),
                  );
                },
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sipariş Kodu: ${order.id?.substring(0, 8)}...',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tarih: ${order.createdAt.toLocal().toString().substring(0, 16)}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Toplam: ₺${(order.finalPrice + order.deliveryFee).toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Durum: ${order.status}',
                          style: TextStyle(
                            color: getStatusColor(order.status), // Duruma göre renk ayarlandı
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
