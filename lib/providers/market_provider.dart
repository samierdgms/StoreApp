import 'package:flutter/material.dart';

class MarketProvider with ChangeNotifier {
  String? _currentMarketId;
  String? _marketName;

  // Şu anki market ID'sini al
  String? get marketId => _currentMarketId;
  String? get marketName => _marketName;

  // Market seçildiğinde veya giriş yapıldığında bunu çağıracağız
  void setMarket(String id, String name) {
    _currentMarketId = id;
    _marketName = name;
    notifyListeners(); // Tüm uygulamaya "Market değişti!" diye haber ver
  }

  // Çıkış yapılırsa marketi unut
  void clearMarket() {
    _currentMarketId = null;
    _marketName = null;
    notifyListeners();
  }
}