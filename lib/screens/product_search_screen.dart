import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../main.dart';
import '../routes/page_transitions.dart';
import '../widgets/enhanced_product_card.dart';

class ProductSearchScreen extends StatefulWidget {
  const ProductSearchScreen({super.key});

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _supabase = Supabase.instance.client;
  List<Product> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.length >= 2) {
        _performSearch(query);
      } else {
        setState(() => _searchResults = []);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);

    try {
      final response = await _supabase
          .from('products')
          .select()
          .ilike('product_name', '%$query%')
          .gt('current_stock', 0)
          .limit(20);

      setState(() {
        _searchResults = response.map((e) => Product.fromMap(e)).toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search products...',
            border: InputBorder.none,
            hintStyle: const TextStyle(color: Colors.white70),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchResults = []);
                    },
                  )
                : null,
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
          onChanged: _onSearchChanged,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Empty state - show search suggestions
    if (_searchController.text.isEmpty) {
      return _buildSearchSuggestions();
    }

    // Loading state
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    // No results
    if (_searchResults.isEmpty) {
      return _buildNoResults();
    }

    // Show results in grid
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _searchResults.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        return EnhancedProductCard(
          product: _searchResults[index],
          onTap: () {
            Navigator.push(
              context,
              SlidePageRoute(
                page: ProductDetailScreen(
                  product: _searchResults[index],
                ),
                direction: PageTransitionDirection.right,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchSuggestions() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Search for products',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
