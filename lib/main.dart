import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'routes/page_transitions.dart';
import 'widgets/enhanced_product_card.dart';
import 'screens/product_search_screen.dart';
import 'screens/category_split_view_screen.dart';
import 'utils/category_logic.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD32F2F)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFD32F2F),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD32F2F),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// --- 3. STATE MANAGEMENT ---

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

// A. HOME SCREEN
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LaxmiMart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Products',
            onPressed: () {
              Navigator.push(
                context,
                SlidePageRoute(
                  page: const ProductSearchScreen(),
                  direction: PageTransitionDirection.up,
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _supabase
            .from('products')
            .select()
            .order('product_name', ascending: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allProducts =
              snapshot.data!.map((e) => Product.fromMap(e)).toList();

          if (allProducts.isEmpty) {
            return const Center(child: Text('No products available.'));
          }

          // Group products by category using Helper
          final groupedProducts = CategoryHelper.groupProducts(allProducts);

          return ListView(
            padding: const EdgeInsets.only(bottom: 100), // Space for FAB
            children: [
              // 1. Promotional Banner
              _buildBannerCarousel(),

              // 2. Horizontal Category Scroll
              _buildCategoryScroll(groupedProducts.keys.toList()),

              // 3. Product Sections (Categorized)
              ...groupedProducts.entries.map((entry) {
                return _buildProductSection(entry.key, entry.value);
              }),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) return const SizedBox.shrink();

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  SlidePageRoute(
                    page: const CartScreen(),
                    direction: PageTransitionDirection.right,
                  ),
                );
              },
              backgroundColor: const Color(0xFFD32F2F),
              icon: Badge(
                label: Text(cart.items.length.toString()),
                child: const Icon(Icons.shopping_cart, color: Colors.white),
              ),
              label: Text(
                '₹${cart.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  /// Promotional banner carousel
  Widget _buildBannerCarousel() {
    return SizedBox(
      height: 180,
      child: PageView(
        children: [
          _buildBannerItem(
            'Fresh Vegetables',
            'Up to 30% OFF',
            const Color(0xFF4CAF50),
            Icons.eco,
          ),
          _buildBannerItem(
            'Dairy Specials',
            'Buy 1 Get 1 Free',
            const Color(0xFF2196F3),
            Icons.water_drop,
          ),
          _buildBannerItem(
            'Snack Time',
            'Flat ₹50 OFF',
            const Color(0xFFFF9800),
            Icons.cookie,
          ),
        ],
      ),
    );
  }

  Widget _buildBannerItem(
      String title, String subtitle, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Shop Now',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, size: 80, color: Colors.white.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  /// Horizontal category navigation
  Widget _buildCategoryScroll(List<String> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text(
            'Shop by Category',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    SlidePageRoute(
                      page: const CategorySplitViewScreen(),
                      direction: PageTransitionDirection.right,
                    ),
                  );
                },
                child: Container(
                  width: 85,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: CategoryHelper.getIconUrl(category),
                          width: 40,
                          height: 40,
                          placeholder: (context, url) =>
                              const Icon(Icons.category, color: Colors.grey),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.category, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Categorized horizontal product section
  Widget _buildProductSection(String title, List<Product> products) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 8, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward, size: 20),
                onPressed: () {
                  Navigator.push(
                    context,
                    SlidePageRoute(
                      page: const CategorySplitViewScreen(),
                      direction: PageTransitionDirection.right,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return SizedBox(
                width: 140,
                child: EnhancedProductCard(
                  product: products[index],
                  onTap: () {
                    Navigator.push(
                      context,
                      SlidePageRoute(
                        page: ProductDetailScreen(product: products[index]),
                        direction: PageTransitionDirection.right,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
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
                            color: Color(0xFFD32F2F)),
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
                            color: Color(0xFFD32F2F))),
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
