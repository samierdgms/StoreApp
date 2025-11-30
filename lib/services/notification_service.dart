import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Uygulamanın her yerinden bildirim göstermek için anahtar
  static final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

  // Servisi Başlat
  static void initialize() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    _listenToOrderUpdates(userId);
    _listenToNewCoupons(userId);
  }

  // 1. SİPARİŞ DURUMUNU DİNLEME
  static void _listenToOrderUpdates(String userId) {
    _client
        .channel('public:orders:$userId')
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'orders',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (payload) {
        final newStatus = payload.newRecord['status'];
        final oldStatus = payload.oldRecord['status'];

        if (newStatus != oldStatus) {
          _showSnackBar(
            title: "Sipariş Güncellendi 📦",
            message: "Yeni Durum: $newStatus",
            color: Colors.blue.shade700,
            icon: Icons.local_shipping,
          );
        }
      },
    )
        .subscribe();
  }

  // 2. YENİ VE AKTİF KUPON BİLDİRİMİ (GÜNCELLENMİŞ VERSİYON)
  static void _listenToNewCoupons(String userId) async {
    try {
      // Kullanıcının alışveriş yaptığı marketleri bul
      final response = await _client
          .from('orders')
          .select('market_id')
          .eq('user_id', userId);

      if (response == null) return;

      // Market ID listesini güvenli şekilde oluştur
      final myMarketIds = (response as List)
          .map((e) => e['market_id']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      if (myMarketIds.isEmpty) return;

      // Kupon tablosunu dinle (INSERT ve UPDATE dahil)
      _client
          .channel('public:coupons')
          .onPostgresChanges(
        event: PostgresChangeEvent.all, // Sadece insert değil, hepsini dinliyoruz
        schema: 'public',
        table: 'coupons',
        callback: (payload) {
          final newRecord = payload.newRecord;

          // Eğer silme işlemiyse (DELETE) newRecord null olabilir, çıkış yap
          if (newRecord == null) return;

          final newCouponMarketId = newRecord['market_id']?.toString();
          final code = newRecord['code'];
          final isNowActive = newRecord['is_active'] == true;

          // Market kontrolü: Eğer bu kupon kullanıcının marketlerinden değilse çık
          if (newCouponMarketId == null || !myMarketIds.contains(newCouponMarketId)) {
            return;
          }

          bool shouldNotify = false;
          String msgTitle = "Yeni Fırsat! 🎉";

          // DURUM 1: Yeni kupon eklendi (INSERT) ve Aktif
          if (payload.eventType == PostgresChangeEvent.insert) {
            if (isNowActive) {
              shouldNotify = true;
              msgTitle = "Yeni Kupon Eklendi! 🎉";
            }
          }
          // DURUM 2: Var olan kupon güncellendi (UPDATE)
          else if (payload.eventType == PostgresChangeEvent.update) {
            final oldRecord = payload.oldRecord;
            // 'oldRecord' null gelebilir, bu durumda varsayılan olarak false kabul ediyoruz
            final wasActive = oldRecord?['is_active'] == true;

            // Eskiden pasifti ŞİMDİ aktif olduysa bildir
            if (!wasActive && isNowActive) {
              shouldNotify = true;
              msgTitle = "Kupon Aktifleşti! 🔔";
            }
          }

          if (shouldNotify) {
            _showSnackBar(
              title: msgTitle,
              message: "Favori marketin bir fırsat paylaştı: $code",
              color: Colors.orange.shade800,
              icon: Icons.discount,
            );
          }
        },
      )
          .subscribe();

    } catch (e) {
      debugPrint("Kupon dinleme hatası: $e");
    }
  }

  static void _showSnackBar({required String title, required String message, required Color color, required IconData icon}) {
    if (messengerKey.currentState == null) return;

    messengerKey.currentState?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white,
        elevation: 4,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  Text(message, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}