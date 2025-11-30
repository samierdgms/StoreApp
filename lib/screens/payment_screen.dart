import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import '../providers/cart_provider.dart';
import '../providers/market_provider.dart';
import '../services/order_service.dart';
import 'home_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // Controller'lar
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _orderNoteController = TextEditingController();

  String _selectedPaymentMethod = 'Kapıda Ödeme / Nakit';
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();

    // Market Limitlerini / Ücretlerini Güncelle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final marketId = Provider.of<MarketProvider>(context, listen: false).marketId;
      if (marketId != null) {
        Provider.of<CartProvider>(context, listen: false).fetchFees(marketId);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _orderNoteController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserInfo() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      if (mounted && response != null) {
        setState(() {
          _nameController.text = response['name'] ?? '';
          _surnameController.text = response['surname'] ?? '';
          _phoneController.text = response['phone_number'] ?? '';
          _addressController.text = response['address_line'] ?? ''; // Veritabanındaki kolon adı
          _cityController.text = response['city'] ?? '';
          _districtController.text = response['district'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Kullanıcı bilgisi çekme hatası: $e");
    }
  }

  // Kullanıcı adresini günceller (Sadece adresi güncelliyoruz, diğer bilgiler profil ayarlarından değişmeli)
  Future<void> _updateUserAddress(String userId) async {
    if (_addressController.text.trim().isNotEmpty) {
      await Supabase.instance.client.from('users').update({
        'address_line': _addressController.text.trim(),
      }).eq('id', userId);
    }
  }

  Future<void> _submitOrder() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final marketId = Provider.of<MarketProvider>(context, listen: false).marketId;
    final userId = Supabase.instance.client.auth.currentUser?.id;

    // Validasyonlar
    if (userId == null || marketId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Oturum veya market hatası!")));
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen açık adresinizi giriniz.")));
      return;
    }

    // Şehir/İlçe kontrolü (Önemli: Veritabanına boş gitmemeli)
    if (_cityController.text.isEmpty || _districtController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil bilgilerinizde Şehir/İlçe eksik. Lütfen profilinizi güncelleyin.")));
      return;
    }

    setState(() => _isProcessing = true);

    // --- SNAPSHOT MANTIĞI BURADA ---
    // Modelde bu alanların tanımlı olması gerekir.
    final order = Order(
      id: null,
      userId: userId,
      marketId: marketId,
      products: cart.items.map((item) => {
        'product_id': item.product.id,
        'title': item.product.name,
        'price': item.product.price,
        'quantity': item.quantity,
        'total': item.totalPrice,
        'unit': item.product.unit,
      }).toList(),
      totalPrice: cart.totalPrice,
      couponCode: cart.appliedCoupon?.code,
      discountAmount: cart.discount,
      finalPrice: cart.finalPrice,
      paymentMethod: _selectedPaymentMethod,
      status: 'Sipariş Onayı Bekleniyor',

      // Teslimat Snapshot Bilgileri
      deliveryAddress: _addressController.text.trim(),
      customerName: _nameController.text.trim(),       // YENİ
      customerSurname: _surnameController.text.trim(), // YENİ
      customerPhone: _phoneController.text.trim(),     // YENİ
      city: _cityController.text.trim(),               // YENİ
      district: _districtController.text.trim(),       // YENİ

      createdAt: DateTime.now(),
      deliveryFee: 0, // Gerekirse cartProvider'dan alınabilir
      orderNote: _orderNoteController.text.trim(),
    );

    try {
      // 1. Kullanıcının adresini users tablosunda güncelle (gelecek sefer için)
      await _updateUserAddress(userId);

      // 2. Siparişi oluştur
      await OrderService.createOrder(order, marketId);

      // 3. Sepeti temizle
      cart.clearCart();

      if (!mounted) return;

      // Başarı Diyalogu
      _showSuccessDialog();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sipariş oluşturulamadı: $e")));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.green, size: 40),
            ),
            const SizedBox(height: 20),
            const Text("Sipariş Alındı!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 10),
            const Text(
              "Siparişiniz başarıyla oluşturuldu. Durumunu siparişlerim sayfasından takip edebilirsiniz.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Tamam"),
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- UI Widget Yardımcıları ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 12.0),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, IconData? icon, bool isReadOnly = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        readOnly: isReadOnly,
        maxLines: maxLines,
        onTapOutside: (event) => FocusScope.of(context).unfocus(),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
          filled: true,
          fillColor: isReadOnly ? Colors.grey.shade100 : Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.green)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.green)));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Ödemeyi Tamamla', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Adres Bilgileri
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Teslimat Bilgileri'),
                  _buildTextField(label: 'Ad', controller: _nameController, icon: Icons.person, isReadOnly: true),
                  _buildTextField(label: 'Soyad', controller: _surnameController, icon: Icons.person, isReadOnly: true),
                  _buildTextField(label: 'Telefon', controller: _phoneController, icon: Icons.phone, isReadOnly: true),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(label: 'Şehir', controller: _cityController, isReadOnly: true)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildTextField(label: 'İlçe', controller: _districtController, isReadOnly: true)),
                    ],
                  ),
                  _buildTextField(label: 'Açık Adres (Düzenlenebilir)', controller: _addressController, icon: Icons.location_on, maxLines: 3),
                  _buildTextField(label: 'Sipariş Notu (Opsiyonel)', controller: _orderNoteController, icon: Icons.note_alt_outlined),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Ödeme Yöntemi
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Ödeme Yöntemi'),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('Kapıda Ödeme / Nakit', style: TextStyle(fontWeight: FontWeight.w500)),
                          secondary: const Icon(Icons.money, color: Colors.green),
                          value: 'Kapıda Ödeme / Nakit',
                          groupValue: _selectedPaymentMethod,
                          onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                          activeColor: Colors.green,
                        ),
                        const Divider(height: 1),
                        RadioListTile<String>(
                          title: const Text('Kapıda Ödeme / Kart', style: TextStyle(fontWeight: FontWeight.w500)),
                          secondary: const Icon(Icons.credit_card, color: Colors.blue),
                          value: 'Kapıda Ödeme / Kart',
                          groupValue: _selectedPaymentMethod,
                          onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 3. Alt Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ödenecek Tutar', style: TextStyle(color: Colors.grey, fontSize: 16)),
                Text('₺${cart.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (cart.isMinimumMet && !_isProcessing) ? _submitOrder : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  disabledBackgroundColor: Colors.green.withOpacity(0.5),
                ),
                child: _isProcessing
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Siparişi Tamamla', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}