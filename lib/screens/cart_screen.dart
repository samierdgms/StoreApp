import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/cart_provider.dart';
import '../providers/market_provider.dart';
import '../services/coupon_service.dart';
import '../services/fee_service.dart';
import 'home_screen.dart';
import 'payment_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _codeController = TextEditingController();
  String? _couponMessage;
  Map<String, double>? _fees;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFees();
    });
  }

  Future<void> _loadFees() async {
    final marketId = Provider.of<MarketProvider>(context, listen: false).marketId;
    if (marketId == null) return;

    try {
      final fees = await FeeService.getFees(marketId);
      if (mounted) {
        Provider.of<CartProvider>(context, listen: false).fetchFees(marketId);
        setState(() {
          _fees = fees;
        });
      }
    } catch (e) {
      debugPrint('Fee fetch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    if (_fees == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    final deliveryFee = cart.deliveryFee;
    final freeDeliveryAmount = cart.freeDeliveryThreshold;
    final minimumOrderAmount = cart.minimumOrder;
    final isMinimumMet = cart.isMinimumMet;
    final isCartEmpty = cart.items.isEmpty;
    final bool hasCoupon = cart.discount > 0;

    // Kupon sonrası saf ürün tutarı (Teslimat ücreti hariç)
    final double productTotalAfterDiscount = cart.totalPrice - cart.discount;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Sepetim', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (!isCartEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: "Sepeti Boşalt",
              onPressed: () => cart.clearCart(),
            )
        ],
      ),
      body: Column(
        children: [
          // Ücretsiz Kargo Progress Bar / Bildirimi
          if (!isCartEmpty)
            Container(
              width: double.infinity,
              color: cart.finalPrice >= freeDeliveryAmount ? Colors.green.shade50 : Colors.blue.shade50,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    cart.finalPrice >= freeDeliveryAmount ? Icons.check_circle : Icons.local_shipping_outlined,
                    color: cart.finalPrice >= freeDeliveryAmount ? Colors.green : Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      cart.finalPrice >= freeDeliveryAmount
                          ? 'Tebrikler! Teslimat ücreti bizden.'
                          : 'Sepete ${(freeDeliveryAmount - cart.finalPrice).toStringAsFixed(2)} TL daha ekle, kargo bedava olsun!',
                      style: TextStyle(
                          color: cart.finalPrice >= freeDeliveryAmount ? Colors.green.shade800 : Colors.blue.shade800,
                          fontWeight: FontWeight.w600,
                          fontSize: 13
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Sepet Ürünleri
          Expanded(
            child: isCartEmpty
                ? _buildEmptyCartView()
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cart.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final item = cart.items[i];
                return _buildCartItem(cart, item);
              },
            ),
          ),

          // Alt Panel (Kupon ve Özet)
          if (!isCartEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -5)),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // --- KUPON ALANI ---
                    if (hasCoupon)
                      _buildActiveCouponCard(cart) // Kupon varsa bunu göster
                    else
                      _buildCouponInputRow(cart), // Kupon yoksa input göster

                    if (_couponMessage != null && !hasCoupon)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _couponMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // --- ÖZET ALANI ---
                    _buildSummaryRow('Ara Toplam', '₺${cart.totalPrice.toStringAsFixed(2)}'),

                    if (cart.discount > 0) ...[
                      _buildSummaryRow('Kupon İndirimi', '-₺${cart.discount.toStringAsFixed(2)}', color: Colors.green),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Divider(height: 1, indent: 20, endIndent: 20, color: Colors.grey),
                      ),
                      // İSTEĞİNİZ: Kupon sonrası ara tutar
                      _buildSummaryRow(
                          'İndirimli Ürün Tutarı',
                          '₺${productTotalAfterDiscount.toStringAsFixed(2)}',
                          color: Colors.black87,
                          isBold: true
                      ),
                    ],

                    _buildSummaryRow(
                        'Teslimat Ücreti',
                        cart.finalPrice >= freeDeliveryAmount ? 'Ücretsiz' : '₺${deliveryFee.toStringAsFixed(2)}',
                        color: cart.finalPrice >= freeDeliveryAmount ? Colors.green : Colors.black
                    ),

                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('GENEL TOPLAM', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('₺${cart.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black)),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Buton ve Uyarılar
                    if (!isMinimumMet)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200)
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.orange),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Minimum sepet tutarı ₺${minimumOrderAmount.toStringAsFixed(0)} olmalıdır.',
                                style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final session = Supabase.instance.client.auth.currentSession;
                            if (session == null) {
                              _showAuthDialog(context);
                            } else {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentScreen()));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                            shadowColor: Colors.green.withOpacity(0.4),
                          ),
                          child: const Text('Sepeti Onayla', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER METHODS ---

  // 1. Kupon Giriş Alanı (Henüz kupon yoksa)
  Widget _buildCouponInputRow(CartProvider cart) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.local_activity_outlined, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                hintText: 'İndirim Kodu',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final code = _codeController.text.trim();
              final marketId = Provider.of<MarketProvider>(context, listen: false).marketId;
              if (marketId != null && code.isNotEmpty) {
                final coupon = await CouponService.validateCoupon(code, marketId);
                setState(() {
                  if (coupon == null) {
                    _couponMessage = 'Geçersiz Kod';
                  } else if (cart.totalPrice < coupon.minAmount) {
                    _couponMessage = 'Sepet tutarı min ${coupon.minAmount}₺ olmalı';
                  } else {
                    cart.applyCoupon(coupon);
                    _couponMessage = null;
                    _codeController.clear(); // Başarılı olunca temizle
                  }
                });
              }
            },
            child: const Text('UYGULA', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 2. Aktif Kupon Kartı (İptal butonu olan)
  Widget _buildActiveCouponCard(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Kupon Uygulandı",
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  "-₺${cart.discount.toStringAsFixed(2)} indirim",
                  style: TextStyle(color: Colors.green.shade700, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                // CartProvider'da removeCoupon metodunuz olduğunu varsayıyoruz
                // Eğer yoksa: cart.applyCoupon(null) veya benzeri bir mantık kullanın
                try {
                  // ignore: avoid_dynamic_calls
                  (cart as dynamic).removeCoupon();
                } catch (e) {
                  // Fallback eğer metod yoksa (geçici çözüm)
                  debugPrint("Lütfen CartProvider'a removeCoupon ekleyin.");
                }
                _couponMessage = null;
              });
            },
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: "Kuponu Kaldır",
          )
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value, {Color color = Colors.black54, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.black54, fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildEmptyCartView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          Text('Sepetiniz şu an boş', style: TextStyle(color: Colors.grey[800], fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Lezzetli ürünlerimizi keşfetmeye başla!', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 5,
              shadowColor: Colors.green.withOpacity(0.4),
            ),
            child: const Text('Alışverişe Başla', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartProvider cart, dynamic item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              item.product.imageUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (ctx, error, stackTrace) =>
                  Container(width: 70, height: 70, color: Colors.grey[100], child: const Icon(Icons.image_not_supported, color: Colors.grey)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                Text(item.product.unit, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 4),
                Text('₺${item.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => cart.decreaseQuantity(item.product),
                  child: const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.remove, size: 16)),
                ),
                Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                InkWell(
                  onTap: () => cart.increaseQuantity(item.product),
                  child: const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.add, size: 16, color: Colors.green)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAuthDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Giriş Yapın"),
        content: const Text("Sipariş vermek için lütfen giriş yapın veya kayıt olun."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Giriş Yap"),
          )
        ],
      ),
    );
  }
}