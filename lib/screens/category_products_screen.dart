import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../main.dart';
import '../routes/page_transitions.dart';
import '../widgets/skeleton_loader.dart';

class CategoryProductsScreen extends StatefulWidget {
  final Category category;
  const CategoryProductsScreen({super.key, required this.category});

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final _supabase = Supabase.instance.client;
  final _scrollController = ScrollController();

  List<Product> _products = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadProducts() async {
    setState(() { _isLoading = true; });
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('category', widget.category.name)
          .gt('current_stock', 0)
          .order('product_name', ascending: true)
          .range(0, _pageSize - 1);

      setState(() {
        _products = (response as List).map((e) => Product.fromMap(e)).toList();
        _hasMore = _products.length == _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() { _isLoadingMore = true; });
    try {
      final offset = _products.length;
      final response = await _supabase
          .from('products')
          .select()
          .eq('category', widget.category.name)
          .gt('current_stock', 0)
          .order('product_name', ascending: true)
          .range(offset, offset + _pageSize - 1);

      final newProducts = (response as List).map((e) => Product.fromMap(e)).toList();

      setState(() {
        _products.addAll(newProducts);
        _hasMore = newProducts.length == _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() { _isLoadingMore = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF3D3D3D),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.category.name,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3D3D3D),
              ),
            ),
            if (!_isLoading)
              Text(
                '${_products.length} products',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFF737373),
                ),
              ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: Stack(
        children: [
          _isLoading
              ? GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: 6,
                  itemBuilder: (_, __) => SkeletonLoader.productCard(),
                )
              : _products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No products in this category',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: const Color(0xFF737373),
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.68,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _products.length + (_isLoadingMore ? 2 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _products.length) {
                          return SkeletonLoader.productCard();
                        }
                        return _buildProductCard(context, _products[index], cart);
                      },
                    ),

          // Floating Cart Bar
          if (cart.items.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
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
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C831F),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Color(0x33000000), blurRadius: 5, offset: Offset(0, 3)),
                      BoxShadow(color: Color(0x24000000), blurRadius: 10, offset: Offset(0, 6)),
                      BoxShadow(color: Color(0x1F000000), blurRadius: 18, offset: Offset(0, 1)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A6B19),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${cart.items.length} item${cart.items.length > 1 ? 's' : ''}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'View Cart',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product, CartProvider cart) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        SlidePageRoute(
          page: ProductDetailScreen(product: product),
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
              color: Color(0x261C1C1C),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Area
            Container(
              height: 130,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              padding: const EdgeInsets.all(16),
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0C831F)),
                      ),
                      errorWidget: (_, __, ___) => Icon(
                        Icons.shopping_bag_outlined,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                    )
                  : Icon(
                      Icons.shopping_bag_outlined,
                      size: 40,
                      color: Colors.grey[400],
                    ),
            ),

            // Content Area
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Weight/unit tag
                  Text(
                    product.weightPackSize ?? '1 unit',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF737373),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Product name
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF3D3D3D),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Price row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
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
                      ),
                      _buildAddButton(product, cart),
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

  Widget _buildAddButton(Product product, CartProvider cart) {
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
            onTap: () => cart.addToCart(product),
            child: const Icon(Icons.add, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }
}
