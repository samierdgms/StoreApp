import 'package:flutter/material.dart';
import 'dart:async';  // Timer kullanabilmek için import ediyoruz
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/coupon.dart';
import '../services/fee_service.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  Coupon? _appliedCoupon;

  // Başlangıçta default değerler
  double freeDeliveryThreshold = 1499.0;
  double deliveryFee = 29.99;
  double minimumOrder = 1000.0; // Minimum sipariş tutarı

  List<CartItem> get items => _items;
  Coupon? get appliedCoupon => _appliedCoupon;

  double get totalPrice => _items.fold(0, (sum, item) => sum + item.totalPrice);

  double get discount {
    if (_appliedCoupon == null || totalPrice < _appliedCoupon!.minAmount) return 0;

    if (_appliedCoupon!.type == 'percent') {
      return totalPrice * (_appliedCoupon!.value / 100);
    } else if (_appliedCoupon!.type == 'fixed') {
      return _appliedCoupon!.value;
    }

    return 0;
  }

  double get finalPrice => totalPrice - discount;

  double get grandTotal {

    if (finalPrice >= freeDeliveryThreshold) {
      return finalPrice;
    }
    return finalPrice + deliveryFee;
  }



  // Supabase'den güncel fee bilgilerini çekme
  Future<void> fetchFees() async {
    try {


      final fees = await FeeService.getFees();

      // Supabase'ten gelen verilerle güncelleme yapalım
      freeDeliveryThreshold = fees['free_delivery_amount'] ?? 1499.0;
      deliveryFee = fees['delivery_fee'] ?? 29.99;
      minimumOrder = fees['minimum_order_amount'] ?? 1000.0; // minimum_order_amount ekledik

      // Verilerin başarılı bir şekilde alındığını kontrol et


      notifyListeners();
    } catch (e) {
      print("Error fetching fees: $e");
    }
  }

  // Timer ile sürekli olarak fetchFees'i çağırmak
  void startFeeUpdateTimer() {
    Timer.periodic(Duration(minutes: 5), (timer) {
      fetchFees();  // Her 5 dakikada bir fetchFees fonksiyonu çağrılacak
    });
  }

  // CartProvider constructor
  CartProvider() {
    fetchFees();  // İlk başta fetchFees'i çağırıyoruz
    startFeeUpdateTimer();  // Timer'ı başlatıyoruz
  }
  bool get isMinimumMet => finalPrice >= minimumOrder;
  void addToCart(Product product) {
    if (!product.inStock) return; // ❗️ Stok kontrolü

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
}





