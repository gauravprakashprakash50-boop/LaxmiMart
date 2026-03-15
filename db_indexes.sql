-- ============================================================
-- DATABASE INDEXES — run in Supabase SQL Editor (Dashboard → SQL)
-- ============================================================

-- Products: category browsing (used by CategoryProductsScreen)
CREATE INDEX IF NOT EXISTS idx_products_category_id
  ON products(category_id);

-- Products: barcode scanning (used by ProductSearchScreen)
CREATE INDEX IF NOT EXISTS idx_products_barcode
  ON products(barcode);

-- Products: full-text search on product name
CREATE INDEX IF NOT EXISTS idx_products_name_fts
  ON products USING gin(to_tsvector('english', product_name));

-- Orders: order history lookup by customer
CREATE INDEX IF NOT EXISTS idx_orders_customer_id
  ON orders(customer_id);

-- Customers: phone lookup (used by OrderHistoryScreen + checkout)
CREATE INDEX IF NOT EXISTS idx_customers_phone
  ON customers(phone);
