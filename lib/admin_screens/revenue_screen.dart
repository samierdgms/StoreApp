import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import '../admin_screens/daily_revenue_detail_screen.dart';

class RevenueScreen extends StatefulWidget {
  const RevenueScreen({super.key});

  @override
  _RevenueScreenState createState() => _RevenueScreenState();
}

class _RevenueScreenState extends State<RevenueScreen> {
  final supabase = Supabase.instance.client;

  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  int selectedDay = DateTime.now().day;

  List<Order> orders = [];
  Map<String, int> orderStatusCount = {
    'Alınan Siparişler': 0,
    'Reddedilen Siparişler': 0,
    'Teslim Edilen Siparişler': 0,
  };
  double totalRevenue = 0.0;
  double monthlyCashRevenue = 0.0;
  double monthlyCardRevenue = 0.0;
  Map<String, int> productSales = {};

  @override
  void initState() {
    super.initState();
    fetchOrdersForDateRange(
      DateTime(selectedYear, selectedMonth, 1),
      DateTime(selectedYear, selectedMonth + 1, 0, 23, 59, 59),
    );
  }

  Future<void> fetchOrdersForDateRange(DateTime startDate, DateTime endDate) async {
    final response = await supabase
        .from('orders')
        .select()
        .gte('created_at', startDate.toIso8601String())
        .lte('created_at', endDate.toIso8601String())
        .order('created_at', ascending: false);

    orders = (response as List<dynamic>).map((map) => Order.fromMap(map)).toList();

    totalRevenue = 0.0;
    monthlyCashRevenue = 0.0;
    monthlyCardRevenue = 0.0;
    orderStatusCount = {
      'Alınan Siparişler': 0,
      'Reddedilen Siparişler': 0,
      'Teslim Edilen Siparişler': 0,
    };
    productSales = {};

    for (var order in orders) {
      if (order.status == 'Sipariş Teslim Edildi') {
        totalRevenue += order.finalPrice;

        if (order.paymentMethod == 'Kapıda Ödeme / Nakit') {
          monthlyCashRevenue += order.finalPrice;
        } else if (order.paymentMethod == 'Kapıda Ödeme / Kart') {
          monthlyCardRevenue += order.finalPrice;
        }

        orderStatusCount['Teslim Edilen Siparişler'] =
            orderStatusCount['Teslim Edilen Siparişler']! + 1;

        for (var product in order.products) {
          productSales[product['title']] =
              (productSales[product['title']] ?? 0) + (product['quantity'] as int);
        }
      } else if (order.status.contains('Reddedildi')) {
        orderStatusCount['Reddedilen Siparişler'] =
            orderStatusCount['Reddedilen Siparişler']! + 1;
      }

      orderStatusCount['Alınan Siparişler'] =
          orderStatusCount['Alınan Siparişler']! + 1;
    }

    setState(() {});
  }

  String _getMonthName(int month) {
    List<String> monthNames = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return monthNames[month - 1];
  }

  void _showDailyRevenueDetails() {
    DateTime selectedDate = DateTime(selectedYear, selectedMonth, selectedDay);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DailyRevenueDetailsScreen(date: selectedDate),
      ),
    );
  }

  List<DropdownMenuItem<int>> _getDropdownItems(int start, int end) {
    return List.generate(end - start + 1, (index) {
      int value = start + index;
      return DropdownMenuItem(
        value: value,
        child: Text('$value'),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Satış Takip'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Tarih Seçimi Alanı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDropdownBox(
                  icon: Icons.calendar_today,
                  label: 'Ay',
                  value: selectedMonth,
                  items: _getDropdownItems(1, 12),
                  display: _getMonthName(selectedMonth),
                  onChanged: (val) {
                    setState(() {
                      selectedMonth = val!;
                      fetchOrdersForDateRange(
                        DateTime(selectedYear, selectedMonth, 1),
                        DateTime(selectedYear, selectedMonth + 1, 0, 23, 59, 59),
                      );
                    });
                  },
                ),
                _buildDropdownBox(
                  icon: Icons.date_range,
                  label: 'Yıl',
                  value: selectedYear,
                  items: _getDropdownItems(2020, 2030),
                  display: selectedYear.toString(),
                  onChanged: (val) {
                    setState(() {
                      selectedYear = val!;
                      fetchOrdersForDateRange(
                        DateTime(selectedYear, selectedMonth, 1),
                        DateTime(selectedYear, selectedMonth + 1, 0, 23, 59, 59),
                      );
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoBox(
                  icon: Icons.attach_money,
                  label: 'Toplam',
                  value: '₺${totalRevenue.toStringAsFixed(2)}',
                ),
                _buildInfoBox(
                  icon: Icons.money,
                  label: 'Nakit',
                  value: '₺${monthlyCashRevenue.toStringAsFixed(2)}',
                ),
                _buildInfoBox(
                  icon: Icons.credit_card,
                  label: 'Kart',
                  value: '₺${monthlyCardRevenue.toStringAsFixed(2)}',
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildOrderStatusTable(),
            const SizedBox(height: 20),
            _buildProductSalesTable(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Gün Seç',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.today),
                    ),
                    value: selectedDay,
                    items: _getDropdownItems(1, 31),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          selectedDay = val;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _showDailyRevenueDetails,
                  icon: const Icon(Icons.search),
                  label: const Text('Günlük Satış Detayı'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownBox({
    required IconData icon,
    required String label,
    required String display,
    required int value,
    required List<DropdownMenuItem<int>> items,
    required void Function(int?) onChanged,
  }) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.blueAccent),
        Text(label, style: const TextStyle(fontSize: 12)),
        DropdownButton<int>(
          value: value,
          items: items,
          onChanged: onChanged,
          underline: Container(),
          style: const TextStyle(fontSize: 16, color: Colors.black),
          icon: const Icon(Icons.arrow_drop_down),
        ),
      ],
    );
  }

  Widget _buildInfoBox({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.green),
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildOrderStatusTable() {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: const Text('Alınan Siparişler'),
            trailing: Text(orderStatusCount['Alınan Siparişler'].toString()),
          ),
          ListTile(
            title: const Text('Reddedilen Siparişler'),
            trailing: Text(orderStatusCount['Reddedilen Siparişler'].toString()),
          ),
          ListTile(
            title: const Text('Teslim Edilen Siparişler'),
            trailing: Text(orderStatusCount['Teslim Edilen Siparişler'].toString()),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSalesTable() {
    return Card(
      child: Column(
        children: productSales.entries.map((entry) {
          return ListTile(
            title: Text(entry.key),
            trailing: Text('${entry.value} adet'),
          );
        }).toList(),
      ),
    );
  }
}
