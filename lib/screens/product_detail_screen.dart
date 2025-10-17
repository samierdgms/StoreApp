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
      appBar: AppBar(title: Text(product.name)),
      body: ListView(
        children: [
          Image.network(product.imageUrl, height: 250, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (product.hasDiscount)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'İndirimde',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(product.unit, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                Text(
                  '${product.price.toStringAsFixed(2)} ₺',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: product.hasDiscount ? Colors.redAccent : Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(stockText, style: TextStyle(color: stockColor)),
                const SizedBox(height: 16),
                Text(product.description, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: product.inStock
                            ? () {
                          Provider.of<CartProvider>(context, listen: false).addToCart(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("${product.name} sepete eklendi"),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                            : null,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: const Color(0xFFFFC067),
                          backgroundColor: Colors.green,
                        ),
                        child: const Text("Sepete Ekle"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CartScreen()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFFC067),
                          side: const BorderSide(color: Colors.green),
                        ),
                        child: const Text("Sepete Git"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
