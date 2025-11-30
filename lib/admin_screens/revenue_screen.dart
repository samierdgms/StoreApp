import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart'; // Model dosyanızın yolu
import '../providers/market_provider.dart';
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

  // İstatistikleri tutacağımız harita
  Map<String, int> orderStatusCount = {
    'Alınan Siparişler': 0,
    'Reddedilen Siparişler': 0,
    'Müşteri İptali': 0,
    'Teslim Edilen Siparişler': 0,
  };

  double totalRevenue = 0.0;
  double monthlyCashRevenue = 0.0;
  double monthlyCardRevenue = 0.0;
  Map<String, int> productSales = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchOrdersForDateRange(
        DateTime(selectedYear, selectedMonth, 1),
        DateTime(selectedYear, selectedMonth + 1, 0, 23, 59, 59),
      );
    });
  }

  Future<void> fetchOrdersForDateRange(DateTime startDate, DateTime endDate) async {
    final marketId = Provider.of<MarketProvider>(context, listen: false).marketId;
    if (marketId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await supabase
          .from('orders')
          .select()
          .eq('market_id', marketId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false);

      orders = (response as List<dynamic>).map((map) => Order.fromMap(map)).toList();

      // Değişkenleri Sıfırla
      totalRevenue = 0.0;
      monthlyCashRevenue = 0.0;
      monthlyCardRevenue = 0.0;
      orderStatusCount = {
        'Alınan Siparişler': 0,
        'Reddedilen Siparişler': 0,
        'Müşteri İptali': 0,
        'Teslim Edilen Siparişler': 0,
      };
      productSales = {};

      for (var order in orders) {
        orderStatusCount['Alınan Siparişler'] = orderStatusCount['Alınan Siparişler']! + 1;

        if (order.status == 'Sipariş Teslim Edildi') {
          totalRevenue += order.finalPrice;

          if (order.paymentMethod.contains('Nakit')) {
            monthlyCashRevenue += order.finalPrice;
          } else {
            monthlyCardRevenue += order.finalPrice;
          }

          orderStatusCount['Teslim Edilen Siparişler'] = orderStatusCount['Teslim Edilen Siparişler']! + 1;

          for (var product in order.products) {
            productSales[product['title']] = (productSales[product['title']] ?? 0) + (product['quantity'] as int);
          }
        }
        else if (order.status.contains('İptal')) {
          orderStatusCount['Müşteri İptali'] = orderStatusCount['Müşteri İptali']! + 1;
        }
        else if (order.status.contains('Reddedildi')) {
          orderStatusCount['Reddedilen Siparişler'] = orderStatusCount['Reddedilen Siparişler']! + 1;
        }
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Hata: $e');
      if (mounted) setState(() => _isLoading = false);
    }
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
    final marketId = Provider.of<MarketProvider>(context, listen: false).marketId;

    if (marketId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DailyRevenueDetailsScreen(
            date: selectedDate,
            marketId: marketId,
          ),
        ),
      );
    }
  }

  List<DropdownMenuItem<int>> _getDropdownItems(int start, int end) {
    return List.generate(end - start + 1, (index) {
      int value = start + index;
      return DropdownMenuItem(value: value, child: Text('$value'));
    });
  }

  // --- MODERN UI WIDGETLARI ---

  // Soft Görünümlü Dropdown Kutusu (Helper)
  Widget _buildSoftDropdownContainer({required Widget child, required IconData icon, required Color iconColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // Dış çerçeve yuvarlaklığı
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          // Dropdown'ın altındaki çizgiyi kaldırıyoruz
          DropdownButtonHideUnderline(child: child),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Ay Seçimi
        Expanded(
          child: _buildSoftDropdownContainer(
            icon: Icons.calendar_month_rounded,
            iconColor: Colors.blueAccent,
            child: DropdownButton<int>(
              value: selectedMonth,
              isDense: true,
              // AÇILAN LİSTE AYARLARI BURADA:
              borderRadius: BorderRadius.circular(20), // Açılan listenin köşeleri
              dropdownColor: Colors.white, // Arka plan rengi
              elevation: 2, // Gölge yumuşaklığı (Daha düşük = daha soft)
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 15),
              items: List.generate(12, (index) {
                return DropdownMenuItem(
                  value: index + 1,
                  child: Text(_getMonthName(index + 1)),
                );
              }),
              onChanged: (val) {
                setState(() {
                  selectedMonth = val!;
                  _isLoading = true;
                  fetchOrdersForDateRange(
                    DateTime(selectedYear, selectedMonth, 1),
                    DateTime(selectedYear, selectedMonth + 1, 0, 23, 59, 59),
                  );
                });
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Yıl Seçimi
        Expanded(
          child: _buildSoftDropdownContainer(
            icon: Icons.today_rounded,
            iconColor: Colors.orangeAccent,
            child: DropdownButton<int>(
              value: selectedYear,
              isDense: true,
              // AÇILAN LİSTE AYARLARI:
              borderRadius: BorderRadius.circular(20),
              dropdownColor: Colors.white,
              elevation: 2,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 15),
              items: _getDropdownItems(2023, 2030),
              onChanged: (val) {
                setState(() {
                  selectedYear = val!;
                  _isLoading = true;
                  fetchOrdersForDateRange(
                    DateTime(selectedYear, selectedMonth, 1),
                    DateTime(selectedYear, selectedMonth + 1, 0, 23, 59, 59),
                  );
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernCard({required String title, required Widget content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            FittedBox(
              child: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Satış & Raporlar', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildDateSelector(),
            const SizedBox(height: 24),

            Row(
              children: [
                _buildInfoCard('Toplam Ciro', '₺${totalRevenue.toStringAsFixed(2)}', Icons.wallet, Colors.green),
                const SizedBox(width: 12),
                _buildInfoCard('Nakit', '₺${monthlyCashRevenue.toStringAsFixed(2)}', Icons.money, Colors.blue),
                const SizedBox(width: 12),
                _buildInfoCard('Kredi Kartı', '₺${monthlyCardRevenue.toStringAsFixed(2)}', Icons.credit_card, Colors.purple),
              ],
            ),
            const SizedBox(height: 24),

            _buildModernCard(
              title: "Sipariş İstatistikleri",
              content: Column(
                children: [
                  _buildStatRow('Toplam Alınan Sipariş', orderStatusCount['Alınan Siparişler'].toString(), Colors.blueAccent),
                  const Divider(height: 24),
                  _buildStatRow('Başarılı Teslimat', orderStatusCount['Teslim Edilen Siparişler'].toString(), Colors.green),
                  const Divider(height: 24),
                  _buildStatRow('Müşteri İptali', orderStatusCount['Müşteri İptali'].toString(), Colors.orange),
                  const SizedBox(height: 8),
                  _buildStatRow('İşletme Reddi', orderStatusCount['Reddedilen Siparişler'].toString(), Colors.red),
                ],
              ),
            ),

            _buildModernCard(
              title: "Bu Ayın Yıldızları 🌟",
              content: productSales.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("Henüz satış verisi yok.", style: TextStyle(color: Colors.grey))))
                  : Column(
                children: productSales.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)),
                          child: Text('${entry.value} Adet', style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 10),

            // Modern Günlük Detay Seçici (Dropdown düzeltildi)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Icon(Icons.insights, color: Colors.blueGrey),
                      SizedBox(width: 8),
                      Text("Günlük Detaylı Rapor", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: selectedDay,
                              // GÜNLÜK SEÇİM KUTUSU İÇİN DE AYNI YUMUŞATMA:
                              borderRadius: BorderRadius.circular(20),
                              elevation: 2,
                              dropdownColor: Colors.white,
                              icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: Colors.blue),
                              items: List.generate(31, (index) => DropdownMenuItem(value: index + 1, child: Text("${index + 1}. Gün", style: const TextStyle(fontWeight: FontWeight.bold)))),
                              onChanged: (val) => setState(() => selectedDay = val!),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: ElevatedButton(
                          onPressed: _showDailyRevenueDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: const Text('Raporu Aç', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500)),
            ],
          ),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}