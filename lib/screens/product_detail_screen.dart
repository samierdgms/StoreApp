import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../screens/cart_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stockText = product.inStock ? "Stokta Var" : "Stokta Yok";
    final stockColor = product.inStock ? Colors.green : Colors.red;

    return Scaffold(
      backgroundColor: Colors.grey[50], // Modern gri arka plan
      body: CustomScrollView(
        slivers: [
          // 1. Genişleyen Başlık ve Resim
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black), // Geri butonu siyah
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: product.id, // Liste ekranından geçiş animasyonu
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_,__,___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),

          // 2. İçerik Alanı
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)), // Kart efekti
              ),
              // Resmi biraz örtmesi için negatif margin (isteğe bağlı ama şık durur)
              // Ancak Sliver yapısında transform kullanmak daha güvenlidir,
              // burada basitçe düz container kullanıyoruz.
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Üst Tutamaç Çizgisi (Görsel Detay)
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Kategori ve Stok Durumu Etiketleri
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.category.toUpperCase(),
                          style: TextStyle(color: Colors.grey[700], fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: stockColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(product.inStock ? Icons.check_circle : Icons.cancel, size: 14, color: stockColor),
                            const SizedBox(width: 6),
                            Text(stockText, style: TextStyle(color: stockColor, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Ürün Adı ve İndirim Rozeti
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.black87, height: 1.2),
                        ),
                      ),
                      if (product.hasDiscount)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: const Text(
                            'İNDİRİM',
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 10),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Fiyat
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${product.price.toStringAsFixed(2)} ₺',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: product.hasDiscount ? Colors.red : Colors.green[700],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '/ ${product.unit}',
                        style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  const Divider(height: 1),
                  const SizedBox(height: 24),

                  // Açıklama
                  const Text(
                    "Ürün Açıklaması",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product.description.isNotEmpty ? product.description : "Bu ürün için detaylı açıklama girilmemiştir.",
                    style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.6),
                  ),

                  const SizedBox(height: 100), // Alt panelin altında kalmaması için boşluk
                ],
              ),
            ),
          ),
        ],
      ),

      // Alt Sabit Panel
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Sepete Git Butonu
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.green, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Sepete Git", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 16),
              // Sepete Ekle Butonu
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: product.inStock
                      ? () {
                    Provider.of<CartProvider>(context, listen: false).addToCart(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(child: Text("${product.name} sepete eklendi", style: const TextStyle(fontWeight: FontWeight.w600))),
                          ],
                        ),
                        backgroundColor: Colors.green[700],
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(milliseconds: 1500),
                      ),
                    );
                  }
                      : null,
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text("Sepete Ekle"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 5,
                    shadowColor: Colors.green.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}