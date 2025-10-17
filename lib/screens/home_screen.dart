import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../services/product_service.dart';
import '../widgets/product_tile.dart';
import 'cart_screen.dart';
import 'campaign_screen.dart';
import 'search_screen.dart';

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
  bool _isFiltering = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadProductsAndCategories();
  }

  void _loadProductsAndCategories() {
    _products = ProductService.fetchProducts();
    _categories = ProductService.fetchCategories();
  }

  void _onCategoryTap(String cat) {
    if (cat == selectedCategory) return;
    setState(() {
      _isFiltering = true;
    });
    Future.delayed(const Duration(milliseconds: 80), () {
      setState(() {
        selectedCategory = cat;
        _isFiltering = false;
      });
    });
  }

  Widget _buildCategoryChips(List<String> categories) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, index) {
          final cat = categories[index];
          final isSelected = selectedCategory == cat;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 20 : 14,
              vertical: isSelected ? 8 : 6,
            ),
            decoration: BoxDecoration(
              color: isSelected ? Colors.green.shade300 : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: Colors.green.shade100,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: InkWell(
              onTap: () => _onCategoryTap(cat),
              borderRadius: BorderRadius.circular(20),
              child: Text(
                cat,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : Colors.grey[800],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerGrid(int count) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: count,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products) {
    final filtered = selectedCategory == 'Tümü'
        ? products
        : products.where((p) => p.category == selectedCategory).toList();

    return AnimationLimiter(
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: filtered.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: MediaQuery.of(context).size.width /
              2 /
              (MediaQuery.of(context).size.width / 2 * 1.4),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (ctx, i) {
          return AnimationConfiguration.staggeredGrid(
            position: i,
            columnCount: 2,
            duration: const Duration(milliseconds: 500),
            child: ScaleAnimation(
              curve: Curves.easeOutBack,
              child: FadeInAnimation(
                child: ProductTile(product: filtered[i]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHomeContent() {
    return Column(
      children: [
        FutureBuilder<List<String>>(
          future: _categories,
          builder: (ctx, snapCat) {
            if (!snapCat.hasData) return const SizedBox();
            return _buildCategoryChips(snapCat.data!);
          },
        ),
        Expanded(
          child: FutureBuilder<List<Product>>(
            future: _products,
            builder: (ctx, snapProd) {
              if (snapProd.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapProd.hasError) {
                return Center(child: Text('Hata: ${snapProd.error}'));
              } else if (!snapProd.hasData || snapProd.data!.isEmpty) {
                return const Center(child: Text('Ürün bulunamadı'));
              }

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _isFiltering
                    ? _buildShimmerGrid(6)
                    : _buildProductGrid(snapProd.data!),
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

    final pages = [
      _buildHomeContent(),
      const SearchScreen(),
      const CartScreen(),
      const CampaignScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Market Uygulaması',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green.shade600,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              final user = Supabase.instance.client.auth.currentUser;
              if (user != null) {
                Navigator.pushNamed(context, '/userProfile');
              } else {
                Navigator.pushNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.green.shade600,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (idx) {
          if (_currentIndex == idx && idx == 0) {
            setState(_loadProductsAndCategories);
          } else {
            setState(() => _currentIndex = idx);
          }
        },
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Arama'),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart),
                if (cart.items.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${cart.items.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Sepetim',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: 'Kampanyalar'),
        ],
      ),
    );
  }
}
