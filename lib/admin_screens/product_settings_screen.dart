import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import '../providers/market_provider.dart';

class ProductSettingsScreen extends StatefulWidget {
  const ProductSettingsScreen({super.key});

  @override
  _ProductSettingsScreenState createState() => _ProductSettingsScreenState();
}

class _ProductSettingsScreenState extends State<ProductSettingsScreen> {
  List<Product> _products = [];
  List<String> _categories = [];

  // Standart Kategoriler Listesi
  final List<String> _defaultCategories = [
    'Meyve & Sebze', 'Et & Tavuk & Balık', 'Süt & Kahvaltılık', 'Temel Gıda',
    'Fırın & Pastane', 'Atıştırmalık & Çikolata', 'İçecekler', 'Dondurma',
    'Temizlik Ürünleri', 'Kişisel Bakım', 'Bebek Ürünleri', 'Evcil Hayvan',
    'Ev & Yaşam', 'Teknoloji', 'Giyim', 'Kırtasiye', 'Diğer'
  ];

  String _selectedCategoryFilter = 'Tümü';
  String _searchQuery = '';
  bool _isLoading = true;

  final _formKey = GlobalKey<FormState>();
  // Form Değişkenleri
  String _name = '';
  String _price = '';
  String _description = '';
  String _unit = '';
  String _formCategory = '';
  String _imageUrl = '';
  String _stockStatus = 'Stokta Var';
  String _discountStatus = 'İndirimli Değil';
  Product? _editingProduct;

  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final marketId = Provider.of<MarketProvider>(context, listen: false).marketId;

    if (marketId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final categories = await ProductService.fetchCategories(marketId);
      final products = await ProductService.fetchProducts(marketId);

      if (mounted) {
        setState(() {
          _categories = categories;
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Veri yüklenemedi: $e')));
      }
    }
  }

  Future<void> _saveProduct() async {
    final marketId = Provider.of<MarketProvider>(context, listen: false).marketId;
    if (marketId == null) return;

    if (_formKey.currentState!.validate()) {
      if (_formCategory.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen listeden bir kategori seçin.')));
        return;
      }

      final newProduct = Product(
        id: _editingProduct?.id ?? '',
        name: _nameController.text.trim(),
        imageUrl: _imageController.text.trim(),
        unit: _unitController.text.trim(),
        price: double.tryParse(_priceController.text.trim()) ?? 0.0,
        inStock: _stockStatus == 'Stokta Var',
        category: _formCategory,
        description: _descController.text.trim(),
        hasDiscount: _discountStatus == 'İndirimli',
        marketId: marketId,
      );

      try {
        if (_editingProduct != null) {
          await ProductService.updateProduct(newProduct);
        } else {
          await ProductService.addProduct(newProduct, marketId);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İşlem başarılı', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
          Navigator.pop(context);
          await _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
        }
      }
    }
  }

  Future<void> _deleteProduct() async {
    if (_editingProduct != null) {
      try {
        await ProductService.deleteProduct(_editingProduct!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ürün silindi')));
          Navigator.pop(context);
          await _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Silme hatası: $e')));
        }
      }
    }
  }

  // --- MODALLER VE DİYALOGLAR ---

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        String localSearchQuery = '';
        final Set<String> combinedCategories = {..._categories, ..._defaultCategories};
        combinedCategories.remove('Tümü');
        final List<String> allSelectableCategories = combinedCategories.toList()..sort();

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final filteredCategories = allSelectableCategories
                .where((c) => c.toLowerCase().contains(localSearchQuery.toLowerCase()))
                .toList();

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
              child: SizedBox(
                height: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 16),
                    const Text('Kategori Seç', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      autofocus: false,
                      decoration: InputDecoration(
                        hintText: 'Listede ara...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          localSearchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filteredCategories.isEmpty
                          ? const Center(child: Text('Sonuç bulunamadı.', style: TextStyle(color: Colors.grey)))
                          : ListView.separated(
                        itemCount: filteredCategories.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final category = filteredCategories[index];
                          return ListTile(
                            title: Text(category),
                            onTap: () {
                              setState(() {
                                _formCategory = category;
                                _categoryController.text = category;
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showProductForm(Product? product) {
    final currentMarketId = Provider.of<MarketProvider>(context, listen: false).marketId ?? 'Bilinmiyor';

    setState(() {
      _editingProduct = product;
      if (product != null) {
        _nameController.text = product.name;
        _priceController.text = product.price.toString();
        _descController.text = product.description;
        _unitController.text = product.unit;
        _imageController.text = product.imageUrl;

        _formCategory = product.category;
        _categoryController.text = product.category;
        _stockStatus = product.inStock ? 'Stokta Var' : 'Stokta Yok';
        _discountStatus = product.hasDiscount ? 'İndirimli' : 'İndirimli Değil';
      } else {
        _nameController.clear();
        _priceController.clear();
        _descController.clear();
        _unitController.clear();
        _imageController.clear();
        _categoryController.clear();

        _formCategory = '';
        _stockStatus = 'Stokta Var';
        _discountStatus = 'İndirimli Değil';
      }
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          title: Text(
            product == null ? 'Yeni Ürün Ekle' : 'Ürünü Düzenle',
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField('Ürün Adı', _nameController, Icons.shopping_bag, isRequired: true),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Fiyat', _priceController, Icons.attach_money, isRequired: true, isNumber: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField('Birim (Adet, Kg)', _unitController, Icons.scale)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField('Açıklama', _descController, Icons.description),
                    const SizedBox(height: 12),
                    _buildTextField('Resim URL', _imageController, Icons.image),
                    const SizedBox(height: 12),

                    // Dropdownlar
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown('Stok Durumu', _stockStatus, ['Stokta Var', 'Stokta Yok'], (val) => _stockStatus = val),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown('İndirim', _discountStatus, ['İndirimli', 'İndirimli Değil'], (val) => _discountStatus = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Kategori Seçici
                    GestureDetector(
                      onTap: _showCategoryPicker,
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _categoryController,
                          decoration: InputDecoration(
                            labelText: 'Kategori Seç',
                            prefixIcon: const Icon(Icons.category, color: Colors.grey),
                            suffixIcon: const Icon(Icons.arrow_drop_down),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          validator: (value) => value!.isEmpty ? 'Seçim yapın' : null,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    // Read-only Market ID
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline, color: Colors.grey, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text("Market ID: $currentMarketId", style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'monospace'))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            if (_editingProduct != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmDelete();
                },
                child: const Text('Sil', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: _saveProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(_editingProduct != null ? 'Güncelle' : 'Kaydet', style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Silinsin mi?"),
        content: const Text("Bu ürünü silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hayır")),
          TextButton(onPressed: () { Navigator.pop(ctx); _deleteProduct(); }, child: const Text("Evet", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isRequired = false, bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: isRequired ? (v) => v!.isEmpty ? '$label gerekli' : null : null,
    );
  }

  Widget _buildDropdown(String label, String value, List<String> options, Function(String) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: (val) => setState(() => onChanged(val!)),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Ürün Yönetimi', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductForm(null),
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Yeni Ürün', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : Column(
        children: [
          // Üst Panel: Arama ve Filtre
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Ürünlerde ara...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedCategoryFilter,
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => _selectedCategoryFilter = val!),
                  decoration: InputDecoration(
                    labelText: "Kategoriye Göre Filtrele",
                    prefixIcon: const Icon(Icons.filter_list, color: Colors.green),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
              ],
            ),
          ),

          // Liste
          Expanded(
            child: _filteredProducts().isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('Ürün bulunamadı', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredProducts().length,
              itemBuilder: (context, index) {
                final product = _filteredProducts()[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        product.imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_,__,___) => Container(width: 60, height: 60, color: Colors.grey[200], child: const Icon(Icons.image_not_supported, color: Colors.grey)),
                      ),
                    ),
                    title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('${product.category} • ${product.unit}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('${product.price.toStringAsFixed(2)} ₺', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14)),
                            const SizedBox(width: 8),
                            if (product.hasDiscount)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                                child: const Text('İndirim', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                              ),
                            if (!product.inStock)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                                child: const Text('Stok Yok', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        )
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
                      onPressed: () => _showProductForm(product),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Product> _filteredProducts() {
    return _products.where((product) {
      final matchesCategory = _selectedCategoryFilter == 'Tümü' || product.category == _selectedCategoryFilter;
      final matchesQuery = product.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }
}