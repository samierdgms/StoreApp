import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/order.dart';
import '../providers/cart_provider.dart';
import '../services/order_service.dart';
import 'home_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _orderNoteController = TextEditingController();  // Sipariş Notu

  String _selectedPaymentMethod = 'Nakit';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final response = await Supabase.instance.client
        .from('users')
        .select()
        .eq('id', userId)
        .single();

    if (response != null) {
      _nameController.text = response['name'] ?? '';
      _surnameController.text = response['surname'] ?? '';
      _phoneController.text = response['phone_number'] ?? '';
      _addressController.text = response['address_line'] ?? '';
      _cityController.text = response['city'] ?? '';
      _districtController.text = response['district'] ?? '';
    }

    setState(() => _isLoading = false);
  }

  Future<void> _updateUserAddress(String userId) async {
    await Supabase.instance.client.from('users').update({
      'address_line': _addressController.text.trim(),
    }).eq('id', userId);
  }

  Future<void> _submitOrder() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Giriş yapılmamış.")),
      );
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Teslimat adresi boş olamaz.")),
      );
      return;
    }

    final order = Order(
      id: DateTime.now().toIso8601String(),
      userId: userId,
      products: cart.items.map((item) => {
        'product_id': item.product.id,
        'title': item.product.name,
        'price': item.product.price,
        'quantity': item.quantity,
        'total': item.totalPrice,
      }).toList(),
      totalPrice: cart.totalPrice,
      couponCode: cart.appliedCoupon?.code,
      discountAmount: cart.discount,
      finalPrice: cart.finalPrice,
      paymentMethod: _selectedPaymentMethod,
      status: 'Sipariş Onayı Bekleniyor',
      deliveryAddress: _addressController.text.trim(),
      createdAt: DateTime.now(),
      deliveryFee: 0,
      orderNote: _orderNoteController.text.trim(),  // Sipariş notunu ekliyoruz
    );

    try {
      await _updateUserAddress(userId);
      await OrderService.createOrder(order);
      cart.clearCart();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.check_circle, color: Colors.green, size: 60),
                    SizedBox(height: 16),
                    Text("Siparişiniz alındı!",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
      );

      // 2 saniye sonra ana ekrana yönlendir
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sipariş başarısız: $e")),
      );
    }
  }

  Widget _buildReadonlyField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildEditableAddressField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _addressController,
        maxLines: 2,
        decoration: InputDecoration(
          labelText: 'Teslimat Adresi',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildOrderNoteField() {  // Sipariş Notu Alanı
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _orderNoteController,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'Sipariş Notu (Opsiyonel)',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ödeme')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildReadonlyField('Ad', _nameController),
            _buildReadonlyField('Soyad', _surnameController),
            _buildReadonlyField('Telefon', _phoneController),
            _buildReadonlyField('İlçe', _districtController),
            _buildReadonlyField('Şehir', _cityController),
            _buildEditableAddressField(),
            _buildOrderNoteField(),  // Sipariş Notu Alanı
            const Divider(height: 32),
            const Text('Ödeme Yöntemi', style: TextStyle(fontWeight: FontWeight.bold)),
            ListTile(
              title: const Text('Kapıda Nakit'),
              leading: Radio(
                value: 'Kapıda Ödeme / Nakit',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
              ),
            ),
            ListTile(
              title: const Text('Kapıda Kart'),
              leading: Radio(
                value: 'Kapıda Ödeme / Kart',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 16, bottom: 12),
              child: Text(
                'Sipariş onayı için aranabilirsiniz.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const Divider(height: 32),
            Text(
              'Sepetteki Ürünler: ₺${cart.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'İndirim: ₺${cart.discount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Kargo Ücreti: ₺${cart.finalPrice >= cart.freeDeliveryThreshold ? '0.00' : cart.deliveryFee.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Toplam Ücret: ₺${cart.grandTotal.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: cart.isMinimumMet ? _submitOrder : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Siparişi Tamamla', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
