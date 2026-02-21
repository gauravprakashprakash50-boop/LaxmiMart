import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'main.dart' hide CartScreen;
import 'cart_screen.dart';
import 'routes/page_transitions.dart';
import 'widgets/skeleton_loader.dart';
import 'screens/product_search_screen.dart';
import 'screens/category_products_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _supabase
          .from('categories')
          .select()
          .order('display_order', ascending: true);

      if (mounted) {
        setState(() {
          _categories = (response as List)
              .map((e) => Category.fromJson(e))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [

              // ── APP BAR ──────────────────────────────────────────
              SliverAppBar(
                backgroundColor: Colors.white,
                floating: true,
                pinned: true,
                expandedHeight: 120,
                elevation: 0,
                shadowColor: const Color(0x12000000),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 50, 16, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Store name + notification
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: Color(0xFF0C831F), size: 18),
                            const SizedBox(width: 4),
                            const Text(
                              'LaxmiMart',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0C831F),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down,
                                size: 18, color: Color(0xFF3D3D3D)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined,
                                  color: Color(0xFF3D3D3D)),
                              onPressed: () {},
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Row 2: Clickable search bar
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            SlidePageRoute(
                              page: const ProductSearchScreen(),
                              direction: PageTransitionDirection.up,
                            ),
                          ),
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                  color: const Color(0xFFEEEEEE), width: 1),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x141C1C1C),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              children: [
                                const Icon(Icons.search,
                                    color: Color(0xFF0C831F), size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  'Search products, brands, barcodes...',
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 14),
                                ),
                                const Spacer(),
                                Icon(Icons.qr_code_scanner,
                                    color: Colors.grey[400], size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                bottom: const PreferredSize(
                  preferredSize: Size.fromHeight(1),
                  child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                ),
              ),

              // ── SECTION HEADER ────────────────────────────────────
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Text(
                    'Shop by Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3D3D3D),
                    ),
                  ),
                ),
              ),

              // ── CATEGORIES GRID ───────────────────────────────────
              if (_isLoading)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => SkeletonLoader.categoryCard(),
                      childCount: 8,
                    ),
                  ),
                )
              else if (_error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _loadCategories,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0C831F)),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_categories.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                          'No categories found.\nRun the SQL script in Supabase.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildCategoryCard(_categories[index]),
                      childCount: _categories.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // ── FLOATING CART ─────────────────────────────────────────
          if (cart.items.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  SlidePageRoute(
                    page: const CartScreen(),
                    direction: PageTransitionDirection.right,
                  ),
                ),
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C831F),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A6B19),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${cart.items.length} item${cart.items.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'View Cart',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios,
                          color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Category category) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        SlidePageRoute(
          page: CategoryProductsScreen(category: category),
          direction: PageTransitionDirection.right,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFECFFEC),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(10),
              child: category.imageUrl != null &&
                      category.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: category.imageUrl!,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.category_outlined,
                        color: Color(0xFF0C831F),
                        size: 24,
                      ),
                    )
                  : const Icon(
                      Icons.category_outlined,
                      color: Color(0xFF0C831F),
                      size: 24,
                    ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3D3D3D),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
