import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../main.dart';
import '../widgets/enhanced_product_card.dart';
import '../routes/page_transitions.dart';

class ProductSearchScreen extends StatefulWidget {
  const ProductSearchScreen({super.key});

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 500); // Wait 500ms after typing stops
  
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

    // Prevent duplicate searches
    if (query == _lastQuery) return;
    _lastQuery = query;

    setState(() => _isSearching = true);

    try {
      // Check if input is a barcode (all digits, 10-13 characters)
      final isBarcodeSearch = RegExp(r'^\d{10,13}$').hasMatch(query.trim());

      List<Map<String, dynamic>> results;

      if (isBarcodeSearch) {
        // EXACT BARCODE MATCH (Instant)
        results = await _supabase
            .from('products')
            .select()
            .eq('barcode', query.trim())
            .limit(50);
      } else {
        // TOKEN-BASED TEXT SEARCH
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
    // Split query into tokens (words)
    final tokens = query
        .toLowerCase()
        .split(' ')
        .where((token) => token.length >= 2)
        .toList();

    if (tokens.isEmpty) return [];

    // Build SQL query: product_name ILIKE '%token1%' AND product_name ILIKE '%token2%'
    // OR brand ILIKE '%token%' OR barcode = 'query'
    
    // For PostgreSQL, we'll use multiple OR conditions for flexible matching
    final searchConditions = tokens.map((token) {
      return 'product_name.ilike.%$token%,brand.ilike.%$token%,category.ilike.%$token%';
    }).join(',');

    try {
      final results = await _supabase
          .from('products')
          .select()
          .or(searchConditions)
          .gt('current_stock', 0) // Only show in-stock items
          .order('product_name', ascending: true)
          .limit(50);

      // Filter results in-memory to ensure ALL tokens are present
      return results.where((product) {
        final productName = (product['product_name'] ?? '').toString().toLowerCase();
        final brand = (product['brand'] ?? '').toString().toLowerCase();
        final category = (product['category'] ?? '').toString().toLowerCase();
        final searchableText = '$productName $brand $category';

        // Check if ALL tokens are present
        return tokens.every((token) => searchableText.contains(token));
      }).toList();
    } catch (e) {
      print('Search error: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Products'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search by name, brand, or barcode...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF00A82D)),
                
                // BARCODE SCANNER BUTTON
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _lastQuery = '';
                          });
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF00A82D)),
                      tooltip: 'Scan Barcode',
                      onPressed: () {
                        // TODO: Integrate barcode scanner package
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Barcode scanner coming soon!\nFor now, type barcode numbers.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00A82D), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                // Debounce: Wait 500ms after user stops typing before searching
                _debouncer.run(() => _performSearch(value));
              },
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Search for products',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Try "Maggi", "Colgate", or scan barcode',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
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
            Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${_searchResults.length} result${_searchResults.length != 1 ? 's' : ''} found',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              return EnhancedProductCard(
                product: _searchResults[index],
                onTap: () {
                  Navigator.push(
                    context,
                    SlidePageRoute(
                      page: ProductDetailScreen(product: _searchResults[index]),
                      direction: PageTransitionDirection.right,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
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
