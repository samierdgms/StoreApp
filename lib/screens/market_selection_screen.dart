import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../providers/market_provider.dart';
import '../providers/cart_provider.dart';
import 'home_screen.dart';

// Marker'ları temsil eden MarketLocation sınıfı
class MarketLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final bool isActive;
  double distance = 0.0;

  MarketLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.isActive,
  });

  factory MarketLocation.fromMap(Map<String, dynamic> map) {
    return MarketLocation(
      id: map['id'],
      name: map['name'] ?? 'Bilinmeyen Market',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      isActive: map['is_active'] ?? false,
    );
  }

  double get calculatedDistance => distance;
}

class MarketSelectionScreen extends StatefulWidget {
  const MarketSelectionScreen({super.key});

  @override
  State<MarketSelectionScreen> createState() => _MarketSelectionScreenState();
}

class _MarketSelectionScreenState extends State<MarketSelectionScreen> with WidgetsBindingObserver {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  String _statusMessage = 'Konum izni bekleniyor...';

  // İzin Durumu Değişkenleri
  bool _permissionDeniedForever = false;
  bool _locationServiceDisabled = false;

  List<MarketLocation> _markets = [];

  // Harita ve Konum Değişkenleri
  final MapController _mapController = MapController();
  Position? _currentPosition;
  static const LatLng _initialCenter = LatLng(38.4237, 27.1428);
  LatLng _mapCenter = _initialCenter;
  double _mapZoom = 12.0;

  @override
  void initState() {
    super.initState();
    // Uygulama arka plandan öne gelince (ayarlardan dönünce) kontrol etmek için observer ekliyoruz
    WidgetsBinding.instance.addObserver(this);
    _checkAndFetchLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Kullanıcı ayarlara gidip geri döndüğünde durumu tekrar kontrol et
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndFetchLocation();
    }
  }

  // --- KONUM YÖNETİMİ ---
  Future<void> _checkAndFetchLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _permissionDeniedForever = false;
        _locationServiceDisabled = false;
      });
    }

    // 1. Servis Kontrolü (GPS Açık mı?)
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Konum servisleri kapalı.';
          _locationServiceDisabled = true; // Butonu göstermek için
          _isLoading = false;
        });
      }
      await _fetchMarkets(_initialCenter.latitude, _initialCenter.longitude);
      return;
    }

    // 2. İzin Kontrolü
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _statusMessage = 'Konum izni reddedildi. Varsayılan sıralama yapılıyor.';
            _isLoading = false;
          });
        }
        await _fetchMarkets(_initialCenter.latitude, _initialCenter.longitude);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Konum izni kalıcı olarak engellendi.';
          _permissionDeniedForever = true; // Ayarlar butonunu göstermek için
          _isLoading = false;
        });
      }
      await _fetchMarkets(_initialCenter.latitude, _initialCenter.longitude);
      return;
    }

    // 3. Her şey yolunda, konumu al
    if (mounted) setState(() => _statusMessage = 'Konum alınıyor...');
    await _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _mapCenter = LatLng(position.latitude, position.longitude);
          _mapZoom = 14.0;
          _statusMessage = 'Konumunuz alındı.';
        });

        _mapController.move(_mapCenter, _mapZoom);
        await _fetchMarkets(position.latitude, position.longitude);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = 'Konum hatası. Varsayılan merkez kullanılıyor.');
      }
      await _fetchMarkets(_initialCenter.latitude, _initialCenter.longitude);
    }
  }

  // --- VERİ VE HESAPLAMA ---
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  Future<void> _fetchMarkets(double userLat, double userLon) async {
    try {
      final response = await _supabase
          .from('markets')
          .select('*')
          .eq('is_active', true);

      final rawMarkets = List<Map<String, dynamic>>.from(response);
      final marketList = rawMarkets.map((map) => MarketLocation.fromMap(map)).toList();

      for (var market in marketList) {
        market.distance = _calculateDistance(
          userLat,
          userLon,
          market.latitude,
          market.longitude,
        );
      }

      marketList.sort((a, b) => a.distance.compareTo(b.distance));

      if (mounted) {
        setState(() {
          _markets = marketList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Marketler çekilemedi: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectMarket(String id, String name) {
    Provider.of<MarketProvider>(context, listen: false).setMarket(id, name);
    Provider.of<CartProvider>(context, listen: false).clearCart();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  // --- ANA WIDGET ---
  @override
  Widget build(BuildContext context) {
    final List<Marker> mapMarkers = _markets.map((market) => Marker(
      point: LatLng(market.latitude, market.longitude),
      width: 80,
      height: 80,
      child: GestureDetector(
        onTap: market.isActive ? () => _selectMarket(market.id, market.name) : null,
        child: Column(
          children: [
            Icon(
              Icons.storefront,
              color: market.isActive ? Colors.green : Colors.grey,
              size: 30,
            ),
            Text(
              market.name.split(' ').first,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: market.isActive ? Colors.black : Colors.grey,
                backgroundColor: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    )).toList();

    if (_currentPosition != null) {
      mapMarkers.add(
          Marker(
            point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            width: 60,
            height: 60,
            child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 35),
          )
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yakındaki Marketler'),
        centerTitle: true,
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _checkAndFetchLocation,
            tooltip: "Konumu Yenile",
          )
        ],
      ),
      body: Column(
        children: [
          // 1. HARİTA
          Container(
            height: 300,
            color: Colors.grey[200],
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _mapCenter,
                    initialZoom: _mapZoom,
                    onTap: (_, __) {}, // Tıklama
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.marketapp.store',
                    ),
                    MarkerLayer(markers: mapMarkers),
                  ],
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black12,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),

          // 2. DURUM MESAJI VE AYAR BUTONLARI
          if ((_permissionDeniedForever || _locationServiceDisabled) && !_isLoading)
            Container(
              width: double.infinity,
              color: Colors.orange.shade50,
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (_permissionDeniedForever) {
                        // Uygulama Ayarlarını Aç (İzin vermek için)
                        await Geolocator.openAppSettings();
                      } else if (_locationServiceDisabled) {
                        // Konum Servisi Ayarlarını Aç (GPS açmak için)
                        await Geolocator.openLocationSettings();
                      }
                    },
                    icon: const Icon(Icons.settings),
                    label: Text(_permissionDeniedForever ? 'Uygulama Ayarlarını Aç' : 'Konum Servisini Aç'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else if (_statusMessage.isNotEmpty && !_isLoading && _currentPosition == null)
            Container(
              width: double.infinity,
              color: Colors.blue.shade50,
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blue.shade900, fontSize: 12),
              ),
            ),

          // 3. LİSTE
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              "En Yakın Marketler (${_currentPosition != null ? 'Konumunuza' : 'Varsayılan Merkeze'} Göre Sıralı)",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          Expanded(
            child: _markets.isEmpty && !_isLoading
                ? const Center(child: Text('Bölgenizde aktif market bulunmamaktadır.'))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _markets.length,
              itemBuilder: (context, index) {
                final market = _markets[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Icon(Icons.storefront, color: market.isActive ? Colors.green[700] : Colors.grey),
                    title: Text(market.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text("${market.distance.toStringAsFixed(2)} km uzakta"),
                    trailing: market.isActive
                        ? ElevatedButton(
                      onPressed: () => _selectMarket(market.id, market.name),
                      child: const Text('Seç'),
                    )
                        : const Text('Kapalı', style: TextStyle(color: Colors.red)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}