import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final supabase = Supabase.instance.client;
  late Map<String, dynamic> currentOrder;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    currentOrder = widget.order;
    // Konsoldan verinin gelip gelmediğini kontrol etmek için yazdırıyoruz
    print("Gelen Sipariş Verisi: $currentOrder");
  }

  /// Supabase'den gelen numeric veriyi hatasız çeviren yardımcı fonksiyon
  double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<void> updateStatus(String newStatus, {String? reason}) async {
    setState(() => isUpdating = true);
    try {
      String statusToSave = newStatus;
      if (reason != null) statusToSave = "$newStatus ($reason)";

      await supabase.from('orders').update({'status': statusToSave}).eq('id', currentOrder['id']);

      if (mounted) {
        setState(() {
          currentOrder['status'] = statusToSave;
          isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Durum güncellendi: $statusToSave'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hata oluştu'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
  }

  void _showRejectModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Siparişi Reddet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...['Ürün/Stok Yok', 'Kurye Yok', 'İşletme Kapalı', 'Yoğunluk Nedeniyle'].map(
                    (reason) => ListTile(
                  leading: const Icon(Icons.cancel_outlined, color: Colors.red),
                  title: Text(reason),
                  onTap: () {
                    Navigator.pop(context);
                    updateStatus("Sipariş Reddedildi", reason: reason);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- VERİ ÇEKME İŞLEMLERİ ---
    final String fullName = "${currentOrder['customer_name']} ${currentOrder['customer_surname']}";
    final String phone = currentOrder['customer_phone'] ?? '-';
    final String fullAddress = "${currentOrder['district']} / ${currentOrder['city']}\n${currentOrder['delivery_address']}";
    final products = currentOrder['products'] is List ? currentOrder['products'] as List : [];
    final String status = currentOrder['status'];
    final String note = currentOrder['order_note'] ?? '';

    // FİYAT HESAPLAMALARI (Garanti Yöntem)
    final double totalPrice = _safeDouble(currentOrder['total_price']);     // İndirimsiz Tutar
    final double discountAmount = _safeDouble(currentOrder['discount_amount']); // İndirim Miktarı
    final double deliveryFee = _safeDouble(currentOrder['delivery_fee']);   // Teslimat Ücreti
    final double finalPrice = _safeDouble(currentOrder['final_price']);     // Son Tutar
    final String? couponCode = currentOrder['coupon_code'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Sipariş Detayı', style: TextStyle(color: Colors.black, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isUpdating
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- MÜŞTERİ KARTI ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(backgroundColor: Colors.blue.shade100, child: Text(fullName.isNotEmpty ? fullName[0] : '?', style: const TextStyle(color: Colors.blue))),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(phone, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              ],
                            ),
                          ),
                          if (phone != '-')
                            IconButton(
                              onPressed: () => _makePhoneCall(phone),
                              icon: const CircleAvatar(
                                backgroundColor: Colors.green,
                                radius: 18,
                                child: Icon(Icons.call, color: Colors.white, size: 18),
                              ),
                            )
                        ],
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(fullAddress, style: const TextStyle(height: 1.4, color: Colors.black87))),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // --- SİPARİŞ NOTU ---
                if (note.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Sipariş Notu:", style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(note, style: TextStyle(color: Colors.amber.shade900)),
                      ],
                    ),
                  ),

                // --- ÜRÜNLER LİSTESİ ---
                const Text("Sipariş İçeriği", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 10),
                ...products.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                        child: Text("${p['quantity']}x", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text("${p['title']}", style: const TextStyle(fontSize: 15))),
                      Text("₺${p['total']}", style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                )).toList(),

                const Divider(height: 30),

                // --- ÖDEME ÖZETİ (GÜNCELLENEN KISIM) ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300), // Çerçeveyi belirginleştirdim
                    boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 5, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.receipt_long, size: 20, color: Colors.blueGrey),
                          SizedBox(width: 8),
                          Text("Ödeme Detayı", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const Divider(height: 20),

                      // Ara Toplam (Total Price)
                      _buildSummaryRow("Ara Toplam", "₺${totalPrice.toStringAsFixed(2)}"),

                      // Teslimat Ücreti (Delivery Fee)
                      _buildSummaryRow("Teslimat Ücreti", deliveryFee == 0 ? "Ücretsiz" : "₺${deliveryFee.toStringAsFixed(2)}"),

                      // İndirim (Discount) - Varsa göster
                      if (discountAmount > 0) ...[
                        _buildSummaryRow(
                            "İndirim ${couponCode != null && couponCode.isNotEmpty ? '($couponCode)' : ''}",
                            "-₺${discountAmount.toStringAsFixed(2)}",
                            color: Colors.green
                        ),
                      ],

                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(thickness: 1)),

                      // Genel Toplam (Final Price)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("TOPLAM TUTAR", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          Text("₺${finalPrice.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.blue)),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- BUTONLAR ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))],
              ),
              child: SafeArea(child: _buildActionButtons(status)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value, {Color color = Colors.black87}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 14, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String status) {
    if (status == 'Sipariş Onayı Bekleniyor') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _showRejectModal,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Reddet"),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => updateStatus('Sipariş Hazırlanıyor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text("Siparişi Onayla", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    } else if (status == 'Sipariş Hazırlanıyor') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => updateStatus('Sipariş Yolda'),
          icon: const Icon(Icons.delivery_dining),
          label: const Text("Kuryeye Teslim Et / Yola Çıkar"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    } else if (status == 'Sipariş Yolda') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => updateStatus('Sipariş Teslim Edildi'),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text("Teslim Edildi Olarak Tamamla"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          "Sipariş Durumu: $status",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
        ),
      );
    }
  }
}