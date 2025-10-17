import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/fee_service.dart'; // FeeService dosya yolunu kontrol et

class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  Map<String, double> fees = {};
  bool isLoading = true;
  String? editingName;
  final TextEditingController _editController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFees();
  }

  Future<void> _loadFees() async {
    try {
      final data = await FeeService.getFees();
      setState(() {
        fees = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ücretler alınamadı: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateFee(String name, String newValue) async {
    final doubleValue = double.tryParse(newValue);
    if (doubleValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir sayı girin')),
      );
      return;
    }

    await Supabase.instance.client
        .from('fees')
        .update({'value': newValue})
        .eq('name', name);

    setState(() {
      fees[name] = doubleValue;
      editingName = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Değer başarıyla güncellendi')),
    );
  }

  Widget _buildFeeRow(String name, double value) {
    final isEditing = editingName == name;

    String label;
    switch (name) {
      case 'free_delivery_amount':
        label = 'Ücretsiz Teslimat Tutarı';
        break;
      case 'minimum_order_amount':
        label = 'Minimum Sipariş Tutarı';
        break;
      case 'delivery_fee':
        label = 'Teslimat Ücreti';
        break;
      default:
        label = name;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (isEditing) ...[
              TextField(
                controller: _editController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Yeni değer',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _updateFee(name, _editController.text),
                    icon: const Icon(Icons.check),
                    label: const Text('Güncelle'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => setState(() => editingName = null),
                    child: const Text('İptal'),
                  ),
                ],
              ),
            ] else ...[
              Text('${value.toStringAsFixed(2)} ₺', style: const TextStyle(fontSize: 16)),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      editingName = name;
                      _editController.text = value.toString();
                    });
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Düzenle'),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final filteredKeys = [
      'free_delivery_amount',
      'minimum_order_amount',
      'delivery_fee',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Ücret Ayarlama')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: filteredKeys
              .where((key) => fees.containsKey(key))
              .map((key) => _buildFeeRow(key, fees[key]!))
              .toList(),
        ),
      ),
    );
  }
}
