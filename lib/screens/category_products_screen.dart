import 'package:flutter/material.dart';
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
          .eq('category_id', widget.category.id)
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
          .eq('category_id', widget.category.id)
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
        title: Text(widget.category.name),
        elevation: 0,
      ),
      body: Stack(
        children: [
          _isLoading
              ? GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: 6,
                  itemBuilder: (_, __) => SkeletonLoader.productCard(),
                )
              : _products.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No products in this category',
                              style: TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                    )
                  : GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _products.length + (_isLoadingMore ? 2 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _products.length) {
                          return SkeletonLoader.productCard();
                        }
                        return _buildProductCard(context, _products[index], cart);
                      },
                    ),

          // Floating Cart
          if (cart.items.isNotEmpty)
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${cart.items.length} item${cart.items.length > 1 ? 's' : ''}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        '₹${cart.totalAmount.toStringAsFixed(0)} • View Cart →',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
    final qty = cart.getQuantity(product.id);

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
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                padding: const EdgeInsets.all(16),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
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
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  if (product.weightPackSize != null)
                    Text(
                      product.weightPackSize!,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₹${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                          ),
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
                      ),
                      qty == 0
                          ? InkWell(
                              onTap: () => cart.addToCart(product),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFF00A82D)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'ADD',
                                  style: TextStyle(
                                    color: Color(0xFF00A82D),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF00A82D),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      if (qty > 1) {
                                        cart.updateQuantity(product.id, qty - 1);
                                      } else {
                                        cart.removeFromCart(product.id);
                                      }
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Icon(Icons.remove, color: Colors.white, size: 16),
                                    ),
                                  ),
                                  Text(
                                    '$qty',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => cart.addToCart(product),
                                    child: const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Icon(Icons.add, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
}
