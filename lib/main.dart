import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'routes/page_transitions.dart';
import 'screens/product_search_screen.dart';
import 'screens/category_products_screen.dart';
import 'widgets/skeleton_loader.dart';

// --- 1. CONFIGURATION ---
const supabaseUrl = 'https://uhamfsyerwrmejlszhqn.supabase.co';
const supabaseKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVoYW1mc3llcndybWVqbHN6aHFuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc4ODg1NjksImV4cCI6MjA4MzQ2NDU2OX0.T9g-6gnTR2Jai68O_un3SHF5sz9Goh4AnlQggLGfG-w';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
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
      title: 'LaxmiMart',
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
      home: const HomeScreen(),
    );
  }
}

// --- 3. STATE MANAGEMENT ---

class Category {
  final String id; // Use category name as ID since no separate categories table
  final String name;
  final String? imageUrl;

  Category({
    required this.id,
    required this.name,
    this.imageUrl,
  });
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
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class CartProvider extends ChangeNotifier {
  final Map<int, CartItem> _items = {};

  Map<int, CartItem> get items => _items;

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
  }

  void updateQuantity(int productId, int newQuantity) {
    if (_items.containsKey(productId)) {
      if (newQuantity > 0 && newQuantity <= _items[productId]!.product.stock) {
        _items[productId]!.quantity = newQuantity;
        notifyListeners();
      } else if (newQuantity <= 0) {
        removeFromCart(productId);
      }
    }
  }

  bool isInCart(int productId) {
    return _items.containsKey(productId);
  }

  int getQuantity(int productId) {
    return _items.containsKey(productId) ? _items[productId]!.quantity : 0;
  }

  void removeFromCart(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
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

  /// Load categories from distinct 'category' values in the products table
  Future<void> _loadCategories() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await _supabase
          .from('products')
          .select('category')
          .not('category', 'is', null)
          .gt('current_stock', 0);

      // Extract distinct, non-null category names
      final Set<String> seen = {};
      final List<Category> cats = [];
      for (final row in (response as List)) {
        final name = row['category'] as String?;
        if (name != null && name.isNotEmpty && seen.add(name)) {
          cats.add(Category(id: name, name: name));
        }
      }
      // Sort alphabetically
      cats.sort((a, b) => a.name.compareTo(b.name));

      setState(() {
        _categories = cats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
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
                expandedHeight: 130,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    padding: const EdgeInsets.fromLTRB(16, 48, 16, 10),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Location + Notification
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFF0C831F), size: 18),
                            const SizedBox(width: 4),
                            Text(
                              'LaxmiMart',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF0C831F),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, color: Color(0xFF3D3D3D), size: 18),
                            const Spacer(),
                            const Icon(Icons.notifications_outlined, color: Color(0xFF3D3D3D), size: 24),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Row 2: Search bar
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              SlidePageRoute(
                                page: const ProductSearchScreen(),
                                direction: PageTransitionDirection.up,
                              ),
                            );
                          },
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFFEEEEEE)),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x141C1C1C),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              children: [
                                const Icon(Icons.search, color: Color(0xFF0C831F), size: 22),
                                const SizedBox(width: 10),
                                Text(
                                  'Search products, brands...',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF737373),
                                    fontSize: 13,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(Icons.qr_code_scanner, color: Color(0xFF737373), size: 20),
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

// B. PRODUCT DETAILS SCREEN (Fixed Layout)
class ProductDetailScreen extends StatelessWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: SingleChildScrollView(
        // FIX: We use SingleChildScrollView to allow scrolling,
        // but we DO NOT use Expanded inside the Column below.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 300, // Fixed height for image area
              color: Colors.grey[200],
              child:
                  const Icon(Icons.shopping_bag, size: 100, color: Colors.grey),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '₹${product.price}',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00A82D)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text("Description",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                    product.description ?? "No details available.",
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        cart.addToCart(product);
                        Navigator.pop(context); // Go back after adding
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to Cart!')),
                        );
                      },
                      child: const Text('ADD TO CART',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
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
      appBar: AppBar(title: const Text('Your Cart')),
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

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final cart = Provider.of<CartProvider>(context, listen: false);
    final supabase = Supabase.instance.client;

    try {
      final customerResponse = await supabase
          .from('customers')
          .upsert({
            'phone': _phoneController.text,
            'full_name': _nameController.text,
            'address': _addressController.text,
          }, onConflict: 'phone')
          .select()
          .single();

      final customerId = customerResponse['id'];

      final orderResponse = await supabase
          .from('orders')
          .insert({
            'customer_id': customerId,
            'total_amount': cart.totalAmount,
            'status': 'New'
          })
          .select()
          .single();

      final orderId = orderResponse['id'];

      final List<Map<String, dynamic>> orderItems = [];
      cart.items.forEach((key, cartItem) {
        orderItems.add({
          'order_id': orderId,
          'product_id': cartItem.product.id,
          'product_name': cartItem.product.name,
          'quantity': cartItem.quantity,
          'unit_price': cartItem.product.price,
          'total_price': cartItem.product.price * cartItem.quantity,
        });
      });

      await supabase.from('order_items').insert(orderItems);

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
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
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
                    labelText: 'Phone Number', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (val) => val!.isEmpty ? 'Enter phone' : null,
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
