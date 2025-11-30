import 'package:supabase_flutter/supabase_flutter.dart';

class MaintenanceService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Bakım modu açık mı? (Boolean değer)
  static Future<bool> isMaintenanceActive() async {
    try {
      final response = await _client
          .from('settings')
          .select('value')
          .eq('name', 'is_maintenance')
          .maybeSingle();

      return response != null && response['value'] == true;
    } catch (e) {
      return false;
    }
  }

  // ✅ YENİ: Süper Admin ID'sini çek (Text değer)
  static Future<String?> getSuperAdminId() async {
    try {
      final response = await _client
          .from('settings')
          .select('text_value') // Yeni eklediğimiz sütun
          .eq('name', 'super_admin_id')
          .maybeSingle();

      if (response != null) {
        return response['text_value'] as String?;
      }
      return null;
    } catch (e) {
      print('Süper Admin ID alınamadı: $e');
      return null;
    }
  }
}