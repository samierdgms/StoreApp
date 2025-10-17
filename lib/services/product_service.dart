import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class ProductService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Ürünleri almak
  static Future<List<Product>> fetchProducts() async {
    try {
      final List<dynamic> response = await _client
          .from('products')
          .select();

      if (response.isEmpty) {
        throw Exception('Ürünler alınamadı.');
      }

      return response
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Ürünler alınamadı: $e');
    }
  }

  // Kategorileri almak
  static Future<List<String>> fetchCategories() async {
    try {
      final List<dynamic> response = await _client
          .from('products')
          .select('category');

      if (response.isEmpty) {
        throw Exception('Kategoriler alınamadı.');
      }

      final categories = response
          .map((e) => (e as Map<String, dynamic>)['category'] as String)
          .toSet()
          .toList();

      categories.sort();
      return ['Tümü', ...categories];
    } catch (e) {
      throw Exception('Kategoriler alınamadı: $e');
    }
  }

  // Yeni bir ürün eklemek
  static Future<void> addProduct(Product product) async {
    try {
      await _client.from('products').insert({
        'name': product.name,
        'price': product.price,
        'image_url': product.imageUrl,
        'unit': product.unit,
        'in_stock': product.inStock,
        'category': product.category,
        'description': product.description,
        'has_discount': product.hasDiscount,
      });
    } catch (e) {
      throw Exception('Ürün eklenemedi: $e');
    }
  }

  // Ürün güncellemek
  static Future<void> updateProduct(Product product) async {
    try {
      await _client.from('products').upsert({
        'id': product.id,
        'name': product.name,
        'price': product.price,
        'image_url': product.imageUrl,
        'unit': product.unit,
        'in_stock': product.inStock,
        'category': product.category,
        'description': product.description,
        'has_discount': product.hasDiscount,
      });
    } catch (e) {
      throw Exception('Ürün güncellenemedi: $e');
    }
  }

  // Ürün silmek
  static Future<void> deleteProduct(String productId) async {
    try {
      await _client.from('products').delete().eq('id', productId);


    } catch (e) {
      throw Exception('Ürün silinemedi: $e');
    }
  }
}
