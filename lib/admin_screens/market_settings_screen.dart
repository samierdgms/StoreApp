import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart'; // Harita için
import 'package:latlong2/latlong.dart'; // Koordinat sınıfı

import '../providers/market_provider.dart';

class MarketSettingsScreen extends StatefulWidget {
  const MarketSettingsScreen({super.key});

  @override
  State<MarketSettingsScreen> createState() => _MarketSettingsScreenState();
}

class _MarketSettingsScreenState extends State<MarketSettingsScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;

  // Form alanları
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _longController = TextEditingController();

  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMarketData();
    });
  }

  Future<void> _loadMarketData() async {
    final marketId = Provider.of<MarketProvider>(context, listen: false).marketId;
    if (marketId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Marketin mevcut bilgilerini ve konumunu çek
      final data = await _supabase
          .from('markets')
          .select('name, is_active, latitude, longitude')
          .eq('id', marketId)
          .single();

      if (mounted) {
        setState(() {
          _nameController.text = data['name'] ?? '';
          _isActive = data['is_active'] ?? true;
          // Konum verileri varsa doldur
          _latController.text = (data['latitude'] ?? '').toString();
          _longController.text = (data['longitude'] ?? '').toString();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Market verisi hatası: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veri alınamadı: $e')),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    final marketId = Provider.of<MarketProvider>(context, listen: false).marketId;
    if (marketId == null) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // İsim, aktiflik ve konum bilgilerini güncelle
      await _supabase.from('markets').update({
        'name': _nameController.text.trim(),
        'is_active': _isActive,
        'latitude': double.tryParse(_latController.text) ?? 0.0,
        'longitude': double.tryParse(_longController.text) ?? 0.0,
      }).eq('id', marketId);

      if (mounted) {
        // Provider ismini de güncelle
        Provider.of<MarketProvider>(context, listen: false)
            .setMarket(marketId, _nameController.text.trim());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Market ayarları güncellendi ✅'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Güncelleme başarısız: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Harita Seçici Ekranını Aç
  void _openMapPicker() async {
    // Mevcut konum varsa oradan başlat, yoksa İzmir merkez
    double startLat = double.tryParse(_latController.text) ?? 38.4237;
    double startLng = double.tryParse(_longController.text) ?? 27.1428;

    final LatLng? pickedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(initialPosition: LatLng(startLat, startLng)),
      ),
    );

    if (pickedLocation != null) {
      setState(() {
        _latController.text = pickedLocation.latitude.toString();
        _longController.text = pickedLocation.longitude.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final marketId = Provider.of<MarketProvider>(context).marketId ?? 'Bilinmiyor';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Market Ayarları', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. DURUM KARTI
              Container(
                decoration: BoxDecoration(
                  color: _isActive ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _isActive ? Colors.green.shade200 : Colors.red.shade200),
                ),
                child: SwitchListTile(
                  title: Text(
                    _isActive ? 'Market Şu An AÇIK' : 'Market Şu An KAPALI',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isActive ? Colors.green[800] : Colors.red[800],
                    ),
                  ),
                  subtitle: Text(
                    _isActive
                        ? 'Müşteriler sipariş verebilir.'
                        : 'Müşteriler marketinizi kapalı görecek.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  value: _isActive,
                  activeColor: Colors.green,
                  onChanged: (val) => setState(() => _isActive = val),
                ),
              ),

              const SizedBox(height: 24),
              const Text("Market Bilgileri", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // 2. MARKET ADI
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Market Adı',
                  prefixIcon: const Icon(Icons.store, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
                validator: (value) => value!.isEmpty ? 'Market adı boş olamaz' : null,
              ),
              const SizedBox(height: 20),

              // 3. KONUM SEÇİMİ
              const Text("Konum Ayarları", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latController,
                            readOnly: true,
                            decoration: const InputDecoration(labelText: 'Enlem (Lat)', isDense: true, border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _longController,
                            readOnly: true,
                            decoration: const InputDecoration(labelText: 'Boylam (Lng)', isDense: true, border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _openMapPicker,
                        icon: const Icon(Icons.map),
                        label: const Text("Haritadan Konum Seç"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.blue),
                          foregroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 4. MARKET ID (Salt Okunur)
              TextFormField(
                initialValue: marketId,
                readOnly: true,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Market ID (Sistem)',
                  filled: true,
                  fillColor: Colors.grey[200],
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),

              const SizedBox(height: 40),

              // KAYDET BUTONU
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveSettings,
                  icon: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Kaydediliyor...' : 'Ayarları Kaydet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 5,
                    shadowColor: Colors.green.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// --- HARİTA SEÇİM EKRANI ---
class LocationPickerScreen extends StatefulWidget {
  final LatLng initialPosition;
  const LocationPickerScreen({super.key, required this.initialPosition});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late LatLng _pickedLocation;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialPosition;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Konumu Seçin"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, _pickedLocation);
            },
          )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _pickedLocation,
              initialZoom: 15.0,
              onTap: (_, point) {
                setState(() {
                  _pickedLocation = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.marketapp.admin',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _pickedLocation,
                    width: 80,
                    height: 80,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 50),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, _pickedLocation);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Bu Konumu Onayla", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}