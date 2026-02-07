import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cart_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('user_name') ?? '';
      _phoneController.text = prefs.getString('user_phone') ?? '';
      _addressController.text = prefs.getString('user_address') ?? '';
    });
  }

  Future<void> _placeOrder(CartService cart) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;
    final prefs = await SharedPreferences.getInstance();

    try {
      debugPrint("Starting Order Process...");

      // 1. Save details locally
      await prefs.setString('user_name', _nameController.text);
      await prefs.setString('user_phone', _phoneController.text);
      await prefs.setString('user_address', _addressController.text);

      // 2. Upsert Customer
      final customerData = {
        'phone': _phoneController.text,
        'full_name': _nameController.text,
        'address': _addressController.text,
      };

      final customerResponse = await supabase
          .from('customers')
          .upsert(customerData, onConflict: 'phone')
          .select()
          .single();

      final int customerId = customerResponse['id'] as int;
      debugPrint("Customer ID: $customerId");

      // 3. Insert Order
      final orderData = {
        'customer_id': customerId,
        'total_amount': cart.totalAmount,
        'status': 'New',
        'created_at': DateTime.now().toIso8601String(),
      };

      final orderResponse = await supabase
          .from('orders')
          .insert(orderData)
          .select()
          .single();

      final int orderId = orderResponse['id'] as int;
      debugPrint("Order ID: $orderId");

      // 4. Insert Order Items
      final List<Map<String, dynamic>> orderItems = [];
      cart.items.forEach((key, item) {
        orderItems.add({
          'order_id': orderId,
          'product_id': item.product.id,
          'product_name': item.product.name,
          'quantity': item.quantity,
          'unit_price': item.product.price,
          'total_price': item.total,
        });
      });

      await supabase.from('order_items').insert(orderItems);
      debugPrint("Order Items Saved.");

      // 🔥 5. DEDUCT STOCK FROM INVENTORY
      for (final item in cart.items.values) {
        try {
          final productData = await supabase
              .from('products')
              .select('current_stock')
              .eq('id', item.product.id)
              .single();

          final currentStock = productData['current_stock'] as int;
          final newStock = currentStock - item.quantity;

          await supabase
              .from('products')
              .update({'current_stock': newStock})
              .eq('id', item.product.id);

          debugPrint("✅ Stock updated for ${item.product.name}: $newStock remaining");
        } catch (e) {
          debugPrint("❌ Stock update failed for ${item.product.name}: $e");
        }
      }

      // 6. Log Activity
      await supabase.from('activity_logs').insert([{
        'action_type': 'ONLINE_ORDER',
        'details': 'Order #$orderId placed for ₹${cart.totalAmount} by ${_nameController.text}'
      }]);

      if (mounted) {
        cart.clearCart();
        _showSuccessDialog();
      }
    } catch (e) {
      debugPrint("ORDER FAILED: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Order Placed!"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 10),
            Text("Your groceries are on the way!"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout Details", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Delivery Address", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildTextField("Full Name", _nameController, Icons.person),
              const SizedBox(height: 10),
              _buildTextField("Phone Number", _phoneController, Icons.phone, inputType: TextInputType.phone),
              const SizedBox(height: 10),
              _buildTextField("Address", _addressController, Icons.home, maxLines: 3),
              const SizedBox(height: 30),

              const Divider(),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Amount to Pay:", style: TextStyle(fontSize: 16)),
                  Text("₹${cart.totalAmount}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _placeOrder(cart),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("CONFIRM ORDER", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType inputType = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFD32F2F)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) => value!.isEmpty ? "Required" : null,
    );
  }
}