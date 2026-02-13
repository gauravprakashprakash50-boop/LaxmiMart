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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // White card on grey background
          borderRadius: BorderRadius.circular(15), // Soft rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06), // Subtle shadow
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: _buildProductImage(),
              ),
            ),

            // Product Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name (2 lines max)
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Weight/Pack Size
                    if (product.weightPackSize != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          product.weightPackSize!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),

                    const Spacer(),

                    // Price & ADD Button Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPriceSection(),
                        _buildAddButton(context),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: product.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: const Color(0xFFF5F5F5),
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: const Color(0xFFF5F5F5),
          child: Icon(Icons.shopping_bag_outlined, 
            size: 40, 
            color: Colors.grey[400],
          ),
        ),
      );
    }
    
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Icon(Icons.shopping_bag_outlined, 
        size: 40, 
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selling Price
        Text(
          '₹${product.price.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        
        // MRP (crossed out if different)
        if (product.mrp != null && product.mrp! > product.price)
          Text(
            '₹${product.mrp!.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              decoration: TextDecoration.lineThrough,
            ),
          ),
      ],
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final isInCart = cart.items.containsKey(product.id);

        if (!isInCart) {
          return Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFF00A82D), width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () {
                cart.addToCart(product);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.name} added'),
                    duration: const Duration(milliseconds: 800),
                    backgroundColor: const Color(0xFF00A82D),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
              ),
              child: const Text(
                'ADD',
                style: TextStyle(
                  color: Color(0xFF00A82D),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }

        // Quantity counter
        final quantity = cart.items[product.id]!.quantity;
        return Container(
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF00A82D),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.white, size: 16),
                onPressed: () {
                  if (quantity > 1) {
                    cart.updateQuantity(product.id, quantity - 1);
                  } else {
                    cart.removeFromCart(product.id);
                  }
                },
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '$quantity',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white, size: 16),
                onPressed: () {
                  if (quantity < product.stock) {
                    cart.addToCart(product);
                  }
                },
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
        );
      },
    );
  }
}
