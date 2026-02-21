import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x261C1C1C),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: 130,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              padding: const EdgeInsets.all(16),
              child: _buildProductImage(),
            ),

            // Product Details
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Weight/Pack Size
                  Text(
                    product.weightPackSize ?? '1 unit',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF737373),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Product Name (2 lines max)
                  Text(
                    product.name,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF3D3D3D),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Price & ADD Button Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildPriceSection(),
                      _buildAddButton(context),
                    ],
                  ),
                ],
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
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0C831F)),
        ),
        errorWidget: (context, url, error) => Icon(
          Icons.shopping_bag_outlined,
          size: 40,
          color: Colors.grey[400],
        ),
      );
    }

    return Icon(
      Icons.shopping_bag_outlined,
      size: 40,
      color: Colors.grey[400],
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '₹${product.price.toStringAsFixed(0)}',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3D3D3D),
          ),
        ),
        if (product.mrp != null && product.mrp! > product.price)
          Text(
            '₹${product.mrp!.toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF9E9E9E),
              decoration: TextDecoration.lineThrough,
            ),
          ),
      ],
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final qty = cart.getQuantity(product.id);

        if (qty == 0) {
          return GestureDetector(
            onTap: () => cart.addToCart(product),
            child: Container(
              height: 36,
              width: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFF7FFF9),
                border: Border.all(color: const Color(0xFF0C831F), width: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'ADD',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF0C831F),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }

        return Container(
          height: 36,
          width: 88,
          decoration: BoxDecoration(
            color: const Color(0xFF0C831F),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: () {
                  if (qty > 1) {
                    cart.updateQuantity(product.id, qty - 1);
                  } else {
                    cart.removeFromCart(product.id);
                  }
                },
                child: const Icon(Icons.remove, color: Colors.white, size: 16),
              ),
              Text(
                '$qty',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (qty < product.stock) {
                    cart.addToCart(product);
                  }
                },
                child: const Icon(Icons.add, color: Colors.white, size: 16),
              ),
            ],
          ),
        );
      },
    );
  }
}
