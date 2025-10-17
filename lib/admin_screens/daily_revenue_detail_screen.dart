import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';

class DailyRevenueDetailsScreen extends StatefulWidget {
  final DateTime date;

  const DailyRevenueDetailsScreen({super.key, required this.date});

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

    final response = await supabase
        .from('orders')
        .select()
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

        if (order.paymentMethod == 'Kapıda Ödeme / Nakit') {
          cashRevenue += order.finalPrice;
        } else if (order.paymentMethod == 'Kapıda Ödeme / Kart') {
          cardRevenue += order.finalPrice;
        }

        for (var product in order.products) {
          productSales[product['title']] =
              (productSales[product['title']] ?? 0) + (product['quantity'] as int);
        }
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${formatDate(widget.date)} Satış Detayları'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : dailyOrders.isEmpty || dailyRevenue == 0
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.info_outline, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Üzgünüz, bugün satış yapılmamış.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.attach_money,
                            size: 40, color: Colors.green),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Günlük Satış',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500)),
                            Text(
                              '₺${dailyRevenue.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Text('Nakit: ₺${cashRevenue.toStringAsFixed(2)}'),
                    Text('Kart: ₺${cardRevenue.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Satılan Ürünler',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: productSales.length,
                itemBuilder: (context, index) {
                  String productName = productSales.keys.elementAt(index);
                  int quantitySold = productSales[productName]!;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.shopping_cart),
                      title: Text(productName),
                      trailing: Text('x $quantitySold',
                          style: const TextStyle(fontSize: 16)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
