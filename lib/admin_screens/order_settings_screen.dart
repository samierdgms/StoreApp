import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart'; // Ses için
import '../providers/market_provider.dart';
import 'package:storeappp/admin_screens/order_detail_screen.dart';

class OrderSettingsScreen extends StatefulWidget {
  const OrderSettingsScreen({super.key});

  @override
  State<OrderSettingsScreen> createState() => _OrderSettingsScreenState();
}

class _OrderSettingsScreenState extends State<OrderSettingsScreen> {
  final supabase = Supabase.instance.client;
  final AudioPlayer _audioPlayer = AudioPlayer(); // Ses oynatıcı

  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;

  Map<String, bool> sectionStates = {
    'Onay Bekleyenler': true,
    'Aktif Siparişler': true,
    'Teslim Edilenler': false,
    'Reddedilenler': false,
  };

  @override
  void initState() {
    super.initState();
    // Sayfa açılınca ilk veriyi çek
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchOrders();
      _setupRealtimeSubscription(); // Canlı dinlemeyi başlat
    });
  }

  // --- CANLI TAKİP VE OTOMATİK YENİLEME ---
  void _setupRealtimeSubscription() {
    final marketId = Provider.of<MarketProvider>(context, listen: false).marketId;
    if (marketId == null) return;

    print("Canlı takip başlatıldı: $marketId");

    supabase
        .channel('public:orders:$marketId') // Benzersiz kanal ismi
        .onPostgresChanges(
      event: PostgresChangeEvent.all, // EKLEME, GÜNCELLEME, SİLME hepsini dinle
      schema: 'public',
      table: 'orders',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'market_id',
        value: marketId,
      ),
      callback: (payload) {
        // Veritabanında bir değişiklik oldu!
        print("Veritabanı değişikliği algılandı: ${payload.eventType}");

        // 1. LİSTEYİ YENİLE (Otomatik Refresh)
        fetchOrders();

        // 2. SADECE YENİ SİPARİŞSE SES ÇAL VE UYARI VER
        if (payload.eventType == PostgresChangeEvent.insert) {
          _playNotificationSound();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: const [
                    Icon(Icons.notifications_active, color: Colors.white),
                    SizedBox(width: 10),
                    Text("🔔 YENİ SİPARİŞ GELDİ!", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 5),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
    )
        .subscribe();
  }

  Future<void> _playNotificationSound() async {
    try {
      // Dosyanın assets/sounds/notification.mp3 yolunda olduğundan emin ol
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      debugPrint("Ses çalma hatası: $e");
    }
  }

  Future<void> fetchOrders() async {
    final marketId = Provider.of<MarketProvider>(context, listen: false).marketId;
    if (marketId == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    try {
      final response = await supabase
          .from('orders')
          .select('*')
          .eq('market_id', marketId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          orders = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      debugPrint("Hata: $e");
    }
  }

  @override
  void dispose() {
    supabase.removeAllChannels(); // Sayfadan çıkınca dinlemeyi durdur
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- ARAYÜZ KODLARI (AYNI KALDI) ---

  List<Map<String, dynamic>> getByStatus(String status) => orders.where((o) => o['status'] == status).toList();

  List<Map<String, dynamic>> getActiveOrders() => orders.where((o) =>
      ['Sipariş Hazırlanıyor', 'Sipariş Yolda'].contains(o['status'])
  ).toList();

  List<Map<String, dynamic>> getCanceledOrders() => orders.where((o) =>
  o['status'].toString().contains('Reddedildi') ||
      o['status'].toString().contains('İptal')
  ).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Sipariş Yönetimi', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: fetchOrders, // Manuel yenileme de kalsın
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (orders.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text("Sipariş bulunamadı."))),

              _buildSection('Onay Bekleyenler', getByStatus('Sipariş Onayı Bekleniyor'), Colors.orange),
              _buildSection('Aktif Siparişler', getActiveOrders(), Colors.blue),
              _buildSection('Teslim Edilenler', getByStatus('Sipariş Teslim Edildi'), Colors.green),
              _buildSection('Reddedilenler', getCanceledOrders(), Colors.red),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> list, Color color) {
    final bool isExpanded = sectionStates[title] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => sectionStates[title] = !isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(Icons.folder_outlined, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text("$title", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                    child: Text("${list.length}", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey),
                ],
              ),
            ),
          ),
          if (isExpanded)
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("Bu kategoride sipariş yok.", style: TextStyle(color: Colors.grey[500])),
              )
            else
              ...list.map((order) => _buildOrderSummaryCard(order, color)).toList(),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(Map<String, dynamic> order, Color themeColor) {
    final String name = "${order['customer_name']} ${order['customer_surname']}";
    final double finalPrice = (order['final_price'] as num?)?.toDouble() ?? 0.0;
    final DateTime date = DateTime.parse(order['created_at']).toLocal();
    final String timeStr = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    final String status = order['status'] ?? '';

    bool isCustomerCancelled = status.contains('İptal');
    bool isMarketRejected = status.contains('Reddedildi');

    Color displayColor = themeColor;
    IconData rightIcon = Icons.arrow_forward_ios;

    if (isCustomerCancelled) {
      displayColor = Colors.orange;
      rightIcon = Icons.person_off_outlined;
    } else if (isMarketRejected) {
      displayColor = Colors.red;
      rightIcon = Icons.block;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => OrderDetailScreen(order: order)),
            );
            fetchOrders();
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: displayColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(timeStr, style: TextStyle(color: displayColor, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      if (isCustomerCancelled)
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 14, color: Colors.orange[800]),
                            const SizedBox(width: 4),
                            Text("Müşteri İptal Etti", style: TextStyle(color: Colors.orange[800], fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        )
                      else if (isMarketRejected)
                        Text("Sipariş Reddedildi", style: TextStyle(color: Colors.red[800], fontSize: 13, fontWeight: FontWeight.w500))
                      else
                        Text("₺${finalPrice.toStringAsFixed(2)}", style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Icon(rightIcon, size: 18, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}