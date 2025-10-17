import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:storeappp/admin_screens/coupons_settings_screen.dart';
import 'package:storeappp/admin_screens/fee_settings_screen.dart';
import 'package:storeappp/admin_screens/system_settings_screen.dart';
import 'package:storeappp/admin_screens/order_settings_screen.dart';
import 'package:storeappp/admin_screens/product_settings_screen.dart';
import 'package:storeappp/admin_screens/revenue_screen.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Paneli'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              Center(
                child: const Text(
                  'Yönetim İşlemleri',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Buttons wrapped in Cards for a more modern feel
              _AdminButton(
                label: 'Hizmet Limitleri Ayarlama',
                icon: Icons.attach_money,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FeesScreen()));
                },
              ),
              _AdminButton(
                label: 'Kupon Ayarları',
                icon: Icons.card_giftcard,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CouponsSettingsScreen()));
                },
              ),
              _AdminButton(
                label: 'Siparişleri Yönet',
                icon: Icons.shopping_bag,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderSettingsScreen()));
                },
              ),
              _AdminButton(
                label: 'Ürünleri Yönet',
                icon: Icons.inventory,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductSettingsScreen()));
                },
              ),
              _AdminButton(
                label: 'Sistem Ayarları',
                icon: Icons.settings,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SystemSettingsScreen()));
                },
              ),
              _AdminButton(
                label: 'Satış Görüntüle',
                icon: Icons.attach_money,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RevenueScreen()));
                },
              ),
              const SizedBox(height: 32), // Add space after buttons
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

  const _AdminButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4, // Add shadow for a modern look
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Rounded corners
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16), // Rounded corners for tap area
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Icon(icon, size: 28, color: Colors.green), // Use larger icons for better visibility
                const SizedBox(width: 16),
                Text(
                  label,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
