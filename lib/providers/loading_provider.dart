import 'package:flutter/foundation.dart';

enum LoadingType {
  products,
  categories,
  cart,
  checkout,
  productDetails,
}

class LoadingProvider extends ChangeNotifier {
  final Map<LoadingType, bool> _loadingStates = {};

  bool isLoading(LoadingType type) => _loadingStates[type] ?? false;

  void setLoading(LoadingType type, bool isLoading) {
    _loadingStates[type] = isLoading;
    notifyListeners();
  }

  void setMultipleLoading(Map<LoadingType, bool> states) {
    _loadingStates.addAll(states);
    notifyListeners();
  }

  bool get isAnyLoading => _loadingStates.values.any((loading) => loading);

  void clearAll() {
    _loadingStates.clear();
    notifyListeners();
  }
}
