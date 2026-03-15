-- ============================================================
--  create_order_atomic
--
--  PURPOSE:
--    Upsert a customer, create an order, insert all order items,
--    and decrement product stock — all in one implicit transaction.
--    Any failure (including insufficient stock) rolls everything back.
--
--  HOW TO RUN:
--    1. Open Supabase Dashboard → SQL Editor
--    2. Paste this entire file and click "Run"
--    3. You should see "Success. No rows returned."
--
--    NOTE: If the function already exists from a previous run,
--    CREATE OR REPLACE will update it in place — no need to drop first.
--
--  PARAMETERS:
--    p_customer_phone    TEXT     Indian mobile number (10 digits)
--    p_customer_name     TEXT     Customer full name
--    p_customer_address  TEXT     Delivery address
--    p_total_amount      NUMERIC  Cart total (pre-calculated on client)
--    p_order_items       JSONB    Array of item objects, each with:
--                                   product_id   INT
--                                   product_name TEXT
--                                   quantity     INT
--                                   unit_price   NUMERIC
--                                   total_price  NUMERIC
--
--  RETURNS:
--    JSONB  { "order_id": <int>, "customer_id": <int> }
--
--  ERRORS (whole order rolls back on any of these):
--    "Product <id> not found"
--    "Insufficient stock for <name>: only <n> left"
-- ============================================================

CREATE OR REPLACE FUNCTION create_order_atomic(
  p_customer_phone   TEXT,
  p_customer_name    TEXT,
  p_customer_address TEXT,
  p_total_amount     NUMERIC,
  p_order_items      JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER   -- runs with owner privileges so stock updates bypass RLS
AS $$
DECLARE
  v_customer_id   BIGINT;   -- adjust to UUID if your customers.id is UUID
  v_order_id      BIGINT;   -- adjust to UUID if your orders.id is UUID
  v_item          JSONB;
  v_product_id    INT;
  v_quantity      INT;
  v_current_stock INT;
  v_product_name  TEXT;
BEGIN

  -- ── STEP 1: Upsert customer ─────────────────────────────────────────────
  INSERT INTO customers (phone, full_name, address)
  VALUES (p_customer_phone, p_customer_name, p_customer_address)
  ON CONFLICT (phone)
  DO UPDATE SET
    full_name = EXCLUDED.full_name,
    address   = EXCLUDED.address
  RETURNING id INTO v_customer_id;

  -- ── STEP 2: Create order ────────────────────────────────────────────────
  INSERT INTO orders (customer_id, total_amount, status)
  VALUES (v_customer_id, p_total_amount, 'New')
  RETURNING id INTO v_order_id;

  -- ── STEP 3: For each item — validate stock, insert, decrement ───────────
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_order_items)
  LOOP
    v_product_id   := (v_item->>'product_id')::INT;
    v_quantity     := (v_item->>'quantity')::INT;
    v_product_name := v_item->>'product_name';

    -- Lock the product row for update to prevent race conditions
    -- (two customers buying the last item simultaneously)
    SELECT current_stock
      INTO v_current_stock
      FROM products
     WHERE id = v_product_id
       FOR UPDATE;

    -- Guard: product must exist
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Product % not found', v_product_id;
    END IF;

    -- Guard: sufficient stock must be available
    IF v_current_stock < v_quantity THEN
      RAISE EXCEPTION 'Insufficient stock for "%": only % left, % requested',
        v_product_name, v_current_stock, v_quantity;
    END IF;

    -- Insert the order item
    INSERT INTO order_items (
      order_id,
      product_id,
      product_name,
      quantity,
      unit_price,
      total_price
    )
    VALUES (
      v_order_id,
      v_product_id,
      v_product_name,
      v_quantity,
      (v_item->>'unit_price')::NUMERIC,
      (v_item->>'total_price')::NUMERIC
    );

    -- Decrement stock atomically (same transaction as the insert above)
    UPDATE products
       SET current_stock = current_stock - v_quantity
     WHERE id = v_product_id;

  END LOOP;

  -- ── RETURN result ────────────────────────────────────────────────────────
  RETURN jsonb_build_object(
    'order_id',    v_order_id,
    'customer_id', v_customer_id
  );

EXCEPTION
  WHEN OTHERS THEN
    -- Re-raise with original message; PostgreSQL rolls back the transaction
    RAISE;
END;
$$;


-- ============================================================
--  GRANT execute permission to the anon role so the Flutter
--  app (using the anon key) can call this function.
-- ============================================================
GRANT EXECUTE ON FUNCTION create_order_atomic(TEXT, TEXT, TEXT, NUMERIC, JSONB)
  TO anon;

