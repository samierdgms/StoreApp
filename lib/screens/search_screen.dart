import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../widgets/product_tile.dart';
import '../providers/market_provider.dart';

enum SortOrder { ascending, descending, discountFirst }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _loading = true;
  String _searchQuery = '';
  SortOrder? _sortOrder;
  List<String> _categories = [];
  String? _selectedCategory;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
  }

  Future<void> _loadProducts() async {
    final marketId = Provider.of<MarketProvider>(context, listen: false).marketId;

    if (marketId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final products = await ProductService.fetchProducts(marketId);
      final categories = await ProductService.fetchCategories(marketId);

      if (mounted) {
        setState(() {
          _allProducts = products;
          _filteredProducts = products;
          _categories = categories;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _filterAndSortProducts(String query) {
    List<Product> filtered = _allProducts.where((product) {
      final nameLower = product.name.toLowerCase();
      final queryLower = query.toLowerCase();
      return nameLower.contains(queryLower) &&
          (_selectedCategory == null || _selectedCategory == 'Tümü' || product.category == _selectedCategory);
    }).toList();

    if (_sortOrder != null) {
      if (_sortOrder == SortOrder.ascending) {
        filtered.sort((a, b) => a.price.compareTo(b.price));
      } else if (_sortOrder == SortOrder.descending) {
        filtered.sort((a, b) => b.price.compareTo(a.price));
      } else if (_sortOrder == SortOrder.discountFirst) {
        filtered.sort((a, b) {
          if (a.hasDiscount && !b.hasDiscount) return -1;
          if (!a.hasDiscount && b.hasDiscount) return 1;
          return a.price.compareTo(b.price);
        });
      }
    }

    setState(() {
      _searchQuery = query;
      _filteredProducts = filtered;
    });
  }

  void _onCategoryChanged(String? newCategory) {
    setState(() {
      _selectedCategory = newCategory;
    });
    _filterAndSortProducts(_searchQuery);
  }

  void _onSortOrderChanged(SortOrder? newOrder) {
    setState(() {
      _sortOrder = newOrder;
    });
    _filterAndSortProducts(_searchQuery);
  }

  // Modal Bottom Sheet Şablonu
  void _showFilterModal({required String title, required Widget content}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            content,
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isActive ? Colors.green : Colors.grey.shade300),
          boxShadow: [
            if (!isActive)
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isActive ? Colors.white : Colors.grey.shade700),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check, size: 16, color: Colors.white),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Ürün Arama', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : Column(
        children: [
          // Arama ve Filtre Alanı
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Arama Çubuğu
                TextField(
                  controller: _searchController,
                  onChanged: _filterAndSortProducts,
                  decoration: InputDecoration(
                    hintText: 'Ne aramıştınız?',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        _filterAndSortProducts('');
                      },
                    )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),

                // Filtre Butonları
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterButton(
                        label: _sortOrder == null ? 'Sırala' : _getSortLabel(_sortOrder!),
                        icon: Icons.sort,
                        isActive: _sortOrder != null,
                        onTap: () {
                          _showFilterModal(
                            title: 'Sıralama Ölçütü',
                            content: Column(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.arrow_upward),
                                  title: const Text('Fiyat: Artan'),
                                  selected: _sortOrder == SortOrder.ascending,
                                  selectedColor: Colors.green,
                                  onTap: () {
                                    _onSortOrderChanged(SortOrder.ascending);
                                    Navigator.pop(context);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.arrow_downward),
                                  title: const Text('Fiyat: Azalan'),
                                  selected: _sortOrder == SortOrder.descending,
                                  selectedColor: Colors.green,
                                  onTap: () {
                                    _onSortOrderChanged(SortOrder.descending);
                                    Navigator.pop(context);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.local_offer),
                                  title: const Text('Önce İndirimliler'),
                                  selected: _sortOrder == SortOrder.discountFirst,
                                  selectedColor: Colors.green,
                                  onTap: () {
                                    _onSortOrderChanged(SortOrder.discountFirst);
                                    Navigator.pop(context);
                                  },
                                ),
                                if (_sortOrder != null)
                                  ListTile(
                                    leading: const Icon(Icons.close, color: Colors.red),
                                    title: const Text('Sıralamayı Temizle', style: TextStyle(color: Colors.red)),
                                    onTap: () {
                                      _onSortOrderChanged(null);
                                      Navigator.pop(context);
                                    },
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      _buildFilterButton(
                        label: _selectedCategory ?? 'Kategori',
                        icon: Icons.category_outlined,
                        isActive: _selectedCategory != null && _selectedCategory != 'Tümü',
                        onTap: () {
                          _showFilterModal(
                            title: 'Kategori Seç',
                            content: SizedBox(
                              height: 300,
                              child: ListView.builder(
                                itemCount: _categories.length,
                                itemBuilder: (ctx, index) {
                                  final category = _categories[index];
                                  return ListTile(
                                    title: Text(category),
                                    selected: _selectedCategory == category,
                                    selectedColor: Colors.green,
                                    trailing: _selectedCategory == category ? const Icon(Icons.check, color: Colors.green) : null,
                                    onTap: () {
                                      _onCategoryChanged(category);
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sonuç Listesi
          Expanded(
            child: _filteredProducts.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  Text(
                    _searchQuery.isEmpty ? 'Arama yapmaya başlayın' : 'Sonuç bulunamadı',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
                : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _filteredProducts.length,
              itemBuilder: (ctx, index) {
                // ProductTile'a hafif gölge ekleyerek modernleştiriyoruz
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: ProductTile(product: _filteredProducts[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getSortLabel(SortOrder order) {
    switch (order) {
      case SortOrder.ascending: return 'Fiyat Artan';
      case SortOrder.descending: return 'Fiyat Azalan';
      case SortOrder.discountFirst: return 'İndirimli';
    }
  }
}