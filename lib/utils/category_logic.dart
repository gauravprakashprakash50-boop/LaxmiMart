import '../main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryHelper {
  static final _supabase = Supabase.instance.client;

  /// Fetch unique categories from database
  static Future<List<String>> getCategories() async {
    try {
      final response = await _supabase
          .from('products')
          .select('category')
          .not('category', 'is', null)
          .gt('current_stock', 0); // Only categories with in-stock items

      // Extract unique categories
      final categories = <String>{};
      for (var row in response) {
        final category = row['category'];
        if (category != null && category.toString().isNotEmpty) {
          categories.add(category.toString());
        }
      }

      final sortedCategories = categories.toList()..sort();
      
      // Remove "Others" if exists and add it to the end
      sortedCategories.remove('Others');
      if (categories.contains('Others')) {
        sortedCategories.add('Others');
      }

      return sortedCategories;
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  /// Fetch products by category
  static Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('category', category)
          .gt('current_stock', 0)
          .order('product_name', ascending: true);

      return response.map((e) => Product.fromMap(e)).toList();
    } catch (e) {
      print('Error fetching products for category $category: $e');
      return [];
    }
  }

  /// Get icon URL for category
  static String getIconUrl(String category) {
    const iconMap = {
      'Dairy, Bread & Eggs': 'https://cdn-icons-png.flaticon.com/512/2674/2674486.png',
      'Snacks & Munchies': 'https://cdn-icons-png.flaticon.com/512/3480/3480822.png',
      'Cold Drinks & Juices': 'https://cdn-icons-png.flaticon.com/512/2405/2405597.png',
      'Personal Care': 'https://cdn-icons-png.flaticon.com/512/2933/2933116.png',
      'Household Essentials': 'https://cdn-icons-png.flaticon.com/512/3050/3050239.png',
      'Instant Food': 'https://cdn-icons-png.flaticon.com/512/857/857681.png',
      'Kitchen Staples': 'https://cdn-icons-png.flaticon.com/512/3480/3480826.png',
      'Others': 'https://cdn-icons-png.flaticon.com/512/1170/1170678.png',
    };
    
    return iconMap[category] ?? iconMap['Others']!;
  }

  /// Legacy method for backward compatibility (used by HomeScreen)
  /// Groups products by database category
  static Map<String, List<Product>> groupProducts(List<Product> products) {
    final grouped = <String, List<Product>>{};
    
    for (var product in products) {
      final category = product.category ?? 'Others';
      grouped.putIfAbsent(category, () => []).add(product);
    }
    
    return grouped;
  }
}
