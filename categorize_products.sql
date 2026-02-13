-- ==================================================
-- AUTO-CATEGORIZATION SCRIPT FOR LAXMIMART
-- ==================================================
-- This script populates the 'category' column based on product names
-- Run this in Supabase SQL Editor

-- 1. DAIRY, BREAD & EGGS
UPDATE products 
SET category = 'Dairy, Bread & Eggs' 
WHERE category IS NULL 
AND (
  product_name ILIKE '%milk%' OR 
  product_name ILIKE '%dahi%' OR 
  product_name ILIKE '%curd%' OR 
  product_name ILIKE '%buttermilk%' OR 
  product_name ILIKE '%chhaas%' OR 
  product_name ILIKE '%amul%' OR
  product_name ILIKE '%cheese%' OR 
  product_name ILIKE '%butter%' OR 
  product_name ILIKE '%paneer%' OR 
  product_name ILIKE '%ghee%' OR
  product_name ILIKE '%bread%' OR 
  product_name ILIKE '%bun%' OR 
  product_name ILIKE '%rusk%' OR 
  product_name ILIKE '%cake%' OR 
  product_name ILIKE '%croissant%'
);

-- 2. SNACKS & MUNCHIES
UPDATE products 
SET category = 'Snacks & Munchies' 
WHERE category IS NULL 
AND (
  product_name ILIKE '%lays%' OR 
  product_name ILIKE '%pringles%' OR 
  product_name ILIKE '%bingo%' OR 
  product_name ILIKE '%nachos%' OR 
  product_name ILIKE '%wafers%' OR 
  product_name ILIKE '%chips%' OR
  product_name ILIKE '%parle%' OR 
  product_name ILIKE '%oreo%' OR 
  product_name ILIKE '%bourbon%' OR 
  product_name ILIKE '%good day%' OR 
  product_name ILIKE '%cookies%' OR 
  product_name ILIKE '%biscuit%' OR
  product_name ILIKE '%cadbury%' OR 
  product_name ILIKE '%kitkat%' OR 
  product_name ILIKE '%munch%' OR 
  product_name ILIKE '%silk%' OR 
  product_name ILIKE '%5 star%' OR 
  product_name ILIKE '%dairy milk%' OR 
  product_name ILIKE '%chocolate%' OR
  product_name ILIKE '%kurkure%' OR
  product_name ILIKE '%namkeen%'
);

-- 3. COLD DRINKS & JUICES
UPDATE products 
SET category = 'Cold Drinks & Juices' 
WHERE category IS NULL 
AND (
  product_name ILIKE '%pepsi%' OR 
  product_name ILIKE '%coke%' OR 
  product_name ILIKE '%coca cola%' OR 
  product_name ILIKE '%thums up%' OR 
  product_name ILIKE '%sprite%' OR 
  product_name ILIKE '%fanta%' OR 
  product_name ILIKE '%cola%' OR
  product_name ILIKE '%real%' OR 
  product_name ILIKE '%tropicana%' OR 
  product_name ILIKE '%maaza%' OR 
  product_name ILIKE '%fruity%' OR 
  product_name ILIKE '%slice%' OR 
  product_name ILIKE '%juice%' OR
  product_name ILIKE '%red bull%' OR 
  product_name ILIKE '%sting%' OR 
  product_name ILIKE '%horlicks%' OR 
  product_name ILIKE '%bournvita%' OR 
  product_name ILIKE '%boost%' OR
  product_name ILIKE '%drink%' OR
  product_name ILIKE '%water%' OR
  product_name ILIKE '%aqua%'
);

-- 4. PERSONAL CARE
UPDATE products 
SET category = 'Personal Care' 
WHERE category IS NULL 
AND (
  product_name ILIKE '%soap%' OR 
  product_name ILIKE '%dettol%' OR 
  product_name ILIKE '%lux%' OR 
  product_name ILIKE '%pears%' OR 
  product_name ILIKE '%body wash%' OR 
  product_name ILIKE '%santoor%' OR
  product_name ILIKE '%shampoo%' OR 
  product_name ILIKE '%conditioner%' OR 
  product_name ILIKE '%hair oil%' OR 
  product_name ILIKE '%head & shoulders%' OR
  product_name ILIKE '%face wash%' OR 
  product_name ILIKE '%cream%' OR 
  product_name ILIKE '%lotion%' OR 
  product_name ILIKE '%powder%' OR 
  product_name ILIKE '%fair%' OR 
  product_name ILIKE '%glow%' OR
  product_name ILIKE '%toothpaste%' OR
  product_name ILIKE '%toothbrush%' OR
  product_name ILIKE '%colgate%' OR
  product_name ILIKE '%pepsodent%' OR
  product_name ILIKE '%close up%' OR
  product_name ILIKE '%deodorant%' OR
  product_name ILIKE '%perfume%'
);

-- 5. HOUSEHOLD ESSENTIALS
UPDATE products 
SET category = 'Household Essentials' 
WHERE category IS NULL 
AND (
  product_name ILIKE '%detergent%' OR 
  product_name ILIKE '%surf%' OR 
  product_name ILIKE '%rin%' OR 
  product_name ILIKE '%vim%' OR 
  product_name ILIKE '%harpic%' OR 
  product_name ILIKE '%lizol%' OR
  product_name ILIKE '%cleaner%' OR
  product_name ILIKE '%phenyl%' OR
  product_name ILIKE '%floor%' OR
  product_name ILIKE '%toilet%'
);

-- 6. INSTANT FOOD & NOODLES
UPDATE products 
SET category = 'Instant Food' 
WHERE category IS NULL 
AND (
  product_name ILIKE '%maggi%' OR 
  product_name ILIKE '%noodles%' OR 
  product_name ILIKE '%pasta%' OR 
  product_name ILIKE '%yippee%' OR 
  product_name ILIKE '%top ramen%' OR
  product_name ILIKE '%instant%' OR
  product_name ILIKE '%ready to eat%'
);

-- 7. KITCHEN STAPLES
UPDATE products 
SET category = 'Kitchen Staples' 
WHERE category IS NULL 
AND (
  product_name ILIKE '%atta%' OR 
  product_name ILIKE '%flour%' OR 
  product_name ILIKE '%rice%' OR 
  product_name ILIKE '%dal%' OR 
  product_name ILIKE '%oil%' OR 
  product_name ILIKE '%masala%' OR
  product_name ILIKE '%spice%' OR
  product_name ILIKE '%salt%' OR
  product_name ILIKE '%sugar%' OR
  product_name ILIKE '%tea%' OR
  product_name ILIKE '%coffee%'
);

-- 8. CATCH-ALL: Mark remaining items as "Others"
UPDATE products 
SET category = 'Others' 
WHERE category IS NULL;

-- Verification: Count products per category
SELECT category, COUNT(*) as product_count 
FROM products 
GROUP BY category 
ORDER BY product_count DESC;
