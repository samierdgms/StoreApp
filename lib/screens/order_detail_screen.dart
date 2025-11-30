import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({Key? key, required this.order}) : super(key: key);

  @override
  _OrderDetailScreenState createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final supabase = Supabase.instance.client; // Supabase client eklendi
  late Map<String, dynamic> currentOrder; // order yerine currentOrder kullanalım ki güncelleyebilelim
  bool _isLoading = true;
  bool _isCancelling = false; // İptal işlemi sırasında loading göstermek için
  String? _marketName;

  @override
  void initState() {
    super.initState();
    currentOrder = widget.order; // İlk veriyi al
    _loadOrderData();
  }

  Future<void> _loadOrderData() async {
    try {
      final marketId = currentOrder['market_id'];
      if (marketId != null) {
        final marketRes = await supabase
            .from('markets')
            .select('name')
            .eq('id', marketId)
            .maybeSingle();

        if (marketRes != null) {
          _marketName = marketRes['name'];
        }
      }
    } catch (e) {
      debugPrint('Market adı çekilemedi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- SİPARİŞ İPTAL FONKSİYONU ---
  Future<void> _cancelOrder() async {
    // Emin misin diye soralım
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Siparişi İptal Et'),
        content: const Text('Siparişinizi iptal etmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Evet, İptal Et', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);

    try {
      // Sadece status güncelliyoruz
      await supabase
          .from('orders')
          .update({'status': 'Sipariş İptal Edildi'})
          .eq('id', currentOrder['id']);

      if (mounted) {
        setState(() {
          currentOrder['status'] = 'Sipariş İptal Edildi'; // UI'ı güncelle
          _isCancelling = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Siparişiniz iptal edildi.'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCancelling = false);
        // Eğer SQL Policy izin vermezse (örn: sipariş hazırlanmaya başladıysa) burası çalışır
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sipariş hazırlanmaya başlandığı için iptal edilemez!'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    if (status.contains('Teslim Edildi')) return Colors.green;
    if (status.contains('Yolda')) return Colors.blue;
    if (status.contains('Hazırlanıyor')) return Colors.orange;
    if (status.contains('Reddedildi') || status.contains('İptal')) return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> products = currentOrder['products'] ?? [];
    final totalPrice = (currentOrder['total_price'] as num).toDouble();
    final discountAmount = (currentOrder['discount_amount'] ?? 0) as num;
    final finalPrice = (currentOrder['final_price'] as num).toDouble();
    final deliveryFee = (currentOrder['delivery_fee'] ?? 0).toDouble();
    final createdAt = DateTime.parse(currentOrder['created_at']).toLocal();
    final orderNote = currentOrder['order_note'];
    final status = currentOrder['status'] ?? 'Bilinmiyor';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Sipariş Detayı', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Alt buton için boşluk
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(status, createdAt),
                const SizedBox(height: 16),
                const Text("Sipariş İçeriği", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final item = products[index];
                    return _buildProductRow(item);
                  },
                ),
                const SizedBox(height: 20),
                _buildSummaryCard(totalPrice, discountAmount, deliveryFee, finalPrice),
                const SizedBox(height: 20),
                _buildDeliveryInfoCard(orderNote, currentOrder['delivery_address'] ?? '', currentOrder['payment_method'] ?? ''),
              ],
            ),
          ),

          // --- İPTAL BUTONU ALANI ---
          if (status == 'Sipariş Onayı Bekleniyor')
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0,-5))],
                ),
                child: SafeArea(
                  child: _isCancelling
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _cancelOrder,
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text("Siparişi İptal Et"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: Colors.red.shade200)
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ... Diğer Widget metodları aynı kalabilir (_buildHeaderCard, _buildProductRow vb.)
  // Sadece buraya kopyalamadım, mevcut kodunun aynısını kullanabilirsin.

  Widget _buildHeaderCard(String status, DateTime date) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.store, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                _marketName ?? 'Market',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
            ),
            child: Text(
              status,
              style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${date.day}/${date.month}/${date.year} • ${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}",
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
            child: Text("${item['quantity']}x", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title'] ?? 'Ürün', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text("${item['price']} ₺ / ${item['unit'] ?? 'Adet'}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Text(
            "₺${(item['total'] ?? 0).toStringAsFixed(2)}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double total, num discount, double delivery, double finalPrice) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          _buildSummaryRow("Ara Toplam", "₺${total.toStringAsFixed(2)}"),
          if (discount > 0)
            _buildSummaryRow("İndirim", "-₺${discount.toStringAsFixed(2)}", color: Colors.green),
          _buildSummaryRow("Teslimat Ücreti", delivery == 0 ? "Ücretsiz" : "₺${delivery.toStringAsFixed(2)}", color: delivery == 0 ? Colors.green : Colors.black),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
          _buildSummaryRow("Toplam Tutar", "₺${(finalPrice).toStringAsFixed(2)}", isBold: true, fontSize: 18),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color color = Colors.black, bool isBold = false, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: fontSize)),
          Text(value, style: TextStyle(color: color, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: fontSize)),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfoCard(String? note, String address, String payment) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Teslimat Bilgileri", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(address, style: const TextStyle(height: 1.4))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.payment, color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              Text(payment),
            ],
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text("Sipariş Notu:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(note, style: const TextStyle(fontStyle: FontStyle.italic)),
          ]
        ],
      ),
    );
  }
}