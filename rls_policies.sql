-- ============================================================
-- RLS POLICIES — run in Supabase SQL Editor (Dashboard → SQL)
-- ============================================================
-- Products: public read, no writes from anonymous clients
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "products_public_read"
  ON products FOR SELECT USING (true);

-- Customers: anonymous can upsert (needed for checkout RPC)
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "customers_anon_upsert"
  ON customers FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "customers_anon_update"
  ON customers FOR UPDATE TO anon USING (true);

-- Orders: anonymous can insert only (via atomic RPC)
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "orders_anon_insert"
  ON orders FOR INSERT TO anon WITH CHECK (true);

-- Order Items: anonymous can insert only (via atomic RPC)
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "order_items_anon_insert"
  ON order_items FOR INSERT TO anon WITH CHECK (true);

-- NOTE: The create_order_atomic function uses SECURITY DEFINER,
-- so it already bypasses RLS internally. These policies handle
-- any future direct-table queries.
