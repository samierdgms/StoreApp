import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../widgets/product_tile.dart';

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

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // Ürünleri ve kategorileri yükleme
  Future<void> _loadProducts() async {
    try {
      final products = await ProductService.fetchProducts();
      final categories = await ProductService.fetchCategories(); // Kategorileri yükle

      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _categories = categories;

        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  // Ürünleri filtrele ve sırala
  void _filterAndSortProducts(String query) {
    List<Product> filtered = _allProducts.where((product) {
      final nameLower = product.name.toLowerCase();
      final queryLower = query.toLowerCase();
      return nameLower.contains(queryLower) &&
          (_selectedCategory == null || _selectedCategory == 'Tümü' || product.category == _selectedCategory);
    }).toList();

    // Sıralama seçenekleri
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

  // Kategoriyi seç
  void _onCategoryChanged(String? newCategory) {
    setState(() {
      _selectedCategory = newCategory;
    });
    _filterAndSortProducts(_searchQuery);
  }

  // Sıralama seçeneklerini güncelle
  void _onSortOrderChanged(SortOrder? newOrder) {
    setState(() {
      _sortOrder = newOrder;
    });
    _filterAndSortProducts(_searchQuery);
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 600) {
      return 2;
    } else if (width < 900) {
      return 3;
    } else {
      return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ürün Arama'), backgroundColor: Colors.green),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: _filterAndSortProducts,
                    decoration: InputDecoration(
                      labelText: 'Ürün ara',
                      labelStyle: TextStyle(color: Colors.grey[700]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    // Sıralama menüsüne geri dönme işlemi
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: const Text('Fiyata Göre Artan'),
                              onTap: () {
                                _onSortOrderChanged(SortOrder.ascending);
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              title: const Text('Fiyata Göre Azalan'),
                              onTap: () {
                                _onSortOrderChanged(SortOrder.descending);
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              title: const Text('İndirimli Ürünler Öncelikli'),
                              onTap: () {
                                _onSortOrderChanged(SortOrder.discountFirst);
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Sırala',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    // Kategori seçme modal'ını açma
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: _categories.map((category) {
                            return ListTile(
                              title: Text(category),
                              onTap: () {
                                _onCategoryChanged(category);
                                Navigator.pop(context);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Kategori Seç',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredProducts.isEmpty
                ? Center(
              child: Text(
                _searchQuery.isEmpty ? 'Lütfen arama yapın' : 'Ürün bulunamadı',
                style: const TextStyle(fontSize: 16),
              ),
            )
                : GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _getCrossAxisCount(context),
                childAspectRatio: 0.7,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _filteredProducts.length,
              itemBuilder: (ctx, index) {
                return ProductTile(product: _filteredProducts[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
