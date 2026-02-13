import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../main.dart';
import '../utils/category_logic.dart';
import '../routes/page_transitions.dart';

/// Category Split-View Screen with categories on left and products on right
class CategorySplitViewScreen extends StatefulWidget {
  const CategorySplitViewScreen({super.key});

  @override
  State<CategorySplitViewScreen> createState() =>
      _CategorySplitViewScreenState();
}

class _CategorySplitViewScreenState extends State<CategorySplitViewScreen> {
  String? _selectedCategory;
  List<String> _categories = [];
  List<Product> _currentProducts = [];
  bool _isLoading = true;
  bool _isLoadingProducts = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  /// Load categories from database
  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    try {
      final categories = await CategoryHelper.getCategories();
      
      setState(() {
        _categories = categories;
        // Select first category by default
        if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first;
          _loadCategoryProducts(_selectedCategory!);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load categories: $e')),
        );
      }
    }
  }

  /// Load products for a specific category
  Future<void> _loadCategoryProducts(String category) async {
    setState(() => _isLoadingProducts = true);

    try {
      final products = await CategoryHelper.getProductsByCategory(category);
      
      setState(() {
        _currentProducts = products;
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() => _isLoadingProducts = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load products: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop by Category'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // LEFT SIDEBAR (20% width)
                _buildLeftSidebar(),

                // RIGHT CONTENT (80% width)
                _buildRightProductGrid(),
              ],
            ),
    );
  }

  /// Build left sidebar with category list
  Widget _buildLeftSidebar() {
    return Expanded(
      flex: 2, // 20% width
      child: Container(
        color: const Color(0xFFF5F5F5), // Off-white background
        child: ListView.builder(
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = _selectedCategory == category;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
                _loadCategoryProducts(category);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  border: Border(
                    left: BorderSide(
                      color: isSelected
                          ? const Color(0xFF00A82D)
                          : Colors.transparent,
                      width: 4,
                    ),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                child: Column(
                  children: [
                    // Category Icon with circular background
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? const Color(0xFF00A82D).withOpacity(0.1)
                          : Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: const Color(0xFF00A82D).withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ] : [],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: CachedNetworkImage(
                          imageUrl: CategoryHelper.getIconUrl(category),
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Icon(
                            Icons.category,
                            size: 32,
                            color: isSelected ? const Color(0xFF00A82D) : Colors.grey,
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.category,
                            size: 32,
                            color: isSelected ? const Color(0xFF00A82D) : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Category Name
                    Text(
                      category,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF00A82D)
                            : const Color(0xFF666666),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build right side product grid
  Widget _buildRightProductGrid() {
    if (_selectedCategory == null) {
      return const Expanded(
        flex: 8,
        child: Center(child: Text('No category selected')),
      );
    }

    if (_isLoadingProducts) {
      return const Expanded(
        flex: 8,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentProducts.isEmpty) {
      return Expanded(
        flex: 8,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined,
                  size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No products in this category',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      flex: 8, // 80% width
      child: Container(
        color: Colors.white,
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 3 columns
            childAspectRatio: 0.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _currentProducts.length,
          itemBuilder: (context, index) {
            return _buildProductCard(_currentProducts[index]);
          },
        ),
      ),
    );
  }

  /// Build individual product card
  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          SlidePageRoute(
            page: ProductDetailScreen(product: product),
            direction: PageTransitionDirection.right,
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image,
                              size: 40, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.shopping_bag,
                            size: 40, color: Colors.grey),
                      ),
              ),
            ),

            // Product Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),

                    // Price Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Selling Price
                            Text(
                              '₹${product.price.toStringAsFixed(product.price.truncateToDouble() == product.price ? 0 : 2)}',
                              style: const TextStyle(
                                color: Color(0xFFD32F2F),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            // MRP (if different)
                            if (product.mrp != null &&
                                product.mrp! > product.price)
                              Text(
                                '₹${product.mrp!.toStringAsFixed(product.mrp!.truncateToDouble() == product.mrp! ? 0 : 2)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),

                        // ADD Button
                        _buildAddButton(product),
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

  /// Build ADD button with quantity counter
  Widget _buildAddButton(Product product) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final isInCart = cart.items.containsKey(product.id);

        if (!isInCart) {
          return OutlinedButton(
            onPressed: () {
              cart.addToCart(product);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.name} added to cart'),
                  duration: const Duration(milliseconds: 800),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF00C853),
              side: const BorderSide(color: Color(0xFF00C853)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: const Size(60, 30),
            ),
            child: const Text(
              'ADD',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          );
        }

        // If in cart, show quantity counter
        final quantity = cart.items[product.id]!.quantity;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF00C853),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.white, size: 14),
                onPressed: () {
                  if (quantity > 1) {
                    cart.updateQuantity(product.id, quantity - 1);
                  } else {
                    cart.removeFromCart(product.id);
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
              Text(
                '$quantity',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white, size: 14),
                onPressed: () {
                  if (quantity < product.stock) {
                    cart.addToCart(product);
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
            ],
          ),
        );
      },
    );
  }
}
