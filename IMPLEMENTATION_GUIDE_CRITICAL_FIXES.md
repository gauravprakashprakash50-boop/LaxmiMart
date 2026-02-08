# 🔧 IMPLEMENTATION GUIDE - Critical Security Fixes
## LaxmiMart Flutter Project

**Priority:** CRITICAL - Do These First  
**Estimated Time:** 4-6 hours  
**Difficulty:** Medium

---

## 🔐 FIX #1: Move Supabase Credentials to Environment Variables

**Time Required:** 30 minutes  
**Risk Level:** CRITICAL  
**Files to Modify:** `pubspec.yaml`, `lib/main.dart`, `lib/main_updated.dart`, `.gitignore`

### Step 1: Add flutter_dotenv Package

**File:** `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.8.0
  provider: ^6.0.0
  shared_preferences: ^2.2.0
  lottie: ^2.6.0
  google_fonts: ^5.1.0
  intl: ^0.18.0
  cupertino_icons: ^1.0.8
  shimmer: ^3.0.0
  cached_network_image: ^3.3.0
  connectivity_plus: ^5.0.2
  flutter_staggered_animations: ^1.1.1
  flutter_cache_manager: ^3.3.1
  path_provider: ^2.1.1
  flutter_dotenv: ^5.1.0  # ← ADD THIS LINE
```

**Action:** Run in terminal:
```bash
flutter pub add flutter_dotenv
```

---

### Step 2: Create .env File

**File:** `.env` (create new file in project root)

```env
# Supabase Configuration
SUPABASE_URL=https://uhamfsyerwrmejlszhqn.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVoYW1mc3llcndybWVqbHN6aHFuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc4ODg1NjksImV4cCI6MjA4MzQ2NDU2OX0.T9g-6gnTR2Jai68O_un3SHF5sz9Goh4AnlQggLGfG-w

# App Configuration
APP_NAME=LaxmiMart
APP_VERSION=1.0.0
```

**⚠️ IMPORTANT:** This file contains secrets - never commit to Git!

---

### Step 3: Update .gitignore

**File:** `.gitignore`

Add this line at the end:
```gitignore
# Environment variables
.env
.env.*
!.env.example
```

**Action:** Run in terminal to verify:
```bash
git status
# .env should NOT appear in the list
```

---

### Step 4: Create .env.example (Template for Team)

**File:** `.env.example` (create new file in project root)

```env
# Supabase Configuration
SUPABASE_URL=your_supabase_url_here
SUPABASE_ANON_KEY=your_supabase_anon_key_here

# App Configuration
APP_NAME=LaxmiMart
APP_VERSION=1.0.0
```

**Note:** This file CAN be committed to Git - it's a template

---

### Step 5: Update pubspec.yaml Assets

**File:** `pubspec.yaml`

```yaml
flutter:
  uses-material-design: true
  
  # Assets must be declared here
  assets:
    - assets/lottie/
    - .env  # ← ADD THIS LINE
```

---

### Step 6: Update lib/main_updated.dart

**File:** `lib/main_updated.dart`

**BEFORE (Lines 1-18):**
```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cart_service.dart';
import 'home_screen.dart';
import 'providers/loading_provider.dart';
import 'services/error_handler.dart';
import 'config/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://uhamfsyerwrmejlszhqn.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVoYW1mc3llcndybWVqbHN6aHFuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc4ODg1NjksImV4cCI6MjA4MzQ2NDU2OX0.T9g-6gnTR2Jai68O_un3SHF5sz9Goh4AnlQggLGfG-w',
  );
```

**AFTER:**
```dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';  // ← ADD THIS
import 'cart_service.dart';
import 'home_screen.dart';
import 'providers/loading_provider.dart';
import 'services/error_handler.dart';
import 'config/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");  // ← ADD THIS

  // Validate required environment variables
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseKey == null) {
    throw Exception('Missing Supabase credentials in .env file');
  }

  await Supabase.initialize(
    url: supabaseUrl,      // ← CHANGED
    anonKey: supabaseKey,  // ← CHANGED
  );
```

---

### Step 7: Test the Changes

**Action:** Run in terminal:
```bash
# Clean build
flutter clean
flutter pub get

# Run app
flutter run
```

**Expected Result:**
- App should launch successfully
- No errors about missing environment variables
- Supabase connection should work

**Troubleshooting:**
```dart
// Add debug print to verify (remove after testing)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  if (kDebugMode) {
    print('Supabase URL loaded: ${dotenv.env['SUPABASE_URL'] != null}');
    print('Supabase Key loaded: ${dotenv.env['SUPABASE_ANON_KEY'] != null}');
  }
  
  // ... rest of code
}
```

---

### Step 8: Rotate Supabase Key (IMPORTANT!)

Since the old key was exposed in code, you MUST rotate it:

1. Go to Supabase Dashboard: https://app.supabase.com
2. Select your project
3. Go to Settings → API
4. Click "Reset" next to "anon public" key
5. Copy the new key
6. Update `.env` file with new key
7. Test app again

---

## ✅ FIX #2: Add Input Validation to Checkout Screen

**Time Required:** 1 hour  
**Risk Level:** HIGH  
**Files to Create:** `lib/core/utils/validators.dart`  
**Files to Modify:** `lib/checkout_screen.dart`

### Step 1: Create Validators Utility

**File:** `lib/core/utils/validators.dart` (create new file)

```dart
/// Input validation utilities for form fields
class Validators {
  /// Validates Indian phone numbers
  /// 
  /// Rules:
  /// - Must be exactly 10 digits
  /// - Must start with 6, 7, 8, or 9
  /// - Only digits allowed
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove any whitespace
    final cleaned = value.replaceAll(RegExp(r'\s+'), '');
    
    // Check length
    if (cleaned.length != 10) {
      return 'Phone number must be exactly 10 digits';
    }
    
    // Check if only digits
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return 'Phone number can only contain digits';
    }
    
    // Check if starts with valid digit (6-9)
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) {
      return 'Invalid Indian phone number format';
    }
    
    return null; // Valid
  }
  
  /// Validates customer name
  /// 
  /// Rules:
  /// - Minimum 2 characters
  /// - Maximum 50 characters
  /// - Only letters and spaces allowed
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    // Trim whitespace
    final trimmed = value.trim();
    
    // Check minimum length
    if (trimmed.length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    // Check maximum length
    if (trimmed.length > 50) {
      return 'Name must not exceed 50 characters';
    }
    
    // Check if only letters and spaces
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(trimmed)) {
      return 'Name can only contain letters and spaces';
    }
    
    return null; // Valid
  }
  
  /// Validates delivery address
  /// 
  /// Rules:
  /// - Minimum 10 characters
  /// - Maximum 200 characters
  static String? address(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    
    // Trim whitespace
    final trimmed = value.trim();
    
    // Check minimum length
    if (trimmed.length < 10) {
      return 'Address must be at least 10 characters';
    }
    
    // Check maximum length
    if (trimmed.length > 200) {
      return 'Address must not exceed 200 characters';
    }
    
    return null; // Valid
  }
  
  /// Validates email address (optional - for future use)
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email is optional
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Invalid email address';
    }
    
    return null; // Valid
  }
}
```

---

### Step 2: Update Checkout Screen

**File:** `lib/checkout_screen.dart`

**Add import at top (Line 1):**
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  // ← ADD THIS
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cart_service.dart';
import 'core/utils/validators.dart';  // ← ADD THIS
```

---

**Replace _buildTextField method (Lines 195-207):**

**BEFORE:**
```dart
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
```

**AFTER:**
```dart
Widget _buildTextField(
  String label,
  TextEditingController controller,
  IconData icon, {
  TextInputType inputType = TextInputType.text,
  int maxLines = 1,
  int? maxLength,
  List<TextInputFormatter>? inputFormatters,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: inputType,
    maxLines: maxLines,
    maxLength: maxLength,
    inputFormatters: inputFormatters,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFFD32F2F)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[50],
      counterText: maxLength != null ? null : '', // Hide counter if no maxLength
    ),
    validator: validator ?? (value) => value!.isEmpty ? "Required" : null,
  );
}
```

---

**Update form fields in build method (Lines 165-175):**

**BEFORE:**
```dart
_buildTextField("Full Name", _nameController, Icons.person),
const SizedBox(height: 10),
_buildTextField("Phone Number", _phoneController, Icons.phone, inputType: TextInputType.phone),
const SizedBox(height: 10),
_buildTextField("Address", _addressController, Icons.home, maxLines: 3),
```

**AFTER:**
```dart
_buildTextField(
  "Full Name",
  _nameController,
  Icons.person,
  maxLength: 50,
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
  ],
  validator: Validators.name,
),
const SizedBox(height: 10),
_buildTextField(
  "Phone Number",
  _phoneController,
  Icons.phone,
  inputType: TextInputType.phone,
  maxLength: 10,
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(10),
  ],
  validator: Validators.phone,
),
const SizedBox(height: 10),
_buildTextField(
  "Address",
  _addressController,
  Icons.home,
  maxLines: 3,
  maxLength: 200,
  validator: Validators.address,
),
```

---

### Step 3: Test Validation

**Test Cases:**

1. **Phone Number:**
   - ❌ Empty → "Phone number is required"
   - ❌ "123" → "Phone number must be exactly 10 digits"
   - ❌ "1234567890" → "Invalid Indian phone number format" (starts with 1)
   - ❌ "98765abc12" → "Phone number can only contain digits"
   - ✅ "9876543210" → Valid

2. **Name:**
   - ❌ Empty → "Name is required"
   - ❌ "A" → "Name must be at least 2 characters"
   - ❌ "John123" → "Name can only contain letters and spaces"
   - ✅ "John Doe" → Valid

3. **Address:**
   - ❌ Empty → "Address is required"
   - ❌ "123 Main" → "Address must be at least 10 characters"
   - ✅ "123 Main Street, City, State - 123456" → Valid

---

## 🔒 FIX #3: Implement Row Level Security (RLS)

**Time Required:** 2 hours  
**Risk Level:** CRITICAL  
**Platform:** Supabase Dashboard

### Step 1: Enable RLS on All Tables

**Location:** Supabase Dashboard → Authentication → Policies

**SQL to Run:**
```sql
-- Enable Row Level Security on all tables
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;
```

**Action:**
1. Go to https://app.supabase.com
2. Select your project
3. Go to SQL Editor
4. Paste the SQL above
5. Click "Run"

---

### Step 2: Create RLS Policies for Products Table

**SQL:**
```sql
-- Products: Anyone can view, only service role can modify
CREATE POLICY "Anyone can view products"
ON products FOR SELECT
USING (true);

CREATE POLICY "Only service role can insert products"
ON products FOR INSERT
WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "Only service role can update products"
ON products FOR UPDATE
USING (auth.role() = 'service_role');

CREATE POLICY "Only service role can delete products"
ON products FOR DELETE
USING (auth.role() = 'service_role');
```

**Explanation:**
- All users can view products (needed for browsing)
- Only admin/service role can modify products
- Prevents customers from changing prices or stock

---

### Step 3: Create RLS Policies for Customers Table

**SQL:**
```sql
-- Customers: Users can only access their own data
CREATE POLICY "Users can view own customer data"
ON customers FOR SELECT
USING (
  phone = current_setting('request.jwt.claims', true)::json->>'phone'
  OR auth.role() = 'service_role'
);

CREATE POLICY "Users can insert own customer data"
ON customers FOR INSERT
WITH CHECK (
  phone = current_setting('request.jwt.claims', true)::json->>'phone'
  OR auth.role() = 'service_role'
);

CREATE POLICY "Users can update own customer data"
ON customers FOR UPDATE
USING (
  phone = current_setting('request.jwt.claims', true)::json->>'phone'
  OR auth.role() = 'service_role'
);
```

**Explanation:**
- Users can only see/modify their own customer record
- Identified by phone number in JWT claims
- Service role (admin) can access all records

---

### Step 4: Create RLS Policies for Orders Table

**SQL:**
```sql
-- Orders: Users can only access their own orders
CREATE POLICY "Users can view own orders"
ON orders FOR SELECT
USING (
  customer_id IN (
    SELECT id FROM customers 
    WHERE phone = current_setting('request.jwt.claims', true)::json->>'phone'
  )
  OR auth.role() = 'service_role'
);

CREATE POLICY "Users can create own orders"
ON orders FOR INSERT
WITH CHECK (
  customer_id IN (
    SELECT id FROM customers 
    WHERE phone = current_setting('request.jwt.claims', true)::json->>'phone'
  )
  OR auth.role() = 'service_role'
);

CREATE POLICY "Only service role can update orders"
ON orders FOR UPDATE
USING (auth.role() = 'service_role');
```

**Explanation:**
- Users can only view their own orders
- Users can create orders for themselves
- Only admins can update order status

---

### Step 5: Create RLS Policies for Order Items Table

**SQL:**
```sql
-- Order Items: Users can only access items from their orders
CREATE POLICY "Users can view own order items"
ON order_items FOR SELECT
USING (
  order_id IN (
    SELECT o.id FROM orders o
    JOIN customers c ON o.customer_id = c.id
    WHERE c.phone = current_setting('request.jwt.claims', true)::json->>'phone'
  )
  OR auth.role() = 'service_role'
);

CREATE POLICY "Users can insert own order items"
ON order_items FOR INSERT
WITH CHECK (
  order_id IN (
    SELECT o.id FROM orders o
    JOIN customers c ON o.customer_id = c.id
    WHERE c.phone = current_setting('request.jwt.claims', true)::json->>'phone'
  )
  OR auth.role() = 'service_role'
);
```

**Explanation:**
- Users can only see items from their own orders
- Prevents viewing other customers' purchases

---

### Step 6: Create RLS Policies for Activity Logs

**SQL:**
```sql
-- Activity Logs: Only service role can access
CREATE POLICY "Only service role can view activity logs"
ON activity_logs FOR SELECT
USING (auth.role() = 'service_role');

CREATE POLICY "Anyone can insert activity logs"
ON activity_logs FOR INSERT
WITH CHECK (true);
```

**Explanation:**
- Only admins can view logs
- Anyone can create logs (for audit trail)

---

### Step 7: Test RLS Policies

**Test in Supabase SQL Editor:**

```sql
-- Test 1: Try to view all customers (should fail for non-admin)
SELECT * FROM customers;

-- Test 2: Try to view all orders (should fail for non-admin)
SELECT * FROM orders;

-- Test 3: View products (should work for everyone)
SELECT * FROM products;
```

**Expected Results:**
- Without authentication: Only products visible
- With authentication: Only own data visible
- As service role: All data visible

---

## 🗑️ FIX #4: Delete Duplicate Files

**Time Required:** 15 minutes  
**Risk Level:** MEDIUM  
**Files to Delete:** 3 files

### Step 1: Verify Which Files Are Active

**Check pubspec.yaml:**
```yaml
# Look for the main entry point
# Usually not specified, defaults to lib/main.dart
```

**Check imports in other files:**
```bash
# Search for imports
grep -r "import.*main.dart" lib/
grep -r "import.*cart_service" lib/
grep -r "import.*home_screen" lib/
```

---

### Step 2: Decision Matrix

| File | Keep | Delete | Reason |
|------|------|--------|--------|
| `lib/main.dart` | ❌ | ✅ | Older version, 650+ lines, less organized |
| `lib/main_updated.dart` | ✅ | ❌ | Better error handling, cleaner structure |
| `lib/cart_service.dart` | ❌ | ✅ | Basic version |
| `lib/cart_service_enhanced.dart` | ✅ | ❌ | Has performance optimizations |
| `lib/home_screen.dart` | ✅ | ❌ | Currently used |
| `lib/home_screen_enhanced.dart` | ❌ | ✅ | Duplicate (if exists) |

---

### Step 3: Backup Before Deletion

```bash
# Create backup
mkdir -p backup_before_cleanup
cp lib/main.dart backup_before_cleanup/
cp lib/cart_service.dart backup_before_cleanup/
cp lib/home_screen_enhanced.dart backup_before_cleanup/ 2>/dev/null || true
```

---

### Step 4: Delete Duplicate Files

```bash
# Delete old main.dart
rm lib/main.dart

# Rename main_updated.dart to main.dart
mv lib/main_updated.dart lib/main.dart

# Delete old cart_service.dart
rm lib/cart_service.dart

# Delete home_screen_enhanced.dart (if exists)
rm lib/home_screen_enhanced.dart 2>/dev/null || true
```

---

### Step 5: Update Imports

**Files that may need updating:**

1. **lib/main.dart** (now renamed from main_updated.dart)
   - Change: `import 'cart_service.dart';`
   - To: `import 'cart_service_enhanced.dart';`

**Find and replace:**
```dart
// BEFORE
import 'cart_service.dart';

// AFTER
import 'cart_service_enhanced.dart';
```

2. **lib/checkout_screen.dart**
   - Change: `import 'cart_service.dart';`
   - To: `import 'cart_service_enhanced.dart';`

3. **lib/home_screen.dart**
   - Change: `import 'cart_service.dart';`
   - To: `import 'cart_service_enhanced.dart';`

---

### Step 6: Rename cart_service_enhanced.dart

```bash
# Rename for cleaner naming
mv lib/cart_service_enhanced.dart lib/cart_service.dart
```

**Now update imports back:**
```dart
// Change all files from:
import 'cart_service_enhanced.dart';

// Back to:
import 'cart_service.dart';
```

---

### Step 7: Test After Cleanup

```bash
# Clean and rebuild
flutter clean
flutter pub get

# Run app
flutter run
```

**Verify:**
- ✅ App launches successfully
- ✅ Cart functionality works
- ✅ Checkout works
- ✅ No import errors

---

## ✅ VERIFICATION CHECKLIST

After completing all fixes, verify:

### Fix #1: Environment Variables
- [ ] `.env` file created and populated
- [ ] `.env` added to `.gitignore`
- [ ] `flutter_dotenv` package installed
- [ ] `lib/main.dart` updated to use dotenv
- [ ] App runs successfully with new configuration
- [ ] Old Supabase key rotated in dashboard

### Fix #2: Input Validation
- [ ] `lib/core/utils/validators.dart` created
- [ ] `lib/checkout_screen.dart` updated
- [ ] Phone validation works (test with invalid numbers)
- [ ] Name validation works (test with numbers/special chars)
- [ ] Address validation works (test with short text)
- [ ] Form prevents submission with invalid data

### Fix #3: Row Level Security
- [ ] RLS enabled on all tables
- [ ] Policies created for products table
- [ ] Policies created for customers table
- [ ] Policies created for orders table
- [ ] Policies created for order_items table
- [ ] Policies created for activity_logs table
- [ ] Tested with SQL queries

### Fix #4: Delete Duplicates
- [ ] Backup created
- [ ] `lib/main.dart` deleted (old version)
- [ ] `lib/main_updated.dart` renamed to `lib/main.dart`
- [ ] `lib/cart_service.dart` deleted (old version)
- [ ] `lib/cart_service_enhanced.dart` renamed to `lib/cart_service.dart`
- [ ] All imports updated
- [ ] App runs successfully after cleanup

---

## 🚀 NEXT STEPS

After completing these critical fixes:

1. **Test Thoroughly:**
   - Create test orders
   - Verify validation works
   - Check database security

2. **Deploy to Staging:**
   - Test in staging environment
   - Verify environment variables work in production build

3. **Monitor:**
   - Check for any errors
   - Monitor Supabase logs
   - Verify RLS is working

4. **Proceed to Medium Priority Fixes:**
   - See `SECURITY_AUDIT_REPORT_PART2.md` for Phase 2 tasks

---

## 📞 TROUBLESHOOTING

### Issue: App crashes after adding dotenv

**Solution:**
```bash
# Make sure .env is in assets
flutter clean
flutter pub get
flutter run
```

### Issue: Validation not working

**Solution:**
```dart
// Check if validator is being called
validator: (value) {
  print('Validating: $value');  // Debug
  return Validators.phone(value);
}
```

### Issue: RLS blocking legitimate queries

**Solution:**
```sql
-- Temporarily disable RLS for testing
ALTER TABLE customers DISABLE ROW LEVEL SECURITY;

-- Re-enable after fixing policies
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
```

---

**End of Implementation Guide**

*Generated by BLACKBOXAI - January 2025*
