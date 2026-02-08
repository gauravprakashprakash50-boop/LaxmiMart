import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../main.dart';

class EnhancedProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const EnhancedProductCard({
    required this.product,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasDiscount =
        product.mrp != null && product.mrp! > product.price;
    final int discountPercent = hasDiscount
        ? ((product.mrp! - product.price) / product.mrp! * 100).round()
        : 0;
    final bool lowStock = product.stock > 0 && product.stock <= 5;
    final bool outOfStock = product.stock == 0;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Product Image
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                    ),
                    child: product.imageUrl != null &&
                            product.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl!,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => Center(
                              child: Icon(Icons.image_outlined,
                                  size: 40, color: Colors.grey[400]),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: Icon(Icons.shopping_bag,
                                  size: 40, color: Colors.grey),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.shopping_bag,
                                size: 40, color: Colors.grey),
                          ),
                  ),
                ),
                // Product Info
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Weight/Pack Size
                      if (product.weightPackSize != null &&
                          product.weightPackSize!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            product.weightPackSize!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      // Price Row
                      Row(
                        children: [
                          Text(
                            '₹${product.price.toStringAsFixed(product.price.truncateToDouble() == product.price ? 0 : 2)}',
                            style: const TextStyle(
                              color: Color(0xFFD32F2F),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (hasDiscount) ...[
                            const SizedBox(width: 6),
                            Text(
                              '₹${product.mrp!.toStringAsFixed(product.mrp!.truncateToDouble() == product.mrp! ? 0 : 2)}',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Colors.grey[500],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Smart Add Button
                      SizedBox(
                        width: double.infinity,
                        child: Consumer<CartProvider>(
                          builder: (context, cart, _) {
                            if (outOfStock) {
                              return const SizedBox.shrink();
                            }
                            final bool inCart = cart.isInCart(product.id);
                            final int quantity = cart.getQuantity(product.id);

                            if (inCart && quantity > 0) {
                              return _buildQuantityCounter(
                                  context, cart, quantity);
                            } else {
                              return SizedBox(
                                height: 36,
                                child: ElevatedButton(
                                  onPressed: () {
                                    cart.addToCart(product);
                                    ScaffoldMessenger.of(context)
                                        .hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Added to Cart!'),
                                        duration: Duration(milliseconds: 500),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD32F2F),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Text(
                                    'ADD',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Badges (top-right)
            Positioned(
              top: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (hasDiscount) _buildDiscountBadge(discountPercent),
                  if (hasDiscount && lowStock) const SizedBox(height: 4),
                  if (lowStock) _buildStockBadge(product.stock),
                ],
              ),
            ),

            // Out of Stock Overlay
            if (outOfStock)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'OUT OF STOCK',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityCounter(
      BuildContext context, CartProvider cart, int quantity) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFD32F2F),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Minus button
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              onPressed: () {
                cart.updateQuantity(product.id, quantity - 1);
              },
              icon: const Icon(Icons.remove, color: Colors.white, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          // Quantity text
          Text(
            '$quantity',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          // Plus button
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              onPressed: () {
                if (quantity < product.stock) {
                  cart.updateQuantity(product.id, quantity + 1);
                }
              },
              icon: const Icon(Icons.add, color: Colors.white, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountBadge(int discountPercent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$discountPercent% OFF',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStockBadge(int stock) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Only $stock left',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
