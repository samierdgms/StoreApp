import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/fee_service.dart';
import '../providers/market_provider.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  // Veritabanından gelen mevcut ücretler
  Map<String, double> fees = {};
  bool isLoading = true;

  // Düzenleme için değişkenler
  String? editingName;
  final TextEditingController _editController = TextEditingController();

  // Sistemde olması beklenen standart anahtarlar
  final List<String> _requiredFeeKeys = [
    'free_delivery_amount', // Ücretsiz teslimat limiti
    'minimum_order_amount', // Minimum sepet tutarı
    'delivery_fee',         // Getirme ücreti
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFees();
    });
  }

  Future<void> _loadFees() async {
    final marketId = Provider.of<MarketProvider>(context, listen: false).marketId;

    if (marketId == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    try {
      final data = await FeeService.getFees(marketId);
      if (mounted) {
        setState(() {
          fees = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        debugPrint("Fee load error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ücretler alınamadı veya sıfırlandı.')),
        );
      }
    }
  }

  Future<void> _saveFee(String name, String newValue) async {
    final marketId = Provider.of<MarketProvider>(context, listen: false).marketId;
    if (marketId == null) return;

    final doubleValue = double.tryParse(newValue);
    if (doubleValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen geçerli bir sayı girin')),
      );
      return;
    }

    try {
      // Bu ücret zaten var mı? (Ekleme için 'fees.containsKey(name)' yeterli)
      if (fees.containsKey(name)) {
        // --- GÜNCELLEME ---
        await Supabase.instance.client
            .from('fees')
            .update({'value': doubleValue})
            .eq('name', name)
            .eq('market_id', marketId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Değer güncellendi')),
        );
      } else {
        // --- EKLEME ---
        await Supabase.instance.client
            .from('fees')
            .insert({
          'name': name,
          'value': doubleValue,
          'market_id': marketId,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yeni ücret tanımlandı')),
        );
      }

      // Listeyi yerel olarak güncelle ve inputu kapat
      setState(() {
        fees[name] = doubleValue;
        editingName = null;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İşlem başarısız: ${e.toString()}')),
      );
    }
  }

  Widget _buildFeeRow(String key) {
    // Bu anahtar veritabanında var mı?
    final bool exists = fees.containsKey(key);
    final double value = exists ? fees[key]! : 0.0;
    final isEditing = editingName == key;

    // Ekranda görünecek güzel isimler
    String label;
    switch (key) {
      case 'free_delivery_amount':
        label = 'Ücretsiz Teslimat Limiti (TL)';
        break;
      case 'minimum_order_amount':
        label = 'Minimum Sipariş Tutarı (TL)';
        break;
      case 'delivery_fee':
        label = 'Teslimat (Getirme) Ücreti (TL)';
        break;
      default:
        label = key;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                // Eğer veri yoksa "Tanımlanmamış" uyarısı
                if (!exists)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8)
                    ),
                    child: const Text('Tanımlanmamış', style: TextStyle(color: Colors.deepOrange, fontSize: 12)),
                  )
              ],
            ),
            const SizedBox(height: 12),

            if (isEditing) ...[
              // --- DÜZENLEME MODU ---
              TextField(
                controller: _editController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Yeni Değer',
                  hintText: 'Ayarlamak İstediğiniz Tutarı Giriniz',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => setState(() => editingName = null),
                    child: const Text('İptal', style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _saveFee(key, _editController.text),
                    icon: const Icon(Icons.save),
                    label: const Text('Kaydet'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ],
              ),
            ] else ...[
              // --- GÖRÜNTÜLEME MODU ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    exists ? '₺${value.toStringAsFixed(2)}' : 'TANIMLA',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: exists ? Colors.black : Colors.deepOrange
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        editingName = key;
                        // Eğer varsa mevcut değeri, yoksa boşluk koy
                        _editController.text = exists ? value.toString() : '';
                      });
                    },
                    icon: Icon(exists ? Icons.edit : Icons.add),
                    label: Text(exists ? 'Düzenle' : 'Ekle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: exists ? Colors.blue : Colors.green, // Var ise mavi, yoksa yeşil
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final marketId = Provider.of<MarketProvider>(context).marketId ?? 'Bilinmiyor';

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Hizmet Limitleri', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Bu market için tanımlanan zorunlu ücret ve limitler aşağıdadır.",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Standart anahtarlar için döngü
            ..._requiredFeeKeys.map((key) => _buildFeeRow(key)).toList(),

            const SizedBox(height: 40),
            const Divider(),

            // Değiştirilemeyen Market ID Alanı
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0, top: 16.0),
              child: Text("Sistem Bilgisi", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            TextFormField(
              initialValue: marketId,
              readOnly: true,
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Market ID',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey[200],
                prefixIcon: const Icon(Icons.lock, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}