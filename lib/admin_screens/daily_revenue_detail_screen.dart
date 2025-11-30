import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';

class DailyRevenueDetailsScreen extends StatefulWidget {
  final DateTime date;
  final String marketId;

  const DailyRevenueDetailsScreen({
    super.key,
    required this.date,
    required this.marketId,
  });

  @override
  _DailyRevenueDetailsScreenState createState() =>
      _DailyRevenueDetailsScreenState();
}

class _DailyRevenueDetailsScreenState extends State<DailyRevenueDetailsScreen> {
  final supabase = Supabase.instance.client;
  double dailyRevenue = 0.0;
  double cashRevenue = 0.0;
  double cardRevenue = 0.0;
  List<Order> dailyOrders = [];
  Map<String, int> productSales = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDailyOrders();
  }

  Future<void> fetchDailyOrders() async {
    DateTime startDate = DateTime(widget.date.year, widget.date.month, widget.date.day, 0, 0, 0);
    DateTime endDate = DateTime(widget.date.year, widget.date.month, widget.date.day, 23, 59, 59);

    try {
      final response = await supabase
          .from('orders')
          .select()
          .eq('market_id', widget.marketId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false);

      dailyOrders = (response as List<dynamic>).map((map) => Order.fromMap(map)).toList();
      dailyRevenue = 0.0;
      cashRevenue = 0.0;
      cardRevenue = 0.0;
      productSales = {};

      for (var order in dailyOrders) {
        if (order.status == 'Sipariş Teslim Edildi') {
          dailyRevenue += order.finalPrice;

          if (order.paymentMethod.contains('Nakit')) {
            cashRevenue += order.finalPrice;
          } else if (order.paymentMethod.contains('Kart')) {
            cardRevenue += order.finalPrice;
          }

          for (var product in order.products) {
            productSales[product['title']] =
                (productSales[product['title']] ?? 0) + (product['quantity'] as int);
          }
        }
      }

      if (mounted) setState(() => isLoading = false);
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '${formatDate(widget.date)} Raporu',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : dailyOrders.isEmpty || dailyRevenue == 0
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insert_chart_outlined_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Bugün satış kaydı bulunmuyor.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Özet Kartı
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                        child: const Icon(Icons.attach_money, size: 30, color: Colors.green),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Günlük Toplam Ciro', style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                          Text(
                            '₺${dailyRevenue.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMiniStat('Nakit', '₺${cashRevenue.toStringAsFixed(2)}', Icons.money, Colors.blue),
                      ),
                      Container(width: 1, height: 40, color: Colors.grey[200]),
                      Expanded(
                        child: _buildMiniStat('Kredi Kartı', '₺${cardRevenue.toStringAsFixed(2)}', Icons.credit_card, Colors.purple),
                      ),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Satılan Ürünler Başlığı
            const Text(
              'Satılan Ürünler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            // Ürün Listesi
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2))
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: productSales.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (context, index) {
                  String productName = productSales.keys.elementAt(index);
                  int quantitySold = productSales[productName]!;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.shopping_bag_outlined, color: Colors.orange, size: 20),
                    ),
                    title: Text(productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                      child: Text('$quantitySold Adet', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}