import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'routes/page_transitions.dart';
import 'screens/product_search_screen.dart';
import 'screens/category_products_screen.dart';
import 'screens/category_split_view_screen.dart';
import 'screens/order_history_screen.dart';
import 'widgets/skeleton_loader.dart';
import 'providers/connectivity_provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- 1. CONFIGURATION — load from .env asset ---
  await dotenv.load(fileName: '.env');
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ??
      (throw Exception('SUPABASE_URL not set in .env'));
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ??
      (throw Exception('SUPABASE_ANON_KEY not set in .env'));

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: const LaxmiMartApp(),
    ),
  );
}

// --- 2. MAIN APP WIDGET ---
class LaxmiMartApp extends StatelessWidget {
  const LaxmiMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Odyit',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0C831F),
          primary: const Color(0xFF0C831F),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF3D3D3D),
          elevation: 0,
          shadowColor: const Color(0x12000000),
          titleTextStyle: GoogleFonts.poppins(
            color: const Color(0xFF3D3D3D),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0C831F),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const OfflineBannerWrapper(child: HomeScreen()),
    );
  }
}

// --- OFFLINE BANNER WRAPPER ---
// Listens to ConnectivityProvider and overlays a non-dismissible banner
// at the top of every screen when the device has no internet connection.
class OfflineBannerWrapper extends StatelessWidget {
  final Widget child;
  const OfflineBannerWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isConnected = context.select<ConnectivityProvider, bool>(
      (p) => p.isConnected,
    );

    return Stack(
      children: [
        child,
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          top: isConnected ? -60 : 0,
          left: 0,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              bottom: false,
              child: Container(
                width: double.infinity,
                color: const Color(0xFFB71C1C),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'No internet connection',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// --- 3. STATE MANAGEMENT ---

class Category {
  final String id;
  final String name;
  final String? imageUrl;

  Category({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'].toString(),
      name: json['name'] as String,
      imageUrl: json['image_url'] as String?,
    );
  }
}

class Product {
  final int id;
  final String name;
  final double price;
  final int stock;
  final String? imageUrl;
  final String? description;
  final double? mrp;
  final String? weightPackSize;
  final String? category;
  final int? categoryId;
  final String? barcode;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.imageUrl,
    this.description,
    this.mrp,
    this.weightPackSize,
    this.category,
    this.categoryId,
    this.barcode,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['product_name'] ?? 'Unknown Item',
      price: (map['selling_price'] ?? 0).toDouble(),
      stock: map['current_stock'] ?? 0,
      imageUrl: map['image_urls'],
      description: map['description'] ?? 'No description available.',
      mrp: map['mrp'] != null ? (map['mrp'] as num).toDouble() : null,
      weightPackSize: map['weight_pack_size'],
      category: map['category'],
      categoryId: map['category_id'] as int?,
      barcode: map['barcode']?.toString(),
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) => Product.fromMap(json);

  Map<String, dynamic> toJson() => {
    'id':               id,
    'product_name':     name,
    'selling_price':    price,
    'current_stock':    stock,
    'image_urls':       imageUrl,
    'description':      description,
    'mrp':              mrp,
    'weight_pack_size': weightPackSize,
    'category':         category,
    'category_id':      categoryId,
    'barcode':          barcode,
  };
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    product: Product.fromJson(json['product'] as Map<String, dynamic>),
    quantity: json['quantity'] as int,
  );
}

class CartProvider extends ChangeNotifier {
  static const _prefsKey = 'laxmimart_cart';
  final Map<int, CartItem> _items = {};

  Map<int, CartItem> get items => _items;

  CartProvider() {
    _loadCart();
  }

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, item) {
      total += item.product.price * item.quantity;
    });
    return total;
  }

  void addToCart(Product product) {
    if (_items.containsKey(product.id)) {
      if (_items[product.id]!.quantity < product.stock) {
        _items[product.id]!.quantity += 1;
      }
    } else {
      _items[product.id] = CartItem(product: product);
    }
    notifyListeners();
    _saveCart();
  }

  void updateQuantity(int productId, int newQuantity) {
    if (_items.containsKey(productId)) {
      if (newQuantity > 0 && newQuantity <= _items[productId]!.product.stock) {
        _items[productId]!.quantity = newQuantity;
        notifyListeners();
        _saveCart();
      } else if (newQuantity <= 0) {
        removeFromCart(productId);
      }
    }
  }

  bool isInCart(int productId) => _items.containsKey(productId);

  int getQuantity(int productId) =>
      _items.containsKey(productId) ? _items[productId]!.quantity : 0;

  void removeFromCart(int productId) {
    _items.remove(productId);
    notifyListeners();
    _saveCart();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
    _saveCart();
  }

  // ── Persistence ────────────────────────────────────────────────────────

  Future<void> _loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      for (final entry in decoded) {
        final item = CartItem.fromJson(entry as Map<String, dynamic>);
        _items[item.product.id] = item;
      }
      notifyListeners();
    } catch (_) {
      // Corrupted prefs — start with empty cart
    }
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_items.values.map((i) => i.toJson()).toList());
      await prefs.setString(_prefsKey, encoded);
    } catch (_) {
      // Ignore save failures silently
    }
  }
}

// --- 4. SCREENS ---

// A. HOME SCREEN — Category-first layout
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
    setState(() { _isLoading = true; _error = null; });
    try {
      // Query the dedicated categories table
      final response = await _supabase
          .from('categories')
          .select('id, name, image_url')
          .order('name', ascending: true);

      final List<Category> cats = (response as List).map((row) {
        return Category(
          id: row['id'].toString(),
          name: row['name'] as String,
          imageUrl: row['image_url'] as String?,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _categories = cats;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fallback: derive categories from the text category column in products
      try {
        final response = await _supabase
            .from('products')
            .select('category')
            .not('category', 'is', null)
            .gt('current_stock', 0);

        final Set<String> seen = {};
        final List<Category> cats = [];
        for (final row in (response as List)) {
          final name = row['category'] as String?;
          if (name != null && name.isNotEmpty && seen.add(name)) {
            cats.add(Category(id: name, name: name));
          }
        }
        cats.sort((a, b) => a.name.compareTo(b.name));

        if (mounted) {
          setState(() {
            _categories = cats;
            _isLoading = false;
          });
        }
      } catch (e2) {
        if (mounted) {
          setState(() { _error = e2.toString(); _isLoading = false; });
        }
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
                expandedHeight: 80,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    padding: const EdgeInsets.fromLTRB(16, 48, 16, 10),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: App name + Search
                        Row(
                          children: [
                            Text(
                              'Odyit',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF0C831F),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.search, color: Color(0xFF0C831F), size: 26),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  SlidePageRoute(
                                    page: const ProductSearchScreen(),
                                    direction: PageTransitionDirection.up,
                                  ),
                                );
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.grid_view_rounded, color: Color(0xFF0C831F), size: 24),
                              tooltip: 'Browse by category',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  SlidePageRoute(
                                    page: const CategorySplitViewScreen(),
                                    direction: PageTransitionDirection.right,
                                  ),
                                );
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                  child: Text(
                    'Shop by Category',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3D3D3D),
                    ),
                  ),
                ),
              ),

              // ── CATEGORIES GRID ───────────────────────────────────
              if (_isLoading)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.75,
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
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Color(0xFF0C831F)),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadCategories,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildCategoryCard(_categories[index]),
                      childCount: _categories.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
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

  Widget _buildCategoryCard(Category category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          SlidePageRoute(
            page: CategoryProductsScreen(category: category),
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
              child: category.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: category.imageUrl!,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0C831F)),
                      errorWidget: (_, __, ___) => const Icon(Icons.category, color: Color(0xFF0C831F)),
                    )
                  : const Icon(Icons.category, color: Color(0xFF0C831F)),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3D3D3D),
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

// B. PRODUCT DETAILS SCREEN
class ProductDetailScreen extends StatelessWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final bool outOfStock = product.stock == 0;
    final bool hasMrp = product.mrp != null && product.mrp! > product.price;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Product Image ─────────────────────────────────────────
            Container(
              height: 280,
              color: const Color(0xFFF5F5F5),
              padding: const EdgeInsets.all(24),
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF0C831F),
                        ),
                      ),
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.shopping_bag_outlined,
                        size: 80,
                        color: Color(0xFFBDBDBD),
                      ),
                    )
                  : const Icon(
                      Icons.shopping_bag_outlined,
                      size: 80,
                      color: Color(0xFFBDBDBD),
                    ),
            ),

            // ── Product Info ──────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Weight / pack size tag
                  if (product.weightPackSize != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.weightPackSize!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF757575),
                        ),
                      ),
                    ),

                  // Product name
                  Text(
                    product.name,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF212121),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Price row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF212121),
                        ),
                      ),
                      if (hasMrp) ...
                        [
                          const SizedBox(width: 10),
                          Text(
                            '₹${product.mrp!.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: const Color(0xFF9E9E9E),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${(((product.mrp! - product.price) / product.mrp!) * 100).toStringAsFixed(0)}% off',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
                      const Spacer(),
                      // Out of stock badge
                      if (outOfStock)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Out of Stock',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFC62828),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description
                  if (product.description != null &&
                      product.description!.isNotEmpty) ...
                    [
                      Text(
                        'Description',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF424242),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.description!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF616161),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                  // ── ADD / Quantity Stepper ────────────────────────────
                  Consumer<CartProvider>(
                    builder: (context, cart, _) {
                      final qty = cart.getQuantity(product.id);

                      if (outOfStock) {
                        return SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: null,
                            style: OutlinedButton.styleFrom(
                              side:
                                  const BorderSide(color: Color(0xFFBDBDBD)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              'Out of Stock',
                              style: GoogleFonts.poppins(
                                  color: const Color(0xFFBDBDBD),
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        );
                      }

                      if (qty == 0) {
                        return SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () => cart.addToCart(product),
                            icon: const Icon(Icons.add_shopping_cart_outlined,
                                size: 20),
                            label: Text(
                              'ADD TO CART',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        );
                      }

                      // Stepper
                      return Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0C831F),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      if (qty > 1) {
                                        cart.updateQuantity(
                                            product.id, qty - 1);
                                      } else {
                                        cart.removeFromCart(product.id);
                                      }
                                    },
                                    icon: const Icon(Icons.remove,
                                        color: Colors.white, size: 22),
                                  ),
                                  Text(
                                    '$qty',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: qty < product.stock
                                        ? () => cart.addToCart(product)
                                        : null,
                                    icon: const Icon(Icons.add,
                                        color: Colors.white, size: 22),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
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

// C. CART SCREEN
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final items = cart.items.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Order History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OrderHistoryScreen(),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 100,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your cart is empty',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add some products to get started',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.shopping_bag),
                          label: const Text('Start Shopping'),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (ctx, i) => const Divider(),
                    itemBuilder: (ctx, i) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red.shade50,
                        child: Text('${items[i].quantity}x',
                            style: const TextStyle(color: Colors.red)),
                      ),
                      title: Text(items[i].product.name),
                      subtitle: Text('₹${items[i].product.price} each'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('₹${items[i].product.price * items[i].quantity}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.grey),
                            onPressed: () =>
                                cart.removeFromCart(items[i].product.id),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5))
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('₹${cart.totalAmount}',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00A82D))),
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: items.isEmpty
                        ? null
                        : () {
                            Navigator.of(context).push(
                              SlidePageRoute(
                                page: const CheckoutScreen(),
                                direction: PageTransitionDirection.right,
                              ),
                            );
                          },
                    child: const Text('PROCEED TO CHECKOUT',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// D. CHECKOUT SCREEN
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  // Fix: dispose controllers to prevent memory leaks
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final cart = Provider.of<CartProvider>(context, listen: false);
    final supabase = Supabase.instance.client;

    try {
      // Build order items list for the RPC (no order_id needed — the DB assigns it)
      final orderItems = cart.items.values.map((cartItem) => {
        'product_id':   cartItem.product.id,
        'product_name': cartItem.product.name,
        'quantity':     cartItem.quantity,
        'unit_price':   cartItem.product.price,
        'total_price':  cartItem.product.price * cartItem.quantity,
      }).toList();

      // Single atomic RPC — upserts customer, creates order, inserts items
      // in one PostgreSQL transaction. Rolls back everything on any failure.
      final result = await supabase.rpc(
        'create_order_atomic',
        params: {
          'p_customer_phone':   _phoneController.text.trim(),
          'p_customer_name':    _nameController.text.trim(),
          'p_customer_address': _addressController.text.trim(),
          'p_total_amount':     cart.totalAmount,
          'p_order_items':      orderItems,
        },
      ) as Map<String, dynamic>;

      final orderId = result['order_id'];

      cart.clearCart();
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Order Placed!'),
            content: Text('Order ID: #$orderId\nWe will contact you shortly.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Back to Home'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'Full Name', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixText: '+91 ',
                  counterText: '',        // hide the built-in counter
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Phone number required';
                  if (val.length != 10) return 'Must be exactly 10 digits';
                  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(val)) {
                    return 'Enter a valid Indian mobile number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                    labelText: 'Address', border: OutlineInputBorder()),
                maxLines: 3,
                validator: (val) => val!.isEmpty ? 'Enter address' : null,
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitOrder,
                        child: const Text('CONFIRM ORDER',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
