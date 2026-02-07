import 'package:flutter/material.dart';
import 'models.dart';

class CartService extends ChangeNotifier {
  // Map of Product ID (int) -> CartItem
  final Map<int, CartItem> _items = {};

  // Performance optimization: Cache computed values
  int? _cachedItemCount;
  double? _cachedTotalAmount;
  bool _isDirty = false;

  Map<int, CartItem> get items => Map.unmodifiable(_items);

  int get itemCount {
    if (_isDirty || _cachedItemCount == null) {
      _cachedItemCount = _items.length;
    }
    return _cachedItemCount!;
  }

  double get totalAmount {
    if (_isDirty || _cachedTotalAmount == null) {
      _cachedTotalAmount =
          _items.values.fold(0.0, (previous, item) => previous! + item.total);
    }
    return _cachedTotalAmount!;
  }

  void _markDirty() {
    _isDirty = true;
    // Clear cache on next access
    _cachedItemCount = null;
    _cachedTotalAmount = null;
  }

  void addToCart(Product product) {
    final wasEmpty = _items.isEmpty;

    if (_items.containsKey(product.id)) {
      _items.update(
        product.id,
        (existing) => CartItem(
          product: existing.product,
          quantity: existing.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        product.id,
        () => CartItem(product: product, quantity: 1),
      );
    }

    _markDirty();

    // Optimized notification strategy
    if (wasEmpty || _items.length % 3 == 0) {
      notifyListeners();
    }
  }

  void removeSingleItem(int productId) {
    if (!_items.containsKey(productId)) return;

    final wasEmpty = _items.isEmpty;

    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existing) => CartItem(
          product: existing.product,
          quantity: existing.quantity - 1,
        ),
      );
    } else {
      _items.remove(productId);
    }

    _markDirty();

    // Optimized notification strategy
    if (wasEmpty || _items.isEmpty || _items.length % 3 == 0) {
      notifyListeners();
    }
  }

  void clearCart() {
    if (_items.isNotEmpty) {
      _items.clear();
      _markDirty();
      notifyListeners();
    }
  }

  int getQuantity(int productId) {
    return _items.containsKey(productId) ? _items[productId]!.quantity : 0;
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      _items.remove(productId);
    } else {
      if (_items.containsKey(productId)) {
        _items.update(
          productId,
          (existing) => CartItem(
            product: existing.product,
            quantity: quantity,
          ),
        );
      } else {
        // This case shouldn't happen, but handle it gracefully
        _items.remove(productId);
      }
    }

    _markDirty();
    notifyListeners();
  }

  // Performance method to force notification
  void notifyIfChanged() {
    if (_isDirty) {
      notifyListeners();
      _isDirty = false;
    }
  }

  // Debug method to check performance
  void debugPrintPerformanceInfo() {
    print('Cart Items: ${_items.length}');
    print('Item Count: $itemCount');
    print('Total Amount: $totalAmount');
    print('Is Dirty: $_isDirty');
  }
}
