import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/coupon.dart';
import '../services/fee_service.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  Coupon? _appliedCoupon;

  // Varsayılan değerler
  double freeDeliveryThreshold = 1499.0;
  double deliveryFee = 29.99;
  double minimumOrder = 1000.0;

  List<CartItem> get items => _items;
  Coupon? get appliedCoupon => _appliedCoupon;

  // Ham sepet tutarı (Kuponsuz)
  double get totalPrice => _items.fold(0, (sum, item) => sum + item.totalPrice);

  // İndirim Tutarı
  double get discount {
    // Kupon yoksa veya sepet tutarı kupon limitinin altına düştüyse indirim 0 olsun
    if (_appliedCoupon == null || totalPrice < _appliedCoupon!.minAmount) return 0;

    if (_appliedCoupon!.type == 'percent') {
      return totalPrice * (_appliedCoupon!.value / 100);
    } else if (_appliedCoupon!.type == 'fixed') {
      return _appliedCoupon!.value;
    }

    return 0;
  }

  // İndirim düştükten sonraki ürün tutarı (Teslimat hariç)
  double get finalPrice => totalPrice - discount;

  // Genel Toplam (Teslimat dahil)
  double get grandTotal {
    if (finalPrice >= freeDeliveryThreshold) {
      return finalPrice;
    }
    return finalPrice + deliveryFee;
  }

  // Minimum tutar karşılandı mı? (İndirimli tutar üzerinden kontrol edilir)
  bool get isMinimumMet => finalPrice >= minimumOrder;

  // ✅ GÜNCELLENDİ: Artık marketId parametresi alıyor
  Future<void> fetchFees(String marketId) async {
    try {
      final fees = await FeeService.getFees(marketId);

      freeDeliveryThreshold = fees['free_delivery_amount'] ?? 1499.0;
      deliveryFee = fees['delivery_fee'] ?? 29.99;
      minimumOrder = fees['minimum_order_amount'] ?? 1000.0;

      notifyListeners();
    } catch (e) {
      print("Error fetching fees: $e");
    }
  }

  CartProvider() {
    // Constructor
  }

  void addToCart(Product product) {
    if (!product.inStock) return;

    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void removeFromCart(Product product) {
    _items.removeWhere((item) => item.product.id == product.id);

    // Eğer sepet boşaldıysa kuponu da sıfırla
    if (_items.isEmpty) {
      _appliedCoupon = null;
    }

    notifyListeners();
  }

  void increaseQuantity(Product product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      _items[index].quantity++;
      notifyListeners();
    }
  }

  void decreaseQuantity(Product product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index != -1 && _items[index].quantity > 1) {
      _items[index].quantity--;
    } else {
      removeFromCart(product);
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _appliedCoupon = null;
    notifyListeners();
  }

  void applyCoupon(Coupon coupon) {
    _appliedCoupon = coupon;
    notifyListeners();
  }

  // ✅ EKLENDİ: Kuponu kaldırma metodu
  void removeCoupon() {
    _appliedCoupon = null;
    notifyListeners();
  }
}