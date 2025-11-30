import 'package:supabase_flutter/supabase_flutter.dart';

class FeeService {
  // ✅ YENİ: Hangi marketin ücretlerini çekeceğimizi soruyoruz
  static Future<Map<String, double>> getFees(String marketId) async {
    final response = await Supabase.instance.client
        .from('fees')
        .select('name, value')
        .eq('market_id', marketId); // <-- Sadece o marketin ayarları

    // Eğer ücretler alınamadıysa veya boşsa, boş bir map döndür
    if (response == null || response.isEmpty) {
      return {};
    }

    final Map<String, double> fees = {};
    for (final row in response) {
      final name = row['name'] as String;
      // Supabase'den gelen değeri double'a çevir
      final value = double.tryParse(row['value'].toString()) ?? 0.0;
      fees[name] = value;
    }

    return fees;
  }
}