class AppConstants {
  static const String appName = 'LaxmiMart';
  static const String primaryColor = '#D32F2F';
  static const String secondaryColor = '#1A1A1A';

  // API Constants
  static const String productsTable = 'products';
  static const String customersTable = 'customers';
  static const String ordersTable = 'orders';
  static const String orderItemsTable = 'order_items';

  // Cache Settings
  static const int maxRetryAttempts = 3;
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration cacheMaxAge = Duration(hours: 24);

  // UI Constants
  static const double defaultBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double gridSpacing = 16.0;

  // Error Messages
  static const String networkError = 'Please check your internet connection';
  static const String serverError = 'Server error occurred. Please try again';
  static const String generalError = 'Something went wrong. Please try again';
  static const String noDataError = 'No data available';
}
