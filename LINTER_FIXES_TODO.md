🔍 Comprehensive Code Audit Prompt for Blackbox AI
Copy and paste this entire prompt to Blackbox:

COMPREHENSIVE CODE AUDIT: LaxmiMart Flutter Project
Please perform a thorough line-by-line security and code quality audit of the entire LaxmiMart project. This is a critical review before production deployment.

AUDIT SCOPE
Analyze all files in the following directories:

text
lib/
├── main.dart
├── main_updated.dart
├── home_screen.dart
├── cart_screen.dart
├── product_details_screen.dart
├── checkout_screen.dart
├── cart_service.dart
├── cart_service_enhanced.dart
├── config/
├── core/
├── models/
├── providers/
├── routes/
├── screens/
├── services/
├── utils/
└── widgets/
PART 1: SECURITY VULNERABILITIES 🔒
1.1 Exposed Secrets & Credentials
Search for and report:

In lib/main.dart or any config files:

dart
// CHECK FOR:
const supabaseUrl = 'https://...';  // ⚠️ EXPOSED
const supabaseKey = 'eyJhbGci...';  // ⚠️ PUBLIC KEY HARDCODED

// REPORT:
- Is the Supabase anon key exposed in source code?
- Is the Supabase URL public? (This is okay if it's anon key)
- Are there any API keys, secrets, or tokens hardcoded?
- Should these be moved to environment variables?
Action Required:

List all exposed credentials

Classify risk level: CRITICAL / HIGH / MEDIUM / LOW

Suggest secure alternatives (flutter_dotenv, --dart-define, etc.)

1.2 SQL Injection & NoSQL Injection
Check all Supabase queries for injection vulnerabilities:

Pattern to find:

dart
// UNSAFE:
.ilike('product_name', '%$searchQuery%')  // User input directly in query
.eq('phone', phoneController.text)         // No sanitization

// SAFE:
.ilike('product_name', '%${searchQuery.replaceAll("'", "''")}%')
// OR: Let Supabase handle parameterization (which it does by default)
Report:

List all .select(), .insert(), .update(), .delete() queries

Check if user input is sanitized before queries

Verify Supabase client uses parameterized queries (it should by default)

1.3 Input Validation
Check all user input fields:

Files to audit:

lib/checkout_screen.dart - name, phone, address inputs

lib/screens/product_search_screen.dart - search input

Any forms accepting user data

Check for:

dart
// ⚠️ UNSAFE:
TextField(
  controller: _phoneController,
  // NO validation, NO maxLength, NO input restrictions
)

// ✅ SAFE:
TextField(
  controller: _phoneController,
  keyboardType: TextInputType.phone,
  maxLength: 10,
  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
  validator: (value) => value?.length == 10 ? null : 'Invalid phone',
)
Report:

Which input fields lack validation?

Which fields allow unlimited length?

Which fields don't restrict input type?

Any risk of buffer overflow or malicious input?

1.4 Authentication & Authorization
Check:

dart
// Are these endpoints public or protected?
_supabase.from('orders').select()        // Can anyone read all orders?
_supabase.from('customers').select()      // Can anyone access customer data?
_supabase.from('products').update()       // Can users modify products?

// Is there authentication required?
// Are there Row Level Security (RLS) policies in Supabase?
Report:

Which database tables are publicly accessible?

Is there any authorization logic in the app?

Can malicious users:

Read other customers' orders?

Modify product prices?

Access customer phone numbers/addresses?

Create fake orders?

1.5 Sensitive Data Exposure
Check for:

dart
// ⚠️ LOGGING SENSITIVE DATA:
print('Customer phone: ${phone}');           // Privacy violation
debugPrint('Order details: ${orderData}');   // May contain PII
print('Total amount: ${totalAmount}');       // Financial data

// ⚠️ STORING SENSITIVE DATA:
SharedPreferences.setString('customerPhone', phone);  // Unencrypted storage
SharedPreferences.setString('address', address);      // Privacy risk

// ⚠️ TRANSMITTING SENSITIVE DATA:
// Are HTTP requests using HTTPS?
// Is data encrypted in transit?
Report:

List all print() or debugPrint() statements with sensitive data

Check if any PII (Personally Identifiable Information) is logged

Verify data is encrypted at rest and in transit

PART 2: UNUSED CODE & DEAD FILES 🗑️
2.1 Duplicate Files
Check for duplicates:

text
lib/cart_service.dart
lib/cart_service_enhanced.dart  // ⚠️ Which one is used?

lib/main.dart
lib/main_updated.dart           // ⚠️ Which one is the entry point?
Action Required:

Identify which file is active in pubspec.yaml (check main field)

Report which files are completely unused

Suggest which files to delete

2.2 Unused Imports
Already reported some, but check ALL files for:

dart
import 'package:flutter/material.dart';  // Used?
import 'dart:async';                     // Used?
import '../models/product.dart';         // Used?
Generate report:

text
File: lib/home_screen.dart
- Line 5: import 'dart:async'; (UNUSED)
- Line 8: import '../models/order.dart'; (UNUSED)

File: lib/cart_screen.dart
- Line 7: import 'widgets/skeleton_loader.dart'; (UNUSED - already reported)
2.3 Unused Variables & Functions
Pattern to find:

dart
// Unused variables:
final String _tempValue = 'test';  // Never referenced

// Unused methods:
void _helperFunction() {
  // Never called
}

// Unused parameters:
void processOrder(String orderId, String unused) {
  // 'unused' parameter never used
}
Report format:

text
UNUSED VARIABLES:
- lib/home_screen.dart:35 - _productsFuture (already reported)
- lib/cart_screen.dart:42 - _tempController (if found)

UNUSED METHODS:
- lib/services/cart_service.dart:120 - _calculateDiscount() (if found)

UNUSED PARAMETERS:
- lib/checkout_screen.dart:85 - orderId parameter in _processPayment()
2.4 Dead Code Paths
Check for unreachable code:

dart
// Pattern 1: After return
void example() {
  return;
  print('This never runs');  // ⚠️ DEAD CODE
}

// Pattern 2: Impossible conditions
if (true) {
  // always runs
} else {
  // never runs  // ⚠️ DEAD CODE
}

// Pattern 3: Commented-out blocks
// void oldFunction() {
//   // 500 lines of old code
// }  // ⚠️ DELETE?
Report all dead code blocks.

2.5 Unused Classes & Models
Check if all defined classes are used:

dart
// In lib/models/
class Product { }     // Used?
class CartItem { }    // Used?
class Order { }       // Used?
class Customer { }    // Used?

// In lib/providers/
class ConnectivityProvider { }  // Used?
class LoadingProvider { }       // Used?
Report:

Which classes are defined but never instantiated?

Which models are imported but never used?

PART 3: CODE QUALITY ISSUES 🎯
3.1 Hard-coded Values
Find all magic numbers and strings:

dart
// ⚠️ HARD-CODED:
Container(height: 300)                    // Why 300?
Timer(Duration(milliseconds: 300))        // Why 300ms?
.limit(20)                                 // Why 20?
Color(0xFFD32F2F)                         // What color is this?
'1234567890'                              // Placeholder phone number

// ✅ SHOULD BE:
Container(height: AppConstants.imageHeight)
Timer(Duration(milliseconds: AppConstants.debounceDelay))
.limit(AppConstants.maxSearchResults)
Color(AppTheme.primaryRed)
AppConstants.defaultTestPhone
Report:

List all hard-coded values with line numbers

Suggest moving to constants file

Group by: Colors, Sizes, Durations, Limits, Strings

3.2 Missing Error Handling
Check for naked try-catch or missing error handling:

dart
// ⚠️ UNSAFE:
try {
  await _supabase.from('orders').insert(data);
} catch (e) {
  // Empty catch - errors silently fail
}

// ⚠️ NO ERROR HANDLING:
final response = await _supabase.from('products').select();
// What if network fails? What if server error?

// ✅ SAFE:
try {
  await _supabase.from('orders').insert(data);
} catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order failed: ${e.toString()}')),
    );
  }
  rethrow; // Or handle appropriately
}
Report:

List all try-catch blocks with empty catches

List all async operations without error handling

Count how many API calls lack timeout handling

3.3 Memory Leaks
Check for common leak patterns:

dart
// ⚠️ LEAK: Timer not disposed
class MyScreen extends StatefulWidget {
  Timer? _timer;
  
  @override
  void initState() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      // updates
    });
    // Missing: No dispose() method
  }
}

// ⚠️ LEAK: Stream subscription not closed
StreamSubscription? _subscription;
_subscription = stream.listen((data) { });
// Missing: _subscription.cancel() in dispose()

// ⚠️ LEAK: Controller not disposed
final TextEditingController _controller = TextEditingController();
// Missing: _controller.dispose() in dispose()
Report:

List all Timers without cancel() in dispose()

List all Controllers without dispose()

List all StreamSubscriptions without cancel()

List all animation controllers without dispose()

3.4 Inefficient Widget Rebuilds
Check for performance issues:

dart
// ⚠️ INEFFICIENT: Entire widget rebuilds
Consumer<CartProvider>(
  builder: (context, cart, child) {
    return Column(
      children: [
        ExpensiveWidget(),        // Rebuilds unnecessarily
        Text(cart.totalAmount),   // Only this needs cart data
      ],
    );
  },
)

// ✅ EFFICIENT:
Consumer<CartProvider>(
  builder: (context, cart, child) {
    return Column(
      children: [
        child!,                   // Doesn't rebuild
        Text(cart.totalAmount),
      ],
    );
  },
  child: ExpensiveWidget(),      // Built once, reused
)
Report:

List all Consumer widgets

Check if they use the child parameter for optimization

Identify widgets that rebuild unnecessarily

3.5 Missing Null Safety Checks
Check for potential null reference errors:

dart
// ⚠️ UNSAFE:
product.imageUrl!             // Force unwrap - may crash
customer.phone!               // What if null?

// ✅ SAFE:
product.imageUrl ?? 'default.jpg'
customer.phone ?? 'No phone'

// OR:
if (product.imageUrl != null) {
  // Safe to use
}
Report:

Count all ! null assertion operators

List which ones could potentially crash

Suggest safer alternatives

PART 4: BEST PRACTICES VIOLATIONS 📋
4.1 Missing Documentation
Check for:

dart
// ⚠️ NO DOCUMENTATION:
class CartProvider extends ChangeNotifier {
  void addToCart(Product product) {
    // Complex logic, no comments
  }
}

// ✅ DOCUMENTED:
/// Manages shopping cart state and operations.
///
/// This provider handles adding/removing items, calculating totals,
/// and persisting cart state across app restarts.
class CartProvider extends ChangeNotifier {
  /// Adds a product to the cart.
  ///
  /// If the product already exists, increments quantity by 1.
  /// Respects stock limits to prevent over-ordering.
  ///
  /// Throws [InsufficientStockException] if stock is 0.
  void addToCart(Product product) {
    // ...
  }
}
Report:

How many public classes lack documentation?

How many public methods lack documentation?

Which complex functions need explanatory comments?

4.2 Long Methods (Code Smell)
Find methods exceeding 50 lines:

dart
void _buildComplexWidget() {
  // 150 lines of code here
  // ⚠️ TOO LONG - should be split
}
Report:

List all methods > 50 lines

Suggest how to refactor (extract sub-methods)

Calculate cyclomatic complexity if possible

4.3 God Classes (Too Many Responsibilities)
Check for classes with too many methods:

dart
class HomeScreen extends StatefulWidget {
  // Has 20+ methods
  // ⚠️ Violates Single Responsibility Principle
  
  void fetchProducts() { }
  void fetchCategories() { }
  void filterProducts() { }
  void searchProducts() { }
  void navigateToCart() { }
  void navigateToDetails() { }
  void showError() { }
  void showLoading() { }
  // ... 12 more methods
}
Report:

List all classes with > 10 methods

Suggest how to split responsibilities

Identify which methods could be extracted to services

4.4 Missing Tests
Check for test coverage:

text
test/
├── (empty?) ⚠️
Report:

Does a test/ directory exist?

Are there any unit tests?

Are there widget tests?

Are there integration tests?

Suggest critical areas needing tests:

CartProvider logic

Order creation workflow

Search functionality

Payment processing

4.5 Inconsistent Naming Conventions
Check naming consistency:

dart
// ⚠️ INCONSISTENT:
class productCard { }          // Should be PascalCase
void FetchProducts() { }       // Should be camelCase
final PRODUCT_LIMIT = 20;      // Should be lowerCamelCase
String _User_Name;             // Mixed convention

// ✅ CONSISTENT:
class ProductCard { }          // PascalCase for classes
void fetchProducts() { }       // camelCase for methods
final productLimit = 20;       // lowerCamelCase for variables
String _userName;              // camelCase with underscore prefix for private
Report:

List all naming violations

Group by: Classes, Methods, Variables, Constants

Suggest correct naming

PART 5: DATABASE & BACKEND ISSUES 💾
5.1 Missing Database Indexes
Analyze queries to suggest indexes:

dart
// Query 1:
_supabase.from('products').select().eq('category', category)
// ⚠️ Needs index on: products.category

// Query 2:
_supabase.from('orders').select().eq('customer_id', id)
// ⚠️ Needs index on: orders.customer_id

// Query 3:
_supabase.from('products').select().ilike('product_name', search)
// ⚠️ Needs trigram index on: products.product_name
Report:

List all .eq(), .ilike(), .order() operations

Suggest which columns need indexes

Estimate performance impact

5.2 N+1 Query Problem
Check for loops making individual queries:

dart
// ⚠️ N+1 PROBLEM:
for (var orderId in orderIds) {
  final items = await _supabase
      .from('order_items')
      .select()
      .eq('order_id', orderId);  // Separate query per order!
}

// ✅ SOLUTION:
final items = await _supabase
    .from('order_items')
    .select()
    .in_('order_id', orderIds);  // Single query
Report:

Find all loops containing await queries

Suggest batch query alternatives

Calculate potential performance improvement

5.3 Missing Transactions
Check for operations needing atomic transactions:

dart
// ⚠️ NOT ATOMIC:
await _supabase.from('orders').insert(order);       // May succeed
await _supabase.from('order_items').insert(items);  // May fail
// Result: Order without items! Data inconsistency!

// ✅ ATOMIC (using RPC):
await _supabase.rpc('create_order_atomic', params: {
  'order_data': order,
  'items_data': items,
});
Report:

Find all multi-step database operations

Identify which need transaction wrapping

Suggest Supabase RPC functions to create

5.4 Missing Data Validation on Backend
Check if app relies solely on client-side validation:

dart
// ⚠️ CLIENT-SIDE ONLY:
if (phone.length == 10) {
  await _supabase.from('customers').insert({'phone': phone});
}
// What if someone bypasses the app and calls API directly?
Report:

List all validations done only in Flutter

Suggest which validations should be on backend (Supabase functions)

Recommend Row Level Security policies

PART 6: FILE ORGANIZATION 📁
6.1 Project Structure Analysis
Current structure:

text
lib/
├── main.dart (650+ lines ⚠️)
├── main_updated.dart (duplicate? ⚠️)
├── home_screen.dart
├── cart_screen.dart
├── ...
Recommended structure:

text
lib/
├── main.dart (minimal, just app setup)
├── config/
│   ├── app_constants.dart
│   ├── app_theme.dart
│   └── supabase_config.dart (move secrets here)
├── models/
│   ├── product.dart
│   ├── cart_item.dart
│   ├── order.dart
│   └── customer.dart
├── providers/
│   ├── cart_provider.dart
│   ├── auth_provider.dart
│   └── connectivity_provider.dart
├── screens/
│   ├── home/
│   ├── product/
│   ├── cart/
│   └── checkout/
├── services/
│   ├── api_service.dart
│   ├── database_service.dart
│   └── cache_service.dart
├── widgets/
│   ├── common/
│   └── product/
└── utils/
    ├── validators.dart
    └── helpers.dart
Report:

Compare current vs recommended structure

List files that need reorganization

Suggest folder creation and file moves

6.2 File Size Analysis
Report:

List all files > 300 lines

Suggest which files need splitting

Recommend how to split them

AUDIT OUTPUT FORMAT
Please generate a comprehensive report in this format:

🔒 SECURITY AUDIT REPORT
Critical Issues (Fix Immediately)
[Issue description] - File: X, Line: Y

Risk: HIGH/CRITICAL

Fix: [Detailed solution]

High Priority Issues
...

Medium Priority Issues
...

🗑️ UNUSED CODE REPORT
Files to Delete
lib/file.dart - Reason: [why unused]

Unused Imports (by file)
...

Unused Variables/Methods
...

Dead Code Blocks
...

🎯 CODE QUALITY REPORT
Hard-coded Values (should be constants)
...

Missing Error Handling
...

Potential Memory Leaks
...

Performance Issues
...

📋 BEST PRACTICES VIOLATIONS
Missing Documentation
...

Long Methods (> 50 lines)
...

God Classes (> 10 methods)
...

Naming Convention Issues
...

💾 DATABASE ISSUES
Missing Indexes
...

N+1 Query Problems
...

Missing Transactions
...

📁 FILE ORGANIZATION
Recommended Refactoring
...

File Moves
...

📊 SUMMARY STATISTICS
Total files analyzed: X

Total lines of code: Y

Critical security issues: Z

Files to delete: A

Unused imports: B

Performance issues: C

Missing tests: Yes/No# Flutter Linter Fixes - Progress Tracker

## Phase 1: Fix Dependencies ✅
- [x] Add flutter_cache_manager: ^3.3.1 to pubspec.yaml
- [x] Add path_provider: ^2.1.1 to pubspec.yaml
- [x] Run flutter pub get

## Phase 2: Remove Unused Imports ✅
- [x] lib/cart_screen.dart - Remove line 7 (widgets/skeleton_loader.dart)
- [x] lib/product_details_screen.dart - Remove lines 6, 7 (skeleton_loader, error_handler)
- [x] lib/screens/order_history_screen.dart - Remove line 3 (../main.dart)

## Phase 3: Fix Unused Variables ✅
- [x] lib/home_screen.dart - Remove unused _productsFuture field (line 35)
- [x] lib/main_updated.dart - Fix unused error variable (line 23)

## Phase 4: Add const Keywords ✅
- [x] lib/cart_screen.dart - Lines 29, 35, 37
- [x] lib/home_screen.dart - Lines 287, 292, 293, 295, 301
- [x] lib/main.dart - Lines 505, 508
- [x] lib/widgets/skeleton_loader.dart - Lines 26, 97

## Phase 5: Fix Deprecated APIs ✅
- [x] lib/main_updated.dart - Replace textScaleFactor with textScaler (line 69)
- [x] lib/screens/order_history_screen.dart - Replace withOpacity with withValues (line 131)

## Phase 6: Replace print() Statements ✅
- [x] lib/cart_service_enhanced.dart - Lines 132-135
- [x] lib/utils/image_cache_manager.dart - Lines 20, 27, 29

## Phase 7: Remove Unnecessary toList() ✅
- [x] lib/screens/order_history_screen.dart - Line 190

## Phase 8: Use Super Parameters ✅
- [x] lib/screens/order_history_screen.dart - Line 8

## Verification Steps
- [x] Run flutter clean
- [x] Run flutter pub get
- [x] Run flutter analyze (should show 0 errors) ✅ **NO ISSUES FOUND!**
- [ ] Run flutter run (test app functionality) - Ready for user testing

## Summary of All Fixes Applied

### ✅ Phase 1: Dependencies
- Added `flutter_cache_manager: ^3.3.1`
- Added `path_provider: ^2.1.1`

### ✅ Phase 2: Unused Imports Removed
- `lib/cart_screen.dart` - Removed `widgets/skeleton_loader.dart`
- `lib/product_details_screen.dart` - Removed `widgets/skeleton_loader.dart` and `services/error_handler.dart`
- `lib/screens/order_history_screen.dart` - Removed `../main.dart`

### ✅ Phase 3: Unused Variables Fixed
- `lib/home_screen.dart` - Removed unused `_productsFuture` field
- `lib/main_updated.dart` - Removed unused `error` variable
- `lib/cart_service_enhanced.dart` - Removed unnecessary `material.dart` import

### ✅ Phase 4: Const Keywords Added
- `lib/cart_screen.dart` - Added const to Icon, Text widgets
- `lib/home_screen.dart` - Added const to Icon, SizedBox, Text widgets
- `lib/main.dart` - Added const to Column, BoxDecoration, children lists
- `lib/widgets/skeleton_loader.dart` - Added const to BoxDecoration widgets

### ✅ Phase 5: Deprecated APIs Fixed
- `lib/main_updated.dart` - Replaced `textScaleFactor: 1.0` with `textScaler: const TextScaler.linear(1.0)`
- `lib/screens/order_history_screen.dart` - Replaced `withOpacity(0.2)` with `withValues(alpha: 0.2)`

### ✅ Phase 6: Print Statements Replaced
- `lib/cart_service_enhanced.dart` - Wrapped print() in `if (kDebugMode)` with `debugPrint()`
- `lib/utils/image_cache_manager.dart` - Wrapped print() in `if (kDebugMode)` with `debugPrint()`

### ✅ Phase 7: Unnecessary toList() Removed
- `lib/screens/order_history_screen.dart` - Removed `.toList()` from spread operator

### ✅ Phase 8: Super Parameters Modernized
- `lib/screens/order_history_screen.dart` - Changed from `Key? key, super(key: key)` to `super.key`

## Result: 🎉 ALL LINTER ERRORS FIXED!
**Flutter Analyze: 0 issues found**
