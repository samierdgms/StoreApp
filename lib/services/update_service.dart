import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // ✅ Yeni paketimiz

class UpdateService {
  static final supabase = Supabase.instance.client;

  /// Ana Kontrol Fonksiyonu
  static Future<void> checkAndUpdate(BuildContext context) async {
    try {
      // 1. Mevcut sürümü öğren
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      // 2. Supabase'den veriyi çek
      final response = await supabase
          .from('app_versions')
          .select()
          .eq('platform', 'android')
          .single();

      String minVersion = response['min_version'];
      String apkUrl = response['apk_url'];

      // 3. Kıyaslama yap
      if (_isUpdateRequired(currentVersion, minVersion)) {
        if (context.mounted) {
          _showUpdateDialog(context, apkUrl, minVersion);
        }
      }
    } catch (e) {
      debugPrint("Versiyon kontrol hatası: $e");
    }
  }

  /// Versiyon Karşılaştırma Mantığı
  static bool _isUpdateRequired(String currentVersion, String cloudVersion) {
    List<int> currentParts = currentVersion.split('.').map(int.parse).toList();
    List<int> cloudParts = cloudVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < cloudParts.length; i++) {
      if (i >= currentParts.length) return true;
      if (cloudParts[i] > currentParts[i]) {
        return true;
      } else if (cloudParts[i] < currentParts[i]) {
        return false;
      }
    }
    return false;
  }

  /// Güncelleme Penceresi
  static void _showUpdateDialog(BuildContext context, String url, String version) {
    showDialog(
      context: context,
      barrierDismissible: false, // Kullanıcı kapatamasın (Zorunlu güncelleme)
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Geri tuşunu engelle
        child: AlertDialog(
          title: Text("Yeni Sürüm Mevcut ($version) 🚀"),
          content: const Text(
            "Uygulamanın yeni bir sürümü yayınlandı.\n\n"
                "Devam etmek için lütfen 'İndir' butonuna basın. "
                "Tarayıcı açılacak ve dosya inecektir.",
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white
              ),
              onPressed: () {
                // Pencereyi kapatmaya gerek yok, kullanıcı güncelleyene kadar kalsın
                // Veya istersen Navigator.pop(context); diyebilirsin.
                _launchURL(url);
              },
              child: const Text("İndir ve Güncelle"),
            ),
          ],
        ),
      ),
    );
  }

  /// Linki Tarayıcıda Açan Fonksiyon
  static Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        debugPrint('Link açılamadı: $url');
      }
    } catch (e) {
      debugPrint('Hata: $e');
    }
  }
}