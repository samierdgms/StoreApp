import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Providerlar
import '../providers/cart_provider.dart';
import '../providers/market_provider.dart';

// Admin Alt Ekranları
import 'package:storeappp/admin_screens/coupons_settings_screen.dart';
import 'package:storeappp/admin_screens/fee_settings_screen.dart';
import 'package:storeappp/admin_screens/market_settings_screen.dart';
import 'package:storeappp/admin_screens/order_settings_screen.dart';
import 'package:storeappp/admin_screens/product_settings_screen.dart';
import 'package:storeappp/admin_screens/revenue_screen.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();

    if (context.mounted) {
      Provider.of<MarketProvider>(context, listen: false).clearMarket();
      Provider.of<CartProvider>(context, listen: false).clearCart();
      Navigator.of(context).pushNamedAndRemoveUntil('/selectMarket', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final marketName = Provider.of<MarketProvider>(context).marketName ?? 'Market';

    return Scaffold(
      backgroundColor: Colors.grey[100], // Modern gri arka plan
      appBar: AppBar(
        // ✅ GERİ BUTONUNU KAPAT
        automaticallyImplyLeading: false,

        // ✅ YERİNE PROFİL BUTONU KOY (SOL TARAFA)
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            tooltip: 'Profil Ayarları',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.green, size: 20),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/userProfile');
            },
          ),
        ),

        title: Column(
          children: [
            const Text(
              'Yönetici Paneli',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            Text(
              marketName,
              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.normal),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Çıkış Butonu (Sağ Tarafta Kalmaya Devam Eder)
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Çıkış Yap',
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hızlı İşlemler',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey
                ),
              ),
              const SizedBox(height: 16),

              _AdminButton(
                label: 'Siparişleri Yönet',
                icon: Icons.shopping_bag_outlined,
                color: Colors.blue,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderSettingsScreen()));
                },
              ),
              _AdminButton(
                label: 'Ürünleri Yönet',
                icon: Icons.inventory_2_outlined,
                color: Colors.orange,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductSettingsScreen()));
                },
              ),
              _AdminButton(
                label: 'Kupon Ayarları',
                icon: Icons.card_giftcard_outlined,
                color: Colors.purple,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CouponsSettingsScreen()));
                },
              ),
              _AdminButton(
                label: 'Hizmet Limitleri (Ücretler)',
                icon: Icons.attach_money,
                color: Colors.teal,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FeesScreen()));
                },
              ),
              _AdminButton(
                label: 'Satış Raporları',
                icon: Icons.bar_chart_rounded,
                color: Colors.indigo,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RevenueScreen()));
                },
              ),
              _AdminButton(
                label: 'Market Ayarları (Aç/Kapat)',
                icon: Icons.store_mall_directory_outlined,
                color: Colors.red,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketSettingsScreen()));
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _AdminButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}