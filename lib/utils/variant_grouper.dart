import '../main.dart';

/// Represents a single variant of a product (different size/pack)
class ProductVariant {
  final int id;
  final String size; // e.g., "100g", "200g", "500ml"
  final double price;
  final double? mrp;
  final int stock;

  ProductVariant({
    required this.id,
    required this.size,
    required this.price,
    this.mrp,
    required this.stock,
  });
}

/// Represents a base product with multiple size/pack variants
class GroupedProduct {
  final String baseName; // e.g., "Colgate Strong Teeth"
  final String? imageUrl;
  final String? description;
  final String? category;
  final List<ProductVariant> variants;
  
  /// Currently selected variant (defaults to first)
  ProductVariant get defaultVariant => variants.first;

  GroupedProduct({
    required this.baseName,
    this.imageUrl,
    this.description,
    this.category,
    required this.variants,
  });
}

/// Utility class for grouping products by base name and extracting variants
class VariantGrouper {
  /// Extract base name from product name by removing size patterns
  /// "Colgate Strong Teeth 100g" -> "Colgate Strong Teeth"
  /// "Amul Milk 500ml" -> "Amul Milk"
  static String getBaseName(String productName) {
    // Remove size patterns: 100g, 200ml, 1kg, 500gm, etc.
    final sizePattern = RegExp(
      r'\s*\d+(\.\d+)?\s*(g|gm|kg|ml|l|ltr|litre|pcs|pack)\b',
      caseSensitive: false,
    );
    String baseName = productName.replaceAll(sizePattern, '').trim();
    
    // Also remove trailing numbers and common size descriptors
    baseName = baseName.replaceAll(RegExp(r'\s+\d+\s*$'), '').trim();
    baseName = baseName.replaceAll(
      RegExp(r'\s+(small|medium|large|mini|jumbo|family|pack)$', caseSensitive: false),
      '',
    ).trim();
    
    return baseName;
  }

  /// Extract size from product name
  /// "Colgate Strong Teeth 100g" -> "100g"
  /// "Amul Milk 500ml" -> "500ml"
  static String extractSize(String productName) {
    final sizePattern = RegExp(
      r'(\d+(\.\d+)?\s*(g|gm|kg|ml|l|ltr|litre|pcs|pack))\b',
      caseSensitive: false,
    );
    final match = sizePattern.firstMatch(productName);
    
    if (match != null) {
      return match.group(0)!.trim();
    }
    
    // Fallback: check for common size descriptors
    final descriptorPattern = RegExp(
      r'\b(small|medium|large|mini|jumbo|family pack)\b',
      caseSensitive: false,
    );
    final descriptorMatch = descriptorPattern.firstMatch(productName);
    if (descriptorMatch != null) {
      return descriptorMatch.group(0)!;
    }
    
    return 'Standard';
  }

  /// Group products by base name into GroupedProduct objects
  /// Returns list of grouped products with variants
  static List<GroupedProduct> groupProducts(List<Product> products) {
    final Map<String, List<Product>> grouped = {};
    
    // Group by base name
    for (var product in products) {
      final baseName = getBaseName(product.name);
      grouped.putIfAbsent(baseName, () => []).add(product);
    }
    
    // Convert to GroupedProduct objects
    final List<GroupedProduct> result = [];
    
    grouped.forEach((baseName, productList) {
      // Sort by price (smallest to largest)
      productList.sort((a, b) => a.price.compareTo(b.price));
      
      final variants = productList.map((p) => ProductVariant(
        id: p.id,
        size: p.weightPackSize ?? extractSize(p.name),
        price: p.price,
        mrp: p.mrp,
        stock: p.stock,
      )).toList();
      
      result.add(GroupedProduct(
        baseName: baseName,
        imageUrl: productList.first.imageUrl,
        description: productList.first.description,
        category: productList.first.category,
        variants: variants,
      ));
    });
    
    return result;
  }

  /// Filter grouped products to only show those with multiple variants
  static List<GroupedProduct> filterMultiVariant(List<GroupedProduct> grouped) {
    return grouped.where((gp) => gp.variants.length > 1).toList();
  }

  /// Get total number of variants across all grouped products
  static int getTotalVariantCount(List<GroupedProduct> grouped) {
    return grouped.fold(0, (sum, gp) => sum + gp.variants.length);
  }
}
