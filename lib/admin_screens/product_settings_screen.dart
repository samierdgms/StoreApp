import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/product_service.dart';
import '../models/product.dart';

class ProductSettingsScreen extends StatefulWidget {
  const ProductSettingsScreen({super.key});

  @override
  _ProductSettingsScreenState createState() => _ProductSettingsScreenState();
}

class _ProductSettingsScreenState extends State<ProductSettingsScreen> {
  List<Product> _products = [];
  List<String> _categories = [];
  String _selectedCategory = 'Tümü';
  String _searchQuery = '';
  bool _isLoading = true;

  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _price = '';
  String _description = '';
  String _unit = '';
  String _category = 'Tümü';
  String _imageUrl = '';
  String _stockStatus = 'Stokta Var';
  String _discountStatus = 'İndirimli';
  Product? _editingProduct;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _categories = await ProductService.fetchCategories();
      _products = await ProductService.fetchProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veri yüklenemedi')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final newProduct = Product(
        id: _editingProduct?.id ?? '',
        name: _name,
        imageUrl: _imageUrl,
        unit: _unit,
        price: double.tryParse(_price) ?? 0.0,
        inStock: _stockStatus == 'Stokta Var',
        category: _category,
        description: _description,
        hasDiscount: _discountStatus == 'İndirimli',
      );

      try {
        if (_editingProduct != null) {
          await ProductService.updateProduct(newProduct);
        } else {
          await ProductService.addProduct(newProduct);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ürün başarıyla kaydedildi')),
        );
        Navigator.pop(context);
        await _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bir hata oluştu: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteProduct() async {
    if (_editingProduct != null) {
      try {
        await ProductService.deleteProduct(_editingProduct!.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ürün başarıyla silindi')),
        );
        Navigator.pop(context);
        await _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Silme işlemi başarısız oldu: ${e.toString()}')),
        );
      }
    }
  }

  void _showProductForm(Product? product) {
    setState(() {
      _editingProduct = product;
      if (product != null) {
        _name = product.name;
        _price = product.price.toString();
        _description = product.description;
        _unit = product.unit;
        _category = product.category;
        _imageUrl = product.imageUrl;
        _stockStatus = product.inStock ? 'Stokta Var' : 'Stokta Yok';
        _discountStatus = product.hasDiscount ? 'İndirimli' : 'İndirimli Değil';
      } else {
        _name = '';
        _price = '';
        _description = '';
        _unit = '';
        _category = 'Tümü';
        _imageUrl = '';
        _stockStatus = 'Stokta Var';
        _discountStatus = 'İndirimli';
      }
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField('Ürün Adı', _name, (v) => _name = v, isRequired: true),
                    const SizedBox(height: 10),
                    _buildTextField('Fiyat', _price, (v) => _price = v, isRequired: true),
                    const SizedBox(height: 10),
                    _buildTextField('Birim', _unit, (v) => _unit = v),
                    const SizedBox(height: 10),
                    _buildTextField('Açıklama', _description, (v) => _description = v),
                    const SizedBox(height: 10),
                    _buildTextField('Resim URL\'si', _imageUrl, (v) => _imageUrl = v),
                    const SizedBox(height: 10),
                    _buildDropdown(
                      'Stok Durumu',
                      _stockStatus,
                      ['Stokta Var', 'Stokta Yok'],
                          (val) => _stockStatus = val,
                    ),
                    const SizedBox(height: 10),
                    _buildDropdown(
                      'İndirim Durumu',
                      _discountStatus,
                      ['İndirimli', 'İndirimli Değil'],
                          (val) => _discountStatus = val,
                    ),
                    const SizedBox(height: 10),
                    _buildCategoryField(),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      ),
                      child: Text(_editingProduct != null ? 'Düzenle' : 'Ekle'),
                    ),
                    const SizedBox(height: 10),
                    if (_editingProduct != null) // Silme butonu sadece düzenleme yapılıyorsa görünsün
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Ürün Silme'),
                                content: const Text('Bu ürünü silmek istediğinizden emin misiniz?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Vazgeç'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _deleteProduct();
                                    },
                                    child: const Text('Sil'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        ),
                        child: const Text('Sil'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(String label, String initialValue, Function(String) onChanged,
      {bool isRequired = false}) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onChanged: (value) => setState(() => onChanged(value)),
      validator: isRequired
          ? (value) {
        if (value == null || value.isEmpty) return '$label boş olamaz';
        return null;
      }
          : null,
    );
  }

  Widget _buildDropdown(
      String label, String value, List<String> options, Function(String) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: (newValue) => setState(() => onChanged(newValue!)),
      items: options
          .map((option) => DropdownMenuItem(value: option, child: Text(option)))
          .toList(),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildCategoryField() {
    return TextFormField(
      initialValue: _category,
      decoration: InputDecoration(
        labelText: 'Kategori',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onChanged: (value) {
        setState(() {
          _category = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Kategori boş olamaz';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürün Ayarları'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductForm(null),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Ürün'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Ürün adı ile ara...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              onChanged: (newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                });
              },
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: "Kategori",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredProducts().isEmpty
                  ? const Center(child: Text('Ürün bulunamadı.'))
                  : ListView.builder(
                itemCount: _filteredProducts().length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts()[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: product.imageUrl.isNotEmpty
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image),
                        ),
                      )
                          : const Icon(Icons.image_not_supported),
                      title: Text(product.name),
                      subtitle: Text(
                        '${product.category} - ${product.price.toStringAsFixed(2)}₺',
                        style: const TextStyle(fontSize: 13),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showProductForm(product),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Product> _filteredProducts() {
    return _products.where((product) {
      final matchesCategory =
          _selectedCategory == 'Tümü' || product.category == _selectedCategory;
      final matchesQuery =
      product.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }
}
