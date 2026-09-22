-- =============================================
-- EXPLORATORY DATA ANALYSIS
-- =============================================


-- ---------------------------------------------------------
-- 1. BASIC DATASET OVERVIEW
-- ---------------------------------------------------------

-- Total number of orders

SELECT
    COUNT(DISTINCT "Order ID") AS total_orders
FROM "amazon_sales_clean";

-- Total quantity sold

SELECT
    SUM("Qty") AS total_quantity_sold
FROM amazon_sales_clean
WHERE "Qty" > 0;

-- Average number of items per order

SELECT
    AVG(order_quantity) AS average_items_per_order
FROM (
    SELECT
        "Order ID",
        SUM("Qty") AS order_quantity
    FROM amazon_sales_clean
    WHERE "Qty" > 0
    GROUP BY "Order ID"
) AS orders;


-- ---------------------------------------------------------
-- 2. QUANTITY CHECKS
-- ---------------------------------------------------------

-- Distribution of Qty values
SELECT
    "Qty",
    COUNT(*) AS row_count
FROM amazon_sales_clean
GROUP BY "Qty"
ORDER BY "Qty";

-- Status distribution where Qty = 0
SELECT
    "Status",
    COUNT(*) AS zero_qty_rows
FROM amazon_sales_clean
WHERE "Qty" = 0
GROUP BY "Status"
ORDER BY zero_qty_rows DESC;

-- Full status breakdown
SELECT
    "Status",
    COUNT(*) AS rows_count,
    COUNT(DISTINCT "Order ID") AS orders_count,
    SUM("Amount") AS total_amount
FROM amazon_sales_clean
GROUP BY "Status"
ORDER BY orders_count DESC;


-- ---------------------------------------------------------
-- 3. REVENUE-RELATED KPIs
-- ---------------------------------------------------------

-- Total revenue

SELECT
    SUM("Amount") AS total_revenue
FROM amazon_sales_clean;

-- Revenue excluding cancelled orders
SELECT
    SUM("Amount") AS revenue_excluding_cancelled
FROM amazon_sales_clean
WHERE "Status" <> 'Cancelled';

-- Revenue from delivered orders

SELECT
    SUM("Amount") AS delivered_amount
FROM amazon_sales_clean
WHERE "Status" = 'Shipped - Delivered to Buyer';

-- Revenue from shipped orders

SELECT
    SUM("Amount") AS shipped_amount
FROM amazon_sales_clean
WHERE "Status" = 'Shipped';

-- Revenue from cancelled orders

SELECT
    SUM("Amount") AS cancelled_amount
FROM amazon_sales_clean
WHERE "Status" = 'Cancelled';

-- Returned / returning amount

SELECT
    SUM("Amount") AS returned_amount
FROM amazon_sales_clean
WHERE "Status" IN (
    'Shipped - Returned to Seller',
    'Shipped - Returning to Seller'
);

-- Pending revenue

SELECT
    SUM("Amount") AS pending_amount
FROM amazon_sales_clean
WHERE "Status" IN (
    'Pending',
    'Pending - Waiting for Pick Up'
);


-- ---------------------------------------------------------
-- 4. AVERAGE ORDER VALUE
-- ---------------------------------------------------------

-- Average order value for non-cancelled orders

SELECT
    AVG(order_total) AS average_order_value
FROM (
    SELECT
        "Order ID",
        SUM("Amount") AS order_total
    FROM amazon_sales_clean
    WHERE "Status" <> 'Cancelled'
    GROUP BY "Order ID"
) AS orders;

-- ---------------------------------------------------------
-- 5. STATUS GROUPS
-- ---------------------------------------------------------

-- Group detailed statuses into broader business categories
SELECT
    CASE
        WHEN "Status" = 'Shipped - Delivered to Buyer'
            THEN 'Delivered'
        WHEN "Status" IN (
            'Shipped',
            'Shipped - Picked Up',
            'Shipped - Out for Delivery',
            'Shipping'
        )
            THEN 'In Transit'
        WHEN "Status" IN (
            'Shipped - Returned to Seller',
            'Shipped - Returning to Seller',
            'Shipped - Rejected by Buyer'
        )
            THEN 'Returned'
        WHEN "Status" = 'Cancelled'
            THEN 'Cancelled'
        WHEN "Status" IN (
            'Pending',
            'Pending - Waiting for Pick Up'
        )
            THEN 'Pending'
        WHEN "Status" IN (
            'Shipped - Lost in Transit',
            'Shipped - Damaged'
        )
            THEN 'Delivery Issue'
        ELSE 'Other'
    END AS status_group,
    COUNT(*) AS rows_count,
    COUNT(DISTINCT "Order ID") AS orders_count,
    SUM("Amount") AS total_amount
FROM amazon_sales_clean
GROUP BY status_group
ORDER BY orders_count DESC;


-- ---------------------------------------------------------
-- 6. ORDER STATUS RATES
-- ---------------------------------------------------------

SELECT
    ROUND(
        COUNT(DISTINCT CASE
            WHEN "Status" = 'Shipped - Delivered to Buyer'
            THEN "Order ID"
        END)::numeric
        / COUNT(DISTINCT "Order ID") * 100,
        2
    ) AS delivery_rate_percent,
    ROUND(
        COUNT(DISTINCT CASE
            WHEN "Status" = 'Cancelled'
            THEN "Order ID"
        END)::numeric
        / COUNT(DISTINCT "Order ID") * 100,
        2
    ) AS cancellation_rate_percent,
    ROUND(
        COUNT(DISTINCT CASE
            WHEN "Status" IN (
                'Shipped - Returned to Seller',
                'Shipped - Returning to Seller',
                'Shipped - Rejected by Buyer'
            )
            THEN "Order ID"
        END)::numeric
        / COUNT(DISTINCT "Order ID") * 100,
        2
    ) AS return_rate_percent,
    ROUND(
        COUNT(DISTINCT CASE
            WHEN "Status" IN (
                'Pending',
                'Pending - Waiting for Pick Up'
            )
            THEN "Order ID"
        END)::numeric
        / COUNT(DISTINCT "Order ID") * 100,
        2
    ) AS pending_rate_percent
FROM amazon_sales_clean;


-- ---------------------------------------------------------
-- 7. MONTHLY ANALYSIS
-- ---------------------------------------------------------

-- Orders and amount by month

SELECT
    DATE_TRUNC('month', "Date") AS month,
    COUNT(DISTINCT "Order ID") AS orders_count,
    SUM("Qty") AS total_quantity,
    SUM("Amount") AS total_amount
FROM amazon_sales_clean
GROUP BY month
ORDER BY month;

-- Delivered orders by month

SELECT
    DATE_TRUNC('month', "Date") AS month,
    COUNT(DISTINCT "Order ID") AS delivered_orders,
    SUM("Amount") AS delivered_amount
FROM amazon_sales_clean
WHERE "Status" = 'Shipped - Delivered to Buyer'
GROUP BY month
ORDER BY month;

-- Cancelled orders by month

SELECT
    DATE_TRUNC('month', "Date") AS month,
    COUNT(DISTINCT "Order ID") AS cancelled_orders
FROM amazon_sales_clean
WHERE "Status" = 'Cancelled'
GROUP BY month
ORDER BY month;

-- Monthly cancellation rate

SELECT
    DATE_TRUNC(
        'month',
        TO_DATE("Date", 'MM-DD-YY')
    ) AS month,
    COUNT(DISTINCT CASE
        WHEN "Status" = 'Cancelled'
        THEN "Order ID"
    END) AS cancelled_orders,
    COUNT(DISTINCT "Order ID") AS total_orders,
    ROUND(
        COUNT(DISTINCT CASE
            WHEN "Status" = 'Cancelled'
            THEN "Order ID"
        END)::numeric
        / COUNT(DISTINCT "Order ID") * 100,
        2
    ) AS cancellation_rate_percent
FROM amazon_sales_clean
GROUP BY month
ORDER BY month;


-- ---------------------------------------------------------
-- 8. PRODUCT / CATEGORY ANALYSIS
-- ---------------------------------------------------------

-- Orders and amount by category

SELECT
    "Category",
    COUNT(DISTINCT "Order ID") AS orders_count,
    SUM("Qty") AS total_quantity,
    SUM("Amount") AS total_amount
FROM amazon_sales_clean
WHERE "Qty" > 0
GROUP BY "Category"
ORDER BY total_amount DESC;

-- Top SKUs by quantity sold

SELECT
    "SKU",
    SUM("Qty") AS total_quantity
FROM amazon_sales_clean
WHERE "Qty" > 0
GROUP BY "SKU"
ORDER BY total_quantity DESC
LIMIT 10;

-- Top SKUs by amount

SELECT
    "SKU",
    COUNT(DISTINCT "Order ID") AS orders_count,
    SUM("Amount") AS total_amount
FROM amazon_sales_clean
WHERE "Amount" IS NOT NULL
GROUP BY "SKU"
ORDER BY total_amount DESC
LIMIT 10;

SELECT
    "SKU",
    COUNT(DISTINCT "Order ID") AS orders_count,
    SUM("Amount") AS delivered_amount
FROM amazon_sales_clean
WHERE "Status" = 'Shipped - Delivered to Buyer'
  AND "Amount" IS NOT NULL
GROUP BY "SKU"
ORDER BY delivered_amount DESC
LIMIT 10;

-- Top styles by amount

SELECT
    "Style",
    COUNT(DISTINCT "Order ID") AS orders_count,
    SUM("Qty") AS total_quantity,
    SUM("Amount") AS total_amount
FROM amazon_sales
WHERE "Amount" IS NOT NULL
  AND "Qty" > 0
GROUP BY "Style"
ORDER BY total_amount DESC
LIMIT 10;


-- ---------------------------------------------------------
-- 9. GEOGRAPHIC ANALYSIS
-- ---------------------------------------------------------

-- Top states by total amount

SELECT
    "ship-state",
    COUNT(DISTINCT "Order ID") AS orders_count,
    SUM("Qty") AS total_quantity,
    SUM("Amount") AS total_amount
FROM amazon_sales_clean
WHERE "Amount" IS NOT NULL
  AND "Qty" > 0
GROUP BY "ship-state"
ORDER BY total_amount DESC
LIMIT 10;

-- Top cities by total amount

SELECT
    "ship-city",
    COUNT(DISTINCT "Order ID") AS orders_count,
    SUM("Qty") AS total_quantity,
    SUM("Amount") AS total_amount
FROM amazon_sales_clean
WHERE "Amount" IS NOT NULL
  AND "Qty" > 0
GROUP BY "ship-city"
ORDER BY total_amount DESC
LIMIT 10;

-- Top states by number of orders

SELECT
    "ship-state",
    COUNT(DISTINCT "Order ID") AS orders_count
FROM amazon_sales_clean
GROUP BY "ship-state"
ORDER BY orders_count DESC
LIMIT 10;


-- ---------------------------------------------------------
-- 10. FULFILMENT ANALYSIS
-- ---------------------------------------------------------

SELECT
    "Fulfilment",
    COUNT(DISTINCT "Order ID") AS orders_count,
    SUM("Qty") AS total_quantity,
    SUM("Amount") AS total_amount
FROM amazon_sales_clean
WHERE "Amount" IS NOT NULL
  AND "Qty" > 0
GROUP BY "Fulfilment"
ORDER BY total_amount DESC;

-- Sales channel analysis

ALTER TABLE amazon_sales_clean
RENAME COLUMN "Sales Channel " TO "Sales Channel";

SELECT
    "Sales Channel",
    COUNT(DISTINCT "Order ID") AS orders_count,
    SUM("Qty") AS total_quantity,
    SUM("Amount") AS total_amount
FROM amazon_sales_clean
WHERE "Amount" IS NOT NULL
  AND "Qty" > 0
GROUP BY "Sales Channel"
ORDER BY total_amount DESC;


-- ---------------------------------------------------------
-- 11. B2B ANALYSIS
-- ---------------------------------------------------------

SELECT
    "B2B",
    COUNT(DISTINCT "Order ID") AS orders_count,
    SUM("Qty") AS total_quantity,
    SUM("Amount") AS total_amount
FROM amazon_sales
WHERE "Amount" IS NOT NULL
  AND "Qty" > 0
GROUP BY "B2B"
ORDER BY total_amount DESC;

SELECT
    "B2B",
    AVG(order_total) AS average_order_value
FROM (
    SELECT
        "Order ID",
        "B2B",
        SUM("Amount") AS order_total
    FROM amazon_sales
    WHERE "Amount" IS NOT NULL
    GROUP BY "Order ID", "B2B"
) AS orders
GROUP BY "B2B";


-- ---------------------------------------------------------
-- 12. EDA SUMMARY
-- ---------------------------------------------------------

-- Overall KPI summary
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT "Order ID") AS total_orders,
    SUM(CASE WHEN "Qty" > 0 THEN "Qty" ELSE 0 END) AS total_quantity,
    SUM("Amount") AS total_amount
FROM amazon_sales_clean;

-- Data quality summary
SELECT
    COUNT(*) FILTER (WHERE "Qty" = 0) AS zero_qty_rows,
    COUNT(*) FILTER (WHERE "Amount" IS NULL) AS null_amount_rows,
    COUNT(*) FILTER (WHERE "Status" = 'Cancelled') AS cancelled_rows
FROM amazon_sales_clean;

-- Status summary
SELECT
    "Status",
    COUNT(DISTINCT "Order ID") AS orders_count,
    SUM("Amount") AS total_amount
FROM amazon_sales_clean
GROUP BY "Status"
ORDER BY orders_count DESC;

-- Top categories
SELECT
    "Category",
    COUNT(DISTINCT "Order ID") AS orders_count,
    SUM("Qty") AS total_quantity,
    SUM("Amount") AS total_amount
FROM amazon_sales_clean
WHERE "Qty" > 0
  AND "Amount" IS NOT NULL
GROUP BY "Category"
ORDER BY total_amount DESC
LIMIT 10;

-- Top states
SELECT
    "ship-state",
    COUNT(DISTINCT "Order ID") AS orders_count,
    SUM("Amount") AS total_amount
FROM amazon_sales_clean
WHERE "ship-state" IS NOT NULL
  AND "Amount" IS NOT NULL
GROUP BY "ship-state"
ORDER BY total_amount DESC
LIMIT 10;