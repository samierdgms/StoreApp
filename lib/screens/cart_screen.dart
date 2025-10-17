import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storeappp/screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/cart_provider.dart';
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
    _loadFees();
  }

  Future<void> _loadFees() async {
    try {
      final fees = await FeeService.getFees();
      setState(() {
        _fees = fees;
      });
    } catch (e) {
      debugPrint('Fee fetch error: $e');
      setState(() {
        _fees = {
          'delivery_fee': 29.99,
          'free_delivery_amount': 1499.0,
          'minimum_order_amount': 1000.0,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    if (_fees == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final deliveryFee = cart.deliveryFee;
    final freeDeliveryAmount = cart.freeDeliveryThreshold;
    final minimumOrderAmount = cart.minimumOrder;


    final isMinimumMet = cart.isMinimumMet;
    final isCartEmpty = cart.items.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sepetim'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // Ücretsiz teslimat bildirimi
          Container(
            width: double.infinity,
            color: Colors.green.shade100,
            padding: const EdgeInsets.all(12),
            child: Text(
              '🚚 ${freeDeliveryAmount.toStringAsFixed(0)} TL ve üzeri siparişlerde getirme ücreti alınmaz!',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Sepet ürünleri listesi veya boş sepet
          Expanded(
            child: isCartEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Sepetiniz boş'),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    },
                    icon: const Icon(Icons.shopping_bag),
                    label: const Text('Alışverişe Başla'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: const Color(0xFFFFC067),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (_, i) {
                final item = cart.items[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Image.network(
                          item.product.imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.name,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.totalPrice.toStringAsFixed(2)} ₺',
                                style: const TextStyle(fontSize: 14, color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => cart.decreaseQuantity(item.product),
                            ),
                            Text('${item.quantity}', style: const TextStyle(fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => cart.increaseQuantity(item.product),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => cart.removeFromCart(item.product),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Alt bilgiler
          Padding(
            padding: const EdgeInsets.all(16),
            child: IgnorePointer(
              ignoring: isCartEmpty,
              child: Opacity(
                opacity: isCartEmpty ? 0.4 : 1.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'İndirim Kodu',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final code = _codeController.text.trim();
                        final coupon = await CouponService.validateCoupon(code);
                        setState(() {
                          if (coupon == null) {
                            _couponMessage = '❌ Geçersiz kod!';
                          } else if (cart.totalPrice < coupon.minAmount) {
                            _couponMessage =
                            '❌ Minimum tutar: ${coupon.minAmount.toStringAsFixed(0)} ₺';
                          } else {
                            cart.applyCoupon(coupon);
                            _couponMessage = '✅ İndirim uygulandı!';
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: const Color(0xFFFFC067),
                      ),
                      child: const Text('Kodu Uygula'),
                    ),
                    if (_couponMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _couponMessage!,
                          style: TextStyle(
                            color: _couponMessage!.startsWith('✅')
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('İndirim:'),
                        Text('-${cart.discount.toStringAsFixed(2)} ₺'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (cart.finalPrice<cart.freeDeliveryThreshold)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Teslimat Ücreti:'),
                          Text('${deliveryFee.toStringAsFixed(2)} ₺'),
                        ],
                      ),
                    if (cart.finalPrice>cart.freeDeliveryThreshold)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('Teslimat Ücreti:'),
                          Text('Getirmesi ücretsiz!',
                              style: TextStyle(
                                  color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Toplam:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          '${(cart.grandTotal).toStringAsFixed(2)} ₺',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (!isMinimumMet && !isCartEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '⚠️ Minimum sipariş tutarı ${minimumOrderAmount.toStringAsFixed(0)} TL\'dir.',
                          style: const TextStyle(
                              color: Colors.red, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.payment),
                      label: const Text('Ödeme Yap'),
                      onPressed: isMinimumMet && !isCartEmpty
                          ? () async {
                        // Oturum kontrolü
                        final session = Supabase.instance.client.auth.currentSession;

                        if (session == null) {
                          // Kullanıcı oturum açmamışsa, dinamik uyarı penceresini göster
                          showDialog(
                            context: context,
                            barrierDismissible: false, // Kullanıcı uyarıyı kapatamasın
                            builder: (BuildContext context) {
                              return Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        size: 60,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(height: 20),
                                      const Text(
                                        'Ödeme işlemi için giriş yapmalısınız',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );

                          // 2 saniye sonra dialog penceresini kapat ve login sayfasına yönlendir
                          Future.delayed(const Duration(seconds: 2), () {
                            Navigator.pop(context); // Dialog'u kapat
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => HomeScreen()),
                            );
                          });
                        } else {
                          // Oturum açıksa ödeme ekranına yönlendir
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PaymentScreen()),
                          );
                        }
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: const Color(0xFFFFC067),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
