import 'package:supabase_flutter/supabase_flutter.dart';

class FeeService {
  static Future<Map<String, double>> getFees() async {
    final response = await Supabase.instance.client.from('fees').select('name, value');

    if (response == null || response.isEmpty) {
      throw Exception('Ücret bilgileri alınamadı');
    }

    final Map<String, double> fees = {};
    for (final row in response) {
      final name = row['name'] as String;
      final value = double.tryParse(row['value'].toString()) ?? 0.0;
      fees[name] = value;
    }

    return fees;
  }
}
