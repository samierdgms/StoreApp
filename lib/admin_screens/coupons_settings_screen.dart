import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/coupon_service.dart';
import '../models/coupon.dart';
import '../providers/market_provider.dart';

class CouponsSettingsScreen extends StatefulWidget {
  const CouponsSettingsScreen({super.key});

  @override
  _CouponsSettingsScreenState createState() => _CouponsSettingsScreenState();
}

class _CouponsSettingsScreenState extends State<CouponsSettingsScreen> {
  List<Coupon> _coupons = [];
  List<Coupon> _activeCoupons = [];
  List<Coupon> _inactiveCoupons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCoupons();
    });
  }

  Future<void> _fetchCoupons() async {
    final marketId = Provider.of<MarketProvider>(context, listen: false).marketId;
    if (marketId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final coupons = await CouponService.fetchAllCoupons(marketId);
      final activeCoupons = <Coupon>[];
      final inactiveCoupons = <Coupon>[];

      for (var coupon in coupons) {
        if (coupon.isActive) {
          activeCoupons.add(coupon);
        } else {
          inactiveCoupons.add(coupon);
        }
      }

      if (mounted) {
        setState(() {
          _coupons = coupons;
          _activeCoupons = activeCoupons;
          _inactiveCoupons = inactiveCoupons;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print('Error: $e');
    }
  }

  // --- DİYALOGLAR ---

  void _showEditCouponDialog(Coupon coupon) {
    String selectedType2 = coupon.type;
    final valueController = TextEditingController(text: coupon.value.toString());
    final minAmountController = TextEditingController(text: coupon.minAmount.toString());
    final descriptionController = TextEditingController(text: coupon.description);
    bool isActive = coupon.isActive;

    final currentMarketId = Provider.of<MarketProvider>(context, listen: false).marketId ?? 'Bilinmiyor';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Column(
            children: [
              const Icon(Icons.edit_note, color: Colors.blue, size: 40),
              const SizedBox(height: 10),
              Text('Düzenle: ${coupon.code}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildReadOnlyField("Kupon Kodu", coupon.code, Icons.qr_code),
                const SizedBox(height: 12),
                _buildDropdownField(
                  "İndirim Türü",
                  selectedType2,
                  const [
                    DropdownMenuItem(value: 'percent', child: Text('Yüzde (%)')),
                    DropdownMenuItem(value: 'fixed', child: Text('Sabit Tutar (₺)')),
                  ],
                      (val) => setState(() => selectedType2 = val!),
                ),
                const SizedBox(height: 12),
                _buildTextField("Değer", valueController, Icons.numbers, isNumber: true),
                const SizedBox(height: 12),
                _buildTextField("Min. Sepet Tutarı", minAmountController, Icons.shopping_cart_outlined, isNumber: true),
                const SizedBox(height: 12),
                _buildTextField("Açıklama", descriptionController, Icons.description),
                const SizedBox(height: 12),
                _buildDropdownField(
                  "Durum",
                  isActive,
                  const [
                    DropdownMenuItem(value: true, child: Text('Aktif 🟢')),
                    DropdownMenuItem(value: false, child: Text('Pasif 🔴')),
                  ],
                      (val) => setState(() => isActive = val!),
                ),
                const SizedBox(height: 20),
                _buildReadOnlyField("Market ID (Sistem)", currentMarketId, Icons.lock),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () async {
                final marketId = Provider.of<MarketProvider>(context, listen: false).marketId;
                if (marketId == null) return;

                final updatedCoupon = Coupon(
                  code: coupon.code,
                  type: selectedType2,
                  value: double.tryParse(valueController.text.trim()) ?? 0.0,
                  minAmount: double.tryParse(minAmountController.text.trim()) ?? 0.0,
                  description: descriptionController.text.trim(),
                  isActive: isActive,
                  marketId: marketId,
                );

                try {
                  await CouponService.updateCoupon(updatedCoupon);
                  _fetchCoupons();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kupon güncellendi ✅')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              child: const Text('Güncelle'),
            ),
          ],
        );
      },
    );
  }

  void _showAddCouponDialog() {
    final codeController = TextEditingController();
    String selectedType = 'percent';
    final valueController = TextEditingController();
    final minAmountController = TextEditingController();
    final descriptionController = TextEditingController();

    final currentMarketId = Provider.of<MarketProvider>(context, listen: false).marketId ?? 'Bilinmiyor';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Column(
            children: [
              Icon(Icons.add_circle_outline, color: Colors.green, size: 40),
              SizedBox(height: 10),
              Text('Yeni Kupon Ekle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField("Kupon Kodu", codeController, Icons.vpn_key, hint: "Örn: YAZ2024"),
                const SizedBox(height: 12),
                _buildDropdownField(
                  "İndirim Türü",
                  selectedType,
                  const [
                    DropdownMenuItem(value: 'percent', child: Text('Yüzde (%)')),
                    DropdownMenuItem(value: 'fixed', child: Text('Sabit Tutar (₺)')),
                  ],
                      (val) => setState(() => selectedType = val!),
                ),
                const SizedBox(height: 12),
                _buildTextField("Değer", valueController, Icons.numbers, isNumber: true, hint: "Örn: 10"),
                const SizedBox(height: 12),
                _buildTextField("Min. Sepet Tutarı", minAmountController, Icons.shopping_cart_outlined, isNumber: true, hint: "Örn: 100"),
                const SizedBox(height: 12),
                _buildTextField("Açıklama", descriptionController, Icons.description, hint: "Kampanya detayları..."),
                const SizedBox(height: 20),
                _buildReadOnlyField("Market ID (Sistem)", currentMarketId, Icons.lock),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () async {
                final code = codeController.text.trim();
                final value = double.tryParse(valueController.text.trim()) ?? 0.0;
                final minAmount = double.tryParse(minAmountController.text.trim()) ?? 0.0;
                final description = descriptionController.text.trim();
                final marketId = Provider.of<MarketProvider>(context, listen: false).marketId;

                if (marketId == null || code.isEmpty || value <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen bilgileri eksiksiz girin.')));
                  return;
                }

                final newCoupon = Coupon(
                  code: code,
                  type: selectedType,
                  value: value,
                  minAmount: minAmount,
                  description: description,
                  isActive: true,
                  marketId: marketId,
                );

                try {
                  await CouponService.addCoupon(newCoupon, marketId);
                  _fetchCoupons();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kupon eklendi ✅')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
  }

  // --- YARDIMCI WIDGETLAR ---

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false, String? hint}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      enabled: false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[200],
      ),
    );
  }

  Widget _buildDropdownField<T>(String label, T value, List<DropdownMenuItem<T>> items, ValueChanged<T?> onChanged) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 4.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
        ],
      ),
    );
  }

  Widget _buildCouponCard(Coupon coupon) {
    final isPercent = coupon.type == 'percent';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: coupon.isActive ? Colors.green.shade50 : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.local_offer,
            color: coupon.isActive ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(
          coupon.code,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: coupon.isActive ? Colors.black87 : Colors.grey,
            decoration: coupon.isActive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(coupon.description, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(
              'Min: ${coupon.minAmount.toStringAsFixed(0)} ₺',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isPercent ? Colors.blue.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isPercent ? Colors.blue.shade200 : Colors.orange.shade200),
              ),
              child: Text(
                isPercent ? '%${coupon.value.toStringAsFixed(0)}' : '-${coupon.value.toStringAsFixed(0)} ₺',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPercent ? Colors.blue.shade700 : Colors.orange.shade800
                ),
              ),
            ),
            const SizedBox(height: 4),
            Icon(Icons.edit, size: 16, color: Colors.grey[400]),
          ],
        ),
        onTap: () => _showEditCouponDialog(coupon),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Kupon Ayarları', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCouponDialog,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Yeni Kupon"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_activeCoupons.isEmpty && _inactiveCoupons.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: Column(
                    children: [
                      Icon(Icons.confirmation_number_outlined, size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text("Henüz kupon oluşturulmamış.", style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                ),
              ),

            if (_activeCoupons.isNotEmpty) ...[
              _buildSectionHeader('Aktif Kuponlar', Colors.green),
              ..._activeCoupons.map(_buildCouponCard),
            ],

            if (_inactiveCoupons.isNotEmpty) ...[
              _buildSectionHeader('Pasif / Geçmiş Kuponlar', Colors.grey),
              ..._inactiveCoupons.map(_buildCouponCard),
            ],

            const SizedBox(height: 80), // FAB için boşluk
          ],
        ),
      ),
    );
  }
}