import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'cart_service.dart';
import 'cart_screen.dart';
import 'product_details_screen.dart';
import 'models.dart';
import 'providers/loading_provider.dart';
import 'services/error_handler.dart';
import 'widgets/skeleton_loader.dart';
import 'widgets/custom_error_widget.dart';
import 'config/app_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  List<Product> _products = [];
  AppError? _error;

  final List<Map<String, dynamic>> categories = [
    {'name': 'All', 'icon': Icons.grid_view, 'color': Colors.redAccent},
    {'name': 'Dairy', 'icon': Icons.water_drop, 'color': Colors.blue},
    {'name': 'Bakery', 'icon': Icons.breakfast_dining, 'color': Colors.brown},
    {'name': 'Veg', 'icon': Icons.eco, 'color': Colors.green},
    {'name': 'Snacks', 'icon': Icons.fastfood, 'color': Colors.orange},
    {'name': 'Drinks', 'icon': Icons.local_bar, 'color': Colors.purple},
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final loadingProvider = context.read<LoadingProvider>();

    try {
      // Check connectivity first
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw 'No internet connection';
      }

      loadingProvider.setLoading(LoadingType.products, true);
      _error = null;

      final response = await _supabase
          .from(AppConstants.productsTable)
          .select()
          .timeout(AppConstants.apiTimeout);

      final data = response as List<dynamic>;
      _products = data.map((json) => Product.fromJson(json)).toList();

      if (_products.isEmpty) {
        _error = AppError.noDataError();
      }
    } catch (e) {
      _error = ErrorHandler.handleError(e);
      _products = [];
    } finally {
      loadingProvider.setLoading(LoadingType.products, false);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(),
              _buildCategories(),
              _buildProductsHeader(),
              Consumer<CartService>(
                builder: (context, cart, child) => _buildProductsSection(cart),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          Consumer<CartService>(
            builder: (context, cart, child) => _buildFloatingCart(cart),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
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
                  Icon(Icons.notifications_outlined, color: Colors.white),
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
    );
  }

  Widget _buildCategories() {
    final loadingProvider = context.watch<LoadingProvider>();
    final isLoading = loadingProvider.isLoading(LoadingType.products);

    return SliverToBoxAdapter(
      child: Container(
        height: 110,
        margin: const EdgeInsets.only(top: 16),
        child: isLoading
            ? ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 6,
                itemBuilder: (context, index) => SkeletonLoader.categoryItem(),
              )
            : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (categories[index]['color'] as Color)
                                .withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            categories[index]['icon'] as IconData,
                            color: categories[index]['color'] as Color,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          categories[index]['name'] as String,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildProductsHeader() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Text(
          "Popular Items",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildProductsSection(CartService cart) {
    final loadingProvider = context.watch<LoadingProvider>();
    final isLoading = loadingProvider.isLoading(LoadingType.products);

    if (isLoading) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            mainAxisSpacing: AppConstants.gridSpacing,
            crossAxisSpacing: AppConstants.gridSpacing,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => SkeletonLoader.productCard(),
            childCount: 6,
          ),
        ),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        child: CustomErrorWidget(
          error: _error!,
          onRetry: _fetchProducts,
        ),
      );
    }

    if (_products.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text("No products found")),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          mainAxisSpacing: AppConstants.gridSpacing,
          crossAxisSpacing: AppConstants.gridSpacing,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) =>
              _buildProductGridCard(context, _products[index], cart),
          childCount: _products.length,
        ),
      ),
    );
  }

  Widget _buildFloatingCart(CartService cart) {
    if (cart.itemCount > 0) {
      return Positioned(
        left: 20,
        right: 20,
        bottom: 30,
        child: GestureDetector(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (c) => const CartScreen())),
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
                            style:
                                TextStyle(color: Colors.white54, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                const Row(
                  children: [
                    Text("View Cart",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 18),
                  ],
                )
              ],
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildProductGridCard(
      BuildContext context, Product product, CartService cart) {
    final int qty = cart.getQuantity(product.id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ProductDetailsScreen(product: product)));
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
                  child: product.imageUrl.isNotEmpty
                      ? Image.network(
                          product.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Text(
                                "No Image\nFound",
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Text(
                            "No Image\nFound",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
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
