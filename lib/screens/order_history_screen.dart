import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  List<Map<String, dynamic>> _orders = [];
  bool _hasSearched = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _hasSearched = false;
    });

    try {
      // 1. Lookup customer by phone
      final customerResp = await _supabase
          .from('customers')
          .select('id')
          .eq('phone', _phoneController.text.trim())
          .maybeSingle();

      if (customerResp == null) {
        setState(() {
          _orders = [];
          _hasSearched = true;
          _isLoading = false;
        });
        return;
      }

      final customerId = customerResp['id'];

      // 2. Fetch orders with nested order_items
      final ordersResp = await _supabase
          .from('orders')
          .select('*, order_items(*)')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      setState(() {
        _orders = List<Map<String, dynamic>>.from(ordersResp as List);
        _hasSearched = true;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching orders: $e')),
        );
      }
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          'Order History',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF3D3D3D),
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: Column(
        children: [
          // ── Phone Input ──────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Form(
              key: _formKey,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: 'Enter 10-digit mobile number',
                        prefixText: '+91 ',
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      ),
                      style: GoogleFonts.poppins(fontSize: 14),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        if (val.length != 10) return 'Must be 10 digits';
                        if (!RegExp(r'^[6-9]\d{9}$').hasMatch(val)) {
                          return 'Invalid Indian mobile';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _fetchOrders,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C831F),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.search, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Results ──────────────────────────────────────────────
          Expanded(
            child: !_hasSearched
                ? _buildPromptState()
                : _orders.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        itemBuilder: (_, i) => _buildOrderCard(_orders[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Enter your phone number\nto view your orders',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: const Color(0xFF9E9E9E),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No orders found for\n+91 ${_phoneController.text}',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: const Color(0xFF9E9E9E),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['id'];
    final rawDate = order['created_at'] as String?;
    final total = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
    final items = List<Map<String, dynamic>>.from(
        (order['order_items'] as List?) ?? []);

    final date = rawDate != null
        ? DateTime.tryParse(rawDate)?.toLocal()
        : null;
    final dateStr = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : 'Unknown date';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 12),
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.receipt_outlined,
                color: Color(0xFF0C831F), size: 20),
          ),
          title: Text(
            'Order #$orderId',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            '$dateStr  ·  ${items.length} item${items.length == 1 ? '' : 's'}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF9E9E9E),
            ),
          ),
          trailing: Text(
            '₹${total.toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: const Color(0xFF0C831F),
            ),
          ),
          children: items.map((item) {
            final name = item['product_name'] as String? ?? 'Item';
            final qty = item['quantity'] as int? ?? 1;
            final price = (item['unit_price'] as num?)?.toDouble() ?? 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: const Color(0xFF3D3D3D)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '×$qty  ₹${(price * qty).toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF616161),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
