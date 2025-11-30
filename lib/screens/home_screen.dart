import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/market_provider.dart';
import '../services/product_service.dart';
import '../widgets/product_tile.dart';
import 'cart_screen.dart';
import 'campaign_screen.dart';
import 'search_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Product>> _products;
  late Future<List<String>> _categories;

  String selectedCategory = 'Tümü';
  int _currentIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  void _loadData() {
    final marketProvider = Provider.of<MarketProvider>(context, listen: false);
    final marketId = marketProvider.marketId;

    if (marketId == null) {
      Future.microtask(() =>
          Navigator.pushReplacementNamed(context, '/selectMarket')
      );
      _products = Future.value([]);
      _categories = Future.value([]);
      return;
    }

    _products = ProductService.fetchProducts(marketId);
    _categories = ProductService.fetchCategories(marketId);
  }

  Widget _buildHomeContent() {
    return Column(
      children: [
        // Kategori Listesi
        FutureBuilder<List<String>>(
          future: _categories,
          builder: (ctx, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            final categories = snapshot.data!;
            return Container(
              color: Colors.white,
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (ctx, index) {
                  final cat = categories[index];
                  final isSelected = selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: Colors.green,
                    backgroundColor: Colors.grey[100],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (_) {
                      setState(() {
                        selectedCategory = cat;
                      });
                    },
                  );
                },
              ),
            );
          },
        ),

        // Ürünler Grid
        Expanded(
          child: FutureBuilder<List<Product>>(
            future: _products,
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.green));
              } else if (snapshot.hasError) {
                return Center(child: Text('Hata: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 10),
                      Text('Bu markette henüz ürün yok.', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                );
              }

              final products = snapshot.data!;
              final filteredProducts = selectedCategory == 'Tümü'
                  ? products
                  : products.where((p) => p.category == selectedCategory).toList();

              if (filteredProducts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 10),
                      Text('Bu kategoride ürün bulunamadı.', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredProducts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7, // Kart oranı
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (ctx, index) {
                  // ProductTile widget'ının da modern görünmesi için
                  // ProductTile dosyasını da güncellemenizi öneririm,
                  // ama burada dışarıdan modern bir gölge veriyoruz.
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ProductTile(product: filteredProducts[index]),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final marketName = Provider.of<MarketProvider>(context).marketName ?? 'Market';

    final List<Widget> pages = [
      _buildHomeContent(),
      const SearchScreen(),
      const CartScreen(),
      const CampaignScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50], // Modern gri arka plan
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.storefront, color: Colors.green),
          onPressed: () {}, // İkon süs amaçlı
        ),
        title: GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/selectMarket');
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Alışveriş Yapılan Market', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Row(
                children: [
                  Text(
                    marketName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.green, size: 20),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.green, size: 20),
            ),
            onPressed: () {
              final user = Supabase.instance.client.auth.currentUser;
              if (user != null) {
                Navigator.pushNamed(context, '/userProfile');
              } else {
                Navigator.pushNamed(context, '/login');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey[400],
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: (index) {
            if (_currentIndex == index && index == 0) {
              setState(() {
                _loadData();
              });
            } else {
              setState(() {
                _currentIndex = index;
              });
            }
          },
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Ana Sayfa'),
            const BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Arama'),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.shopping_bag_outlined),
                  if (cart.items.isNotEmpty)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '${cart.items.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Sepetim',
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.local_offer_outlined), label: 'Fırsatlar'),
          ],
        ),
      ),
      body: pages[_currentIndex],
    );
  }
}