import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class ProductService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Market ID'ye göre ürünleri getir
  static Future<List<Product>> fetchProducts(String marketId) async {
    try {
      final List<dynamic> response = await _client
          .from('products')
          .select()
          .eq('market_id', marketId);

      if (response.isEmpty) {
        return [];
      }

      return response
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Ürünler alınamadı: $e');
    }
  }

  // Kategorileri getir
  static Future<List<String>> fetchCategories(String marketId) async {
    try {
      final List<dynamic> response = await _client
          .from('products')
          .select('category')
          .eq('market_id', marketId);

      if (response.isEmpty) {
        return ['Tümü'];
      }

      final categoriesSet = response
          .map((e) => (e as Map<String, dynamic>)['category'] as String)
          .toSet();

      categoriesSet.remove('Tümü');

      final sortedCategories = categoriesSet.toList()..sort();

      return ['Tümü', ...sortedCategories];
    } catch (e) {
      throw Exception('Kategoriler alınamadı: $e');
    }
  }

  // ✅ YENİ ÜRÜN EKLEME (INSERT)
  static Future<void> addProduct(Product product, String marketId) async {
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
        'market_id': marketId, // Ekleme yaparken market ID şart
      });
    } catch (e) {
      throw Exception('Ürün eklenemedi: $e');
    }
  }

  // ✅ ÜRÜN GÜNCELLEME (UPDATE)
  static Future<void> updateProduct(Product product) async {
    try {
      // 🛠️ DÜZELTME: market_id'yi bu haritaya (Map) eklemiyoruz!
      // Sadece değiştirilebilir alanları gönderiyoruz.
      await _client.from('products').update({
        'name': product.name,
        'price': product.price,
        'image_url': product.imageUrl,
        'unit': product.unit,
        'in_stock': product.inStock,
        'category': product.category,
        'description': product.description,
        'has_discount': product.hasDiscount,
      }).eq('id', product.id); // Sadece bu ID'ye sahip ürünü güncelle
    } catch (e) {
      throw Exception('Ürün güncellenemedi: $e');
    }
  }

  // Ürün silme
  static Future<void> deleteProduct(String productId) async {
    try {
      await _client.from('products').delete().eq('id', productId);
    } catch (e) {
      throw Exception('Ürün silinemedi: $e');
    }
  }
}