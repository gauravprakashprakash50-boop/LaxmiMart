import '../main.dart';

class CategoryHelper {
  // Define the category hierarchy
  static const Map<String, List<String>> categoryMap = {
    // Dairy, Bread & Eggs
    'Milk & Curd': ['milk', 'dahi', 'curd', 'buttermilk', 'chhaas', 'amul'],
    'Cheese & Butter': ['cheese', 'butter', 'paneer', 'ghee'],
    'Bread & Bakery': ['bread', 'bun', 'rusk', 'cake', 'croissant', 'pav'],

    // Snacks & Munchies
    'Chips & Crisps': ['lays', 'pringles', 'bingo', 'nachos', 'wafers', 'chips'],
    'Biscuits': ['parle', 'oreo', 'bourbon', 'good day', 'cookies', 'biscuit'],
    'Chocolates': [
      'cadbury',
      'kitkat',
      'munch',
      'silk',
      '5 star',
      'dairy milk',
      'chocolate'
    ],

    // Cold Drinks & Juices
    'Soft Drinks': ['pepsi', 'coke', 'thums up', 'sprite', 'fanta', 'cola'],
    'Juices': ['real', 'tropicana', 'maaza', 'fruity', 'slice', 'juice'],
    'Energy & Health': ['red bull', 'sting', 'horlicks', 'bournvita', 'boost'],

    // Personal Care
    'Bath & Body': ['soap', 'dettol', 'lux', 'pears', 'body wash', 'santoor'],
    'Hair Care': ['shampoo', 'conditioner', 'hair oil', 'head & shoulders'],
    'Skincare': ['face wash', 'cream', 'lotion', 'powder', 'fair', 'glow'],

    // Household
    'Cleaning': ['detergent', 'surf', 'rin', 'vim', 'harpic', 'lizol'],
    'Kitchen': ['maggi', 'noodles', 'pasta', 'atta', 'rice', 'dal', 'oil'],
  };

  // Get subcategory for a product based on name
  static String getSubcategory(String productName) {
    final nameLower = productName.toLowerCase();

    for (var entry in categoryMap.entries) {
      final subcategory = entry.key;
      final keywords = entry.value;

      for (var keyword in keywords) {
        if (nameLower.contains(keyword)) {
          return subcategory;
        }
      }
    }

    return 'Others'; // Default category
  }

  // Get icon URL for subcategory
  static String getIconUrl(String subcategory) {
    const iconMap = {
      // Dairy icons
      'Milk & Curd': 'https://cdn-icons-png.flaticon.com/512/2674/2674486.png',
      'Cheese & Butter': 'https://cdn-icons-png.flaticon.com/512/3050/3050163.png',
      'Bread & Bakery': 'https://cdn-icons-png.flaticon.com/512/2553/2553691.png',

      // Snacks icons
      'Chips & Crisps': 'https://cdn-icons-png.flaticon.com/512/3480/3480822.png',
      'Biscuits': 'https://cdn-icons-png.flaticon.com/512/541/541732.png',
      'Chocolates': 'https://cdn-icons-png.flaticon.com/512/3076/3076079.png',

      // Drinks icons
      'Soft Drinks': 'https://cdn-icons-png.flaticon.com/512/2405/2405597.png',
      'Juices': 'https://cdn-icons-png.flaticon.com/512/2553/2553642.png',
      'Energy & Health': 'https://cdn-icons-png.flaticon.com/512/924/924514.png',

      // Personal Care icons
      'Bath & Body': 'https://cdn-icons-png.flaticon.com/512/2553/2553642.png',
      'Hair Care': 'https://cdn-icons-png.flaticon.com/512/2933/2933116.png',
      'Skincare': 'https://cdn-icons-png.flaticon.com/512/3774/3774299.png',

      // Household icons
      'Cleaning': 'https://cdn-icons-png.flaticon.com/512/3050/3050239.png',
      'Kitchen': 'https://cdn-icons-png.flaticon.com/512/3480/3480826.png',

      // Default
      'Others': 'https://cdn-icons-png.flaticon.com/512/1170/1170678.png',
    };

    return iconMap[subcategory] ?? iconMap['Others']!;
  }

  // Group products by subcategory
  static Map<String, List<Product>> groupProducts(List<Product> products) {
    final grouped = <String, List<Product>>{};

    for (var product in products) {
      final subcategory = getSubcategory(product.name);
      grouped.putIfAbsent(subcategory, () => []).add(product);
    }

    return grouped;
  }
}
