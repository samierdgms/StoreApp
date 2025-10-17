import 'package:flutter/material.dart';

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({Key? key, required this.order}) : super(key: key);

  @override
  _OrderDetailScreenState createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Map<String, dynamic> order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    order = widget.order; // Başlangıçta order'ı alıyoruz
    _loadOrderData();
  }

  // Arka planda sipariş detaylarını yüklemek için fonksiyon
  Future<void> _loadOrderData() async {
    // Burada Supabase veya backend'den veri çekme işlemini başlatıyoruz
    await Future.delayed(const Duration(seconds: 1));  // Veriyi simüle etmek için

    // Arka planda işlemi yaptıktan sonra UI'yi güncelleyeceğiz
    setState(() {
      order['order_note'] = order['order_note'] ?? 'Sipariş notu mevcut değil'; // Sipariş notu
      _isLoading = false; // Yüklenme tamamlandı
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> products = order['products'];
    final totalPrice = (order['total_price'] as num).toDouble();
    final discountAmount = (order['discount_amount'] ?? 0) as num;
    final finalPrice = (order['final_price'] as num).toDouble();
    final createdAt = DateTime.parse(order['created_at']);
    final couponCode = order['coupon_code'];

    // deliveryFee'yi doğrudan order tablosundan alıyoruz
    final deliveryFee = order['delivery_fee'] ?? 29.99;
    final orderNote = order['order_note'] ?? ''; // Sipariş notunu alıyoruz

    return Scaffold(
      appBar: AppBar(title: const Text('Sipariş Detayı')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator()) // Yükleme spinner'ı
                : SingleChildScrollView(  // SingleChildScrollView kullanarak kaydırılabilir hale getiriyoruz
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sipariş Kodu
                  Text(
                    'Sipariş Kodu: ${order['id'].toString().substring(0, 8)}...',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Sipariş Tarihi
                  Text('Sipariş Tarihi: ${createdAt.toString().substring(0, 16)}'),
                  Text('Ödeme Yöntemi: ${order['payment_method']}'),
                  Text('Durum: ${order['status']}'),
                  const Divider(height: 24),

                  // Sipariş Notu
                  if (orderNote.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Sipariş Notu: $orderNote',
                      style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ],
                  const Divider(height: 24),

                  // Ürün Başlığı
                  const Text(
                    'Ürünler',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Ürün Listesi
                  Wrap(
                    spacing: 16,  // Her öğe arasındaki yatay mesafe
                    runSpacing: 16, // Satırlar arasındaki dikey mesafe
                    children: List.generate(products.length, (index) {
                      final item = products[index];
                      final name = item['title'] ?? 'Ürün';
                      final quantity = item['quantity'] ?? 1;
                      final price = item['price'] ?? 0;
                      final total = item['total'] ?? 0;
                      final unit = item['unit'] ?? 'Birim';  // Unit bilgisi

                      return Container(
                        width: MediaQuery.of(context).size.width / 2 - 32, // Ekran genişliğine göre genişlik
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Ürün Adı
                                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('Adet: $quantity'),
                                Text('Toplam: ₺${total.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
                                Text('Birim Fiyat: ₺${price.toStringAsFixed(2)} / $unit', style: const TextStyle(color: Colors.grey)),
                                const SizedBox(height: 8),
                                // Ürün ID'sini gösterebiliriz
                                Text(
                                  'ID: ${item['product_id']}',
                                  style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const Divider(height: 32),

                  // Ürün Tutarı
                  Text('Ürün Tutarı: ₺${totalPrice.toStringAsFixed(2)}'),

                  // İndirim Bilgisi
                  Row(
                    children: [
                      Text(
                        'İndirim: -₺${discountAmount.toStringAsFixed(2)}',
                      ),
                      if (couponCode != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '(Kupon: $couponCode)',
                            style: const TextStyle(color: Colors.deepPurple, fontStyle: FontStyle.italic),
                          ),
                        ),
                    ],
                  ),

                  // Kargo Ücreti
                  Text('Kargo Ücreti: ₺${deliveryFee.toStringAsFixed(2)}'),

                  const SizedBox(height: 8),

                  // Ödenen Tutar
                  Text(
                    'Ödenen Tutar: ₺${(finalPrice + deliveryFee).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),

                  const SizedBox(height: 12),

                  // Teslimat Adresi
                  Text('Teslimat Adresi:\n${order['delivery_address']}'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
