import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderSettingsScreen extends StatefulWidget {
  const OrderSettingsScreen({super.key});

  @override
  State<OrderSettingsScreen> createState() => _OrderSettingsScreenState();
}

class _OrderSettingsScreenState extends State<OrderSettingsScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;

  Map<String, bool> sectionStates = {
    'Onay Bekleyenler': false,
    'Aktif Siparişler': false,
    'Teslim Edilenler': false,
    'Reddedilenler': false,
  };

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    final response = await supabase
        .from('orders')
        .select('*, users(name, surname, phone_number)')
        .order('created_at', ascending: false);

    setState(() {
      orders = List<Map<String, dynamic>>.from(response);
      isLoading = false;
    });
  }

  Future<void> updateOrderStatus(String id, String status) async {
    await supabase.from('orders').update({'status': status}).eq('id', id);
    await fetchOrders();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sipariş durumu "$status" olarak güncellendi')),
    );
  }

  Future<void> cancelOrder(String id, String cancelReason) async {
    String updatedStatus = 'Sipariş Reddedildi ($cancelReason)';
    await supabase.from('orders').update({
      'status': updatedStatus,
    }).eq('id', id);
    await fetchOrders();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sipariş iptal edildi: $cancelReason')),
    );
  }

  List<Map<String, dynamic>> getByStatus(String status) {
    return orders.where((o) => o['status'] == status).toList();
  }

  List<Map<String, dynamic>> getActiveOrders() {
    return orders.where((o) => ['Sipariş Hazırlanıyor', 'Sipariş Yolda'].contains(o['status'])).toList();
  }

  List<Map<String, dynamic>> getCanceledOrders() {
    return orders.where((o) =>
    o['status']?.toString().startsWith('Sipariş Reddedildi') ?? false).toList();
  }

  Widget buildSection(String title, List<Map<String, dynamic>> orderList) {
    if (orderList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...orderList.map(buildOrderCard),
      ],
    );
  }

  Widget buildOrderCard(Map<String, dynamic> order) {
    final String id = order['id'];
    final double finalPrice = (order['final_price'] as num).toDouble();
    final String status = order['status'];
    final String address = order['delivery_address'] ?? '';
    final List<dynamic> products = order['products'] ?? [];
    final String orderNote = order['order_note'] ?? '';

    final user = order['users'];
    final String customerName = '${user['name']} ${user['surname']}';
    final String customerPhone = user['phone_number'] ?? 'Numara yok';

    bool isExpanded = false;
    String? cancelReason;

    return StatefulBuilder(
      builder: (context, setInnerState) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: InkWell(
            onTap: () => setInnerState(() => isExpanded = !isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sipariş No: $id', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Durum: $status'),
                  Text('Tutar: ${finalPrice.toStringAsFixed(2)} ₺'),
                  if (orderNote.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text('Sipariş Notu: $orderNote', style: const TextStyle(fontStyle: FontStyle.italic)),
                    ),
                  if (isExpanded) ...[
                    const SizedBox(height: 8),
                    Text('Müşteri: $customerName'),
                    Text('Telefon: $customerPhone'),
                    Text('Adres: $address'),
                    const SizedBox(height: 8),
                    Text('Ürünler:'),
                    for (var p in products) Text('- ${p['title']} x${p['quantity']}'),
                    const SizedBox(height: 12),

                    if (status == 'Sipariş Onayı Bekleniyor') ...[
                      ElevatedButton.icon(
                        onPressed: () => updateOrderStatus(id, 'Sipariş Hazırlanıyor'),
                        icon: const Icon(Icons.check),
                        label: const Text('Onayla'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          DropdownButton<String>(
                            value: cancelReason,
                            hint: const Text('İptal Sebebi Seçin'),
                            items: const [
                              DropdownMenuItem(value: 'Kurye Yok', child: Text('Kurye Yok')),
                              DropdownMenuItem(value: 'Ürün Mevcut Değil', child: Text('Ürün Mevcut Değil')),
                              DropdownMenuItem(value: 'İşletme Kapalı', child: Text('İşletme Kapalı')),
                            ],
                            onChanged: (value) {
                              setInnerState(() => cancelReason = value);
                            },
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: cancelReason != null ? () {
                              cancelOrder(id, cancelReason!);
                            } : null,
                            child: const Text('İptal Et'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          ),
                        ],
                      ),
                    ],

                    if (status == 'Sipariş Hazırlanıyor' || status == 'Sipariş Yolda') ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          DropdownButton<String>(
                            value: cancelReason,
                            hint: const Text('İptal Sebebi Seçin'),
                            items: const [
                              DropdownMenuItem(value: 'Kurye Yok', child: Text('Kurye Yok')),
                              DropdownMenuItem(value: 'Ürün Mevcut Değil', child: Text('Ürün Mevcut Değil')),
                              DropdownMenuItem(value: 'İşletme Kapalı', child: Text('İşletme Kapalı')),
                            ],
                            onChanged: (value) {
                              setInnerState(() => cancelReason = value);
                            },
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: cancelReason != null ? () {
                              cancelOrder(id, cancelReason!);
                            } : null,
                            child: const Text('İptal Et'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          ),
                        ],
                      ),
                    ],

                    if (status != 'Sipariş Onayı Bekleniyor') ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: null,
                        hint: const Text('Durum Güncelle'),
                        items: const [
                          DropdownMenuItem(value: 'Sipariş Yolda', child: Text('Sipariş Yolda')),
                          DropdownMenuItem(value: 'Sipariş Teslim Edildi', child: Text('Sipariş Teslim Edildi')),
                        ],
                        onChanged: (value) {
                          if (value != null) updateOrderStatus(id, value);
                        },
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Siparişler')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSectionWithToggle('Onay Bekleyenler', getByStatus('Sipariş Onayı Bekleniyor')),
            buildSectionWithToggle('Aktif Siparişler', getActiveOrders()),
            buildSectionWithToggle('Teslim Edilenler', getByStatus('Sipariş Teslim Edildi')),
            buildSectionWithToggle('Reddedilenler', getCanceledOrders()),
          ],
        ),
      ),
    );
  }

  Widget buildSectionWithToggle(String title, List<Map<String, dynamic>> orderList) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            ListTile(
              title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              trailing: Icon(
                sectionStates[title] == true ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: Colors.black,
              ),
              onTap: () {
                setState(() {
                  sectionStates[title] = !sectionStates[title]!;
                });
              },
            ),
            Visibility(
              visible: sectionStates[title] == true,
              child: buildSection(title, orderList),
            ),
          ],
        );
      },
    );
  }
}
