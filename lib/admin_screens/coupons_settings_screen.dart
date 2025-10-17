import 'package:flutter/material.dart';
import 'package:storeappp/services/coupon_service.dart';
import 'package:storeappp/models/coupon.dart';

class CouponsSettingsScreen extends StatefulWidget {
  const CouponsSettingsScreen({super.key});

  @override
  _CouponsSettingsScreenState createState() => _CouponsSettingsScreenState();
}

class _CouponsSettingsScreenState extends State<CouponsSettingsScreen> {
  List<Coupon> _coupons = [];
  List<Coupon> _activeCoupons = [];
  List<Coupon> _inactiveCoupons = [];

  @override
  void initState() {
    super.initState();
    _fetchCoupons();
  }

  Future<void> _fetchCoupons() async {
    try {
      final coupons = await CouponService.fetchAllCoupons();
      final activeCoupons = <Coupon>[];
      final inactiveCoupons = <Coupon>[];

      for (var coupon in coupons) {
        if (coupon.isActive) {
          activeCoupons.add(coupon);
        } else {
          inactiveCoupons.add(coupon);
        }
      }

      setState(() {
        _coupons = coupons;
        _activeCoupons = activeCoupons;
        _inactiveCoupons = inactiveCoupons;
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  void _showEditCouponDialog(Coupon coupon) {
    String selectedType2 = coupon.type;  // Kuponun mevcut türü
    final typeController = TextEditingController(text: coupon.type);
    final valueController = TextEditingController(text: coupon.value.toString());
    final minAmountController = TextEditingController(text: coupon.minAmount.toString());
    final descriptionController = TextEditingController(text: coupon.description);
    bool isActive = coupon.isActive;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Kupon Düzenle: ${coupon.code}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  enabled: false,
                  decoration: const InputDecoration(labelText: 'Kupon Kodu (değiştirilemez)'),
                  controller: TextEditingController(text: coupon.code),
                ),
                DropdownButtonFormField<String>(
                  value: selectedType2,
                  items: const [
                    DropdownMenuItem(value: 'percent', child: Text('Yüzde')),
                    DropdownMenuItem(value: 'fixed', child: Text('Sabit')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedType2 = value;
                      });
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Tür'),
                ),
                TextField(
                  controller: valueController,
                  decoration: const InputDecoration(labelText: 'Değer'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: minAmountController,
                  decoration: const InputDecoration(labelText: 'Minimum Tutar'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Açıklama'),
                ),
                DropdownButtonFormField<bool>(
                  value: isActive,
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Aktif')),
                    DropdownMenuItem(value: false, child: Text('Pasif')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        isActive = value;
                      });
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Durum'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                final updatedCoupon = Coupon(
                  code: coupon.code,
                  type: selectedType2,
                  value: double.tryParse(valueController.text.trim()) ?? 0.0,
                  minAmount: double.tryParse(minAmountController.text.trim()) ?? 0.0,
                  description: descriptionController.text.trim(),
                  isActive: isActive,
                );

                try {
                  await CouponService.updateCoupon(updatedCoupon);
                  _fetchCoupons();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kupon başarıyla güncellendi.')),
                  );
                } catch (e) {
                  print('Kupon güncellenemedi: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Kupon güncellenemedi: $e')),
                  );
                }
              },
              child: const Text('Güncelle'),
            ),
          ],
        );
      },
    );
  }

  void _showAddCouponDialog() {
    final codeController = TextEditingController();
    String selectedType = 'percent'; // Default
    final valueController = TextEditingController();
    final minAmountController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Yeni Kupon Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'Kupon Kodu'),
                ),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: const [
                    DropdownMenuItem(value: 'percent', child: Text('Yüzde')),
                    DropdownMenuItem(value: 'fixed', child: Text('Sabit')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedType = value;
                      });
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Tür'),
                ),
                TextField(
                  controller: valueController,
                  decoration: const InputDecoration(labelText: 'Değer'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: minAmountController,
                  decoration: const InputDecoration(labelText: 'Minimum Tutar'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Açıklama'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                final code = codeController.text.trim();
                final value = double.tryParse(valueController.text.trim()) ?? 0.0;
                final minAmount = double.tryParse(minAmountController.text.trim()) ?? 0.0;
                final description = descriptionController.text.trim();

                if (code.isEmpty || value <= 0 || minAmount < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen tüm alanları doğru şekilde doldurun.')),
                  );
                  return;
                }

                final newCoupon = Coupon(
                  code: code,
                  type: selectedType,
                  value: value,
                  minAmount: minAmount,
                  description: description,
                  isActive: true,
                );

                try {
                  await CouponService.addCoupon(newCoupon);
                  _fetchCoupons();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kupon başarıyla eklendi.')),
                  );
                } catch (e) {
                  print('Kupon eklenemedi: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Kupon eklenemedi: $e')),
                  );
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kupon Ayarları'),
      ),
      body: ListView(
        children: [
          ExpansionTile(
            title: const Text('Aktif Kuponlar'),
            children: _activeCoupons.isEmpty
                ? [const ListTile(title: Text('Aktif kupon bulunmamaktadır.'))]
                : _activeCoupons
                .map((coupon) => ListTile(
              title: Text(coupon.code),
              subtitle: Text(coupon.description),
              trailing: Icon(
                coupon.isActive ? Icons.check : Icons.close,
                color: coupon.isActive ? Colors.green : Colors.red,
              ),
              onTap: () => _showEditCouponDialog(coupon),
            ))
                .toList(),
          ),
          ExpansionTile(
            title: const Text('Pasif Kuponlar'),
            children: _inactiveCoupons.isEmpty
                ? [const ListTile(title: Text('Pasif kupon bulunmamaktadır.'))]
                : _inactiveCoupons
                .map((coupon) => ListTile(
              title: Text(coupon.code),
              subtitle: Text(coupon.description),
              trailing: Icon(
                coupon.isActive ? Icons.check : Icons.close,
                color: coupon.isActive ? Colors.green : Colors.red,
              ),
              onTap: () => _showEditCouponDialog(coupon),
            ))
                .toList(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _showAddCouponDialog,
              child: const Text('Yeni Kupon Ekle'),
            ),
          ),
        ],
      ),
    );
  }
}
