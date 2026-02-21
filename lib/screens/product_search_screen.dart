import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../main.dart';
import '../routes/page_transitions.dart';

class ProductSearchScreen extends StatefulWidget {
  const ProductSearchScreen({super.key});

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 500);

  List<Product> _searchResults = [];
  bool _isSearching = false;
  String _lastQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  /// TOKEN-BASED SEARCH LOGIC
  Future<void> _performSearch(String query) async {
    if (query.isEmpty || query.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    if (query == _lastQuery) return;
    _lastQuery = query;

    setState(() => _isSearching = true);

    try {
      final isBarcodeSearch = RegExp(r'^\d{10,13}$').hasMatch(query.trim());

      List<Map<String, dynamic>> results;

      if (isBarcodeSearch) {
        results = await _supabase
            .from('products')
            .select()
            .eq('barcode', query.trim())
            .limit(50);
      } else {
        results = await _tokenBasedSearch(query);
      }

      setState(() {
        _searchResults = results.map((e) => Product.fromMap(e)).toList();
        _isSearching = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: $e')),
        );
      }
    }
  }

  /// Optimized token-based search using PostgreSQL's ILIKE and OR conditions
  Future<List<Map<String, dynamic>>> _tokenBasedSearch(String query) async {
    final tokens = query
        .toLowerCase()
        .split(' ')
        .where((token) => token.length >= 2)
        .toList();

    if (tokens.isEmpty) return [];

    final searchConditions = tokens.map((token) {
      return 'product_name.ilike.%$token%,brand.ilike.%$token%,category.ilike.%$token%';
    }).join(',');

    try {
      final results = await _supabase
          .from('products')
          .select()
          .or(searchConditions)
          .gt('current_stock', 0)
          .order('product_name', ascending: true)
          .limit(50);

      return results.where((product) {
        final productName = (product['product_name'] ?? '').toString().toLowerCase();
        final brand = (product['brand'] ?? '').toString().toLowerCase();
        final category = (product['category'] ?? '').toString().toLowerCase();
        final searchableText = '$productName $brand $category';
        return tokens.every((token) => searchableText.contains(token));
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF3D3D3D),
        elevation: 0,
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF3D3D3D),
          ),
          decoration: InputDecoration(
            hintText: 'Search products, brands, barcodes...',
            hintStyle: GoogleFonts.poppins(
              color: const Color(0xFF737373),
              fontSize: 14,
            ),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20, color: Color(0xFF737373)),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchResults = [];
                        _lastQuery = '';
                      });
                    },
                  )
                : IconButton(
                    icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF0C831F)),
                    tooltip: 'Scan Barcode',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Barcode scanner coming soon! For now, type barcode numbers.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
          ),
          onChanged: (value) {
            setState(() {}); // Rebuild to show/hide clear button
            _debouncer.run(() => _performSearch(value));
          },
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0C831F)),
      );
    }

    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Search for products',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: const Color(0xFF3D3D3D),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try "Maggi", "Colgate", or scan barcode',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF737373),
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: const Color(0xFF3D3D3D),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF737373),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            '${_searchResults.length} result${_searchResults.length != 1 ? 's' : ''} for "${_searchController.text}"',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF737373),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              return _buildProductCard(context, _searchResults[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
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
                      Text(
                        product.weightPackSize ?? '1 unit',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF737373),
                        ),
                      ),
                      const SizedBox(height: 4),
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
      },
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

/// DEBOUNCER: Delays search execution until user stops typing
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
