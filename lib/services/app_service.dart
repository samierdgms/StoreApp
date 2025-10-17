// lib/services/app_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AppService {
  static final _client = Supabase.instance.client;

  static Future<bool> isUnderMaintenance() async {
    final res = await _client.from('settings').select('is_maintenance').maybeSingle();
    if (res == null) return false;
    return res['is_maintenance'] == true;
  }
}

