import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cart_service.dart';
import 'cart_screen.dart';
import 'product_details_screen.dart'; // NEW IMPORT
import 'models.dart';
import 'routes/page_transitions.dart';
import 'widgets/skeleton_loader.dart';
import 'services/error_handler.dart';
import 'providers/connectivity_provider.dart';
import 'widgets/common_widgets.dart';
import 'widgets/cached_image_widget.dart';
import 'core/exceptions/app_exceptions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;

  final List<Map<String, dynamic>> categories = [
    {'name': 'All', 'icon': Icons.grid_view, 'color': Colors.redAccent},
    {'name': 'Dairy', 'icon': Icons.water_drop, 'color': Colors.blue},
    {'name': 'Bakery', 'icon': Icons.breakfast_dining, 'color': Colors.brown},
    {'name': 'Veg', 'icon': Icons.eco, 'color': Colors.green},
    {'name': 'Snacks', 'icon': Icons.fastfood, 'color': Colors.orange},
    {'name': 'Drinks', 'icon': Icons.local_bar, 'color': Colors.purple},
  ];

  bool _isLoading = true;
  String? _errorMessage;
  List<Product> _products = [];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check connectivity first
      final connectivityProvider =
          Provider.of<ConnectivityProvider>(context, listen: false);
      if (!connectivityProvider.isConnected) {
        throw NetworkException('No internet connection');
      }

      // FIXED: Removed the 'if (response == null)' check.
      // Supabase .select() returns the data directly or throws an error.
      final response = await _supabase.from('products').select();

      final data = response as List<dynamic>;
      final products = data.map((json) => Product.fromJson(json)).toList();

      if (mounted) {
        setState(() {
          _products = _selectedCategory == 'All'
              ? products
              : products
                  .where((p) =>
                      p.category.toLowerCase() ==
                      _selectedCategory.toLowerCase())
                  .toList();
          _isLoading = false;
        });
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load products: ${e.message}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
      debugPrint('DB Error: $e');
    }
  }

  void _filterByCategory(String category) {
    if (_selectedCategory == category) return;

    setState(() {
      _selectedCategory = category;
    });
    _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // --- 1. APP BAR ---
              SliverAppBar(
                backgroundColor: const Color(0xFFD32F2F),
                floating: true,
                pinned: true,
                expandedHeight: 140,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    decoration: const BoxDecoration(
                      color: Color(0xFFD32F2F),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "LaxmiMart",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold),
                            ),
                            Icon(Icons.notifications_outlined,
                                color: Colors.white),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: const Row(
                            children: [
                              Icon(Icons.search, color: Colors.grey),
                              SizedBox(width: 8),
                              Text("Search products...",
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // --- 2. CATEGORIES ---
              SliverToBoxAdapter(
                child: Container(
                  height: 110,
                  margin: const EdgeInsets.only(top: 16),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = _selectedCategory == category['name'];

                      return Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: GestureDetector(
                          onTap: () =>
                              _filterByCategory(category['name'] as String),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (category['color'] as Color)
                                          .withAlpha(50)
                                      : (category['color'] as Color)
                                          .withAlpha(30),
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(
                                          color: category['color'] as Color,
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: Icon(
                                  category['icon'] as IconData,
                                  color: category['color'] as Color,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                category['name'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // --- 3. PRODUCTS ---
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    "Popular Items",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // PRODUCTS SECTION
              if (_isLoading)
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => SkeletonLoader.productCard(),
                      childCount: 6,
                    ),
                  ),
                )
              else if (_errorMessage != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: ErrorDisplayWidget(
                      error: ErrorHandler.handleError(_errorMessage,
                          onRetry: _fetchProducts),
                    ),
                  ),
                )
              else if (_products.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "No products found",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Try changing the category or check back later",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildProductGridCard(
                          context, _products[index], cart),
                      childCount: _products.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // --- 4. FLOATING CART ---
          if (cart.itemCount > 0)
            Positioned(
              left: 20,
              right: 20,
              bottom: 30,
              child: GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    SlidePageRoute(
                      page: const CartScreen(),
                      direction: PageTransitionDirection.right,
                    )),
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha(50),
                          blurRadius: 10,
                          offset: const Offset(0, 5))
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(10)),
                            child: Text("${cart.itemCount}",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("₹${cart.totalAmount}",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const Text("Total",
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                      const Row(
                        children: [
                          Text("View Cart",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 18),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductGridCard(
      BuildContext context, Product product, CartService cart) {
    final int qty = cart.getQuantity(product.id);

    return GestureDetector(
      // NEW: Navigate to Details Page on tap
      onTap: () {
        Navigator.push(
            context,
            SlidePageRoute(
                page: ProductDetailsScreen(product: product),
                direction: PageTransitionDirection.right));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withAlpha(20),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ImageCacheManager.buildProductImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(product.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("₹${product.price}",
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 14)),
                      qty == 0
                          ? InkWell(
                              onTap: () => cart.addToCart(product),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.add,
                                    color: Color(0xFFD32F2F), size: 20),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFD32F2F),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                children: [
                                  InkWell(
                                      onTap: () =>
                                          cart.removeSingleItem(product.id),
                                      child: const Icon(Icons.remove,
                                          color: Colors.white, size: 14)),
                                  const SizedBox(width: 8),
                                  Text("$qty",
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                  const SizedBox(width: 8),
                                  InkWell(
                                      onTap: () => cart.addToCart(product),
                                      child: const Icon(Icons.add,
                                          color: Colors.white, size: 14)),
                                ],
                              ),
                            ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
