import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_service.dart';
import 'models.dart';
import 'widgets/cached_image_widget.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartService>(context);
    final qty = cart.getQuantity(product.id);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Product Details"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // --- 1. BIG IMAGE SECTION ---
          Container(
            height: 300,
            width: double.infinity,
            color: Colors.grey[100],
            child: ImageCacheManager.buildProductImage(
              imageUrl: product.imageUrl,
              width: double.infinity,
              height: 300,
              fit: BoxFit.contain,
            ),
          ),

          // --- 2. DETAILS SECTION ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F).withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      product.category.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFFD32F2F),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Product Name
                  Text(
                    product.name,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Stock & Price Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "₹${product.price}",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFD32F2F),
                        ),
                      ),
                      Text(
                        product.stockQuantity > 0
                            ? "In Stock: ${product.stockQuantity}"
                            : "Out of Stock",
                        style: TextStyle(
                          color: product.stockQuantity > 0
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Divider(),
                  const SizedBox(height: 10),

                  const Text(
                    "Description",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description.isEmpty
                        ? "No description available for this product."
                        : product.description,
                    style: const TextStyle(
                        fontSize: 16, color: Colors.black87, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // --- 3. BOTTOM ACTION BAR ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 10,
                offset: const Offset(0, -5))
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Quantity Control or Add Button
              qty > 0
                  ? Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () =>
                                  cart.removeSingleItem(product.id),
                              icon:
                                  const Icon(Icons.remove, color: Colors.black),
                            ),
                            const SizedBox(width: 20),
                            Text(
                              "$qty",
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 20),
                            IconButton(
                              onPressed: () => cart.addToCart(product),
                              icon: const Icon(Icons.add, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => cart.addToCart(product),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD32F2F),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            "ADD TO CART",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
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
