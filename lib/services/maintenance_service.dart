import 'package:supabase_flutter/supabase_flutter.dart';

class MaintenanceService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Bakım modu durumunu Supabase'den al
  static Future<bool> isMaintenanceActive() async {
    try {
      final Map<String, dynamic>? response = await _client
          .from('settings')
          .select('value')
          .eq('name', 'is_maintenance')
          .limit(1)
          .maybeSingle();

      return response != null && response['value'] == true;
    } catch (e) {
      print('Bakım durumu kontrolü sırasında hata: $e');
      return false;
    }
  }

  // Bakım modunu aktif et
  static Future<bool> activateMaintenanceMode() async {
    try {
      await _client
          .from('settings')
          .update({'value': true})
          .eq('name', 'is_maintenance');

      return true;
    } catch (e) {
      print('Bakım modu aktif edilirken hata: $e');
      return false;
    }
  }

  // Bakım modunu pasif et
  static Future<bool> deactivateMaintenanceMode() async {
    try {
      await _client
          .from('settings')
          .update({'value': false})
          .eq('name', 'is_maintenance');

      return true;
    } catch (e) {
      print('Bakım modu pasif edilirken hata: $e');
      return false;
    }
  }
}
