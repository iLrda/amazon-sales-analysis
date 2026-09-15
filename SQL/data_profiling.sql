-- =========================================================
-- AMAZON SALES DATA PROFILING
-- Purpose: Understand dataset structure and identify
-- potential data quality issues before cleaning.
-- =========================================================

-- Sample rows

SELECT *
FROM "amazon_sales"
LIMIT 10;


-- ---------------------------------------------------------
-- 1. DATASET GRANULARITY
-- ---------------------------------------------------------

-- Compare total rows with unique orders to determine
-- whether one order is represented by one or multiple
-- lines.

SELECT
    COUNT(DISTINCT "Order ID") AS unique_orders,
    COUNT(*) AS total_rows
FROM "amazon_sales";

-- Compare rows to detect duplicate records.

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT to_jsonb(t)) AS distinct_rows,
    COUNT(*) - COUNT(DISTINCT to_jsonb(t)) AS duplicate_rows
FROM "amazon_sales" AS t;

-- Identify orders that appear across multiple rows.
-- Repeated Order IDs may represent multiple products
-- within the same order.

SELECT
    "Order ID",
    COUNT(*) AS row_count
FROM "amazon_sales"
GROUP BY "Order ID"
HAVING COUNT(*) > 1
ORDER BY row_count DESC;

SELECT
    "Order ID",
    "SKU",
    "Category",
    "Size",
    "Qty",
    "Amount",
    "Status"
FROM "amazon_sales"
WHERE "Order ID" = '403-4984515-8861958';

-- Check whether the combination of Order ID and SKU
-- uniquely identifies an order line.

SELECT
    "Order ID",
    "SKU",
    COUNT(*) AS row_count
FROM "amazon_sales"
GROUP BY
    "Order ID",
    "SKU"
HAVING COUNT(*) > 1
ORDER BY row_count DESC;

SELECT *
FROM "amazon_sales"
WHERE "Order ID" = '171-9628368-5329958'
  AND "SKU" = 'J0329-KR-L';


-- ---------------------------------------------------------
-- 2. MISSING VALUES
-- ---------------------------------------------------------

-- Check NULL values in analytically important columns.

SELECT
    j.key AS column_name,
    COUNT(*) AS null_rows
FROM "amazon_sales" AS t
CROSS JOIN LATERAL jsonb_each_text(to_jsonb(t)) AS j(key, value)
WHERE j.value IS NULL
GROUP BY j.key
ORDER BY null_rows DESC;

-- Check blank strings that are not stored as SQL NULLs.

SELECT
    j.key AS column_name,
    COUNT(*) AS blank_rows
FROM "amazon_sales" AS t
CROSS JOIN LATERAL jsonb_each_text(to_jsonb(t)) AS j(key, value)
WHERE j.value IS NOT NULL
  AND TRIM(j.value) = ''
GROUP BY j.key
ORDER BY blank_rows DESC;


-- ---------------------------------------------------------
-- 3. INVESTIGATE MISSION/BLANK VALUES
-- ---------------------------------------------------------

-- Investigate whether blank values represent missing data
-- or valid business logic.

SELECT
    "fulfilled-by",
    COUNT(*) AS row_count
FROM "amazon_sales"
GROUP BY "fulfilled-by"
ORDER BY row_count DESC;

-- Check the relationship between fulfilment method
-- and the fulfilled-by field.

SELECT
    "Fulfilment",
    "fulfilled-by",
    COUNT(*) AS row_count
FROM "amazon_sales"
GROUP BY
    "Fulfilment",
    "fulfilled-by"
ORDER BY row_count DESC;

-- Check whether the Unnamed: 22 field contains useful
-- information or duplicates information from B2B.

SELECT
    "B2B",
    "Unnamed: 22",
    COUNT(*) AS row_count
FROM "amazon_sales"
GROUP BY
    "B2B",
    "Unnamed: 22"
ORDER BY row_count DESC;

-- Check whether blank currency values occur in the same
-- rows as NULL Amount values.

SELECT
    COUNT(*) FILTER (
        WHERE NULLIF(TRIM("currency"), '') IS NULL
          AND "Amount" IS NULL
        ) AS both_missing,
    COUNT(*) FILTER (
        WHERE NULLIF(TRIM("currency"), '') IS NULL
          AND "Amount" IS NOT NULL
          ) AS currency_missing,
    COUNT(*) FILTER (
        WHERE NULLIF(TRIM("currency"), '') IS NOT NULL
          AND "Amount" IS NULL
           ) AS amount_null
FROM "amazon_sales";

-- Investigate blank courier status values by order status.

SELECT
    "Status",
    COUNT(*) AS blank_courier_rows
FROM "amazon_sales"
WHERE NULLIF(TRIM("Courier Status"), '') IS NULL
GROUP BY "Status"
ORDER BY blank_courier_rows DESC;

SELECT
    "Status",
    COUNT(*) AS null_amount_rows
FROM "amazon_sales"
WHERE "Amount" IS NULL
GROUP BY "Status"
ORDER BY null_amount_rows DESC;


-- ---------------------------------------------------------
-- 4. NUMERIC CHECKS
-- ---------------------------------------------------------

-- Identify negative, zero, or unusually high values
-- in quantity and sales amount.

SELECT
    MIN("Qty") AS min_qty,
    MAX("Qty") AS max_qty,
    COUNT(*) FILTER (WHERE "Qty" = 0) AS zero_qty,
    COUNT(*) FILTER (WHERE "Qty" < 0) AS negative_qty,
    MIN("Amount") AS min_amount,
    MAX("Amount") AS max_amount,
    COUNT(*) FILTER (WHERE "Amount" = 0) AS zero_amount,
    COUNT(*) FILTER (WHERE "Amount" < 0) AS negative_amount
FROM "amazon_sales";

-- Investigate whether zero quantities and zero amounts
-- are associated with particular order statuses.

SELECT
    "Status",
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE "Qty" = 0) AS zero_qty_rows,
    COUNT(*) FILTER (WHERE "Amount" = 0) AS zero_amount_rows,
    COUNT(*) FILTER (WHERE "Amount" IS NULL) AS null_amount_rows
FROM "amazon_sales"
GROUP BY "Status"
ORDER BY zero_qty_rows DESC;

-- Check potentially inconsistent Qty / Amount combinations.

SELECT
    COUNT(*) FILTER (
        WHERE "Qty" = 0 AND "Amount" > 0
         ) AS zero_qty_positive_amount,
    COUNT(*) FILTER (
        WHERE "Qty" > 0 AND "Amount" = 0
       ) AS positive_qty_zero_amount
FROM "amazon_sales";

-- Identify which order statuses contain these unusual
-- Qty / Amount combinations.

SELECT
    "Status",
    COUNT(*) FILTER (
        WHERE "Qty" = 0 AND "Amount" > 0
        ) AS zero_qty_positive_amount,
    COUNT(*) FILTER (
        WHERE "Qty" > 0 AND "Amount" = 0
         ) AS positive_qty_zero_amount
	FROM "amazon_sales"
	GROUP BY "Status"
	ORDER BY zero_qty_positive_amount DESC,
             positive_qty_zero_amount DESC;

-- Check whether zero Amount values with positive quantity
-- may be associated with promotions.

SELECT
    CASE
        WHEN TRIM("promotion-ids") = '' THEN 'No promotion'
        ELSE 'Promotion'
    END AS promotion_status,
    COUNT(*) AS zero_amount_rows
FROM "amazon_sales"
WHERE "Qty" > 0
  AND "Amount" = 0
GROUP BY promotion_status
ORDER BY zero_amount_rows DESC;

-- ---------------------------------------------------------
-- 5. DATE VALIDATION
-- ---------------------------------------------------------

-- Verify that text dates follow the expected MM-DD-YY
-- format before converting them to DATE.

SELECT
    COUNT(*) FILTER (
        WHERE TRIM("Date") = ''
         ) AS blank_dates,
    COUNT(*) FILTER (
        WHERE "Date" !~ '^(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])-[0-9]{2}$'
          ) AS invalid_date_format
FROM "amazon_sales";

-- Determine the dataset's time range.

SELECT
    MIN(TO_DATE("Date", 'MM-DD-YY')) AS min_date,
    MAX(TO_DATE("Date", 'MM-DD-YY')) AS max_date,
    COUNT(DISTINCT "Date") AS distinct_dates
FROM "amazon_sales";

-- Detect calendar-invalid dates that may still match
-- the expected text pattern.

SELECT COUNT(*) AS invalid_calendar_dates
FROM "amazon_sales"
WHERE TO_CHAR(
          TO_DATE("Date", 'MM-DD-YY'),
          'MM-DD-YY') <> "Date";


-- ---------------------------------------------------------
-- 6. SHIPPING LOCATION VALIDATION
-- ---------------------------------------------------------

-- Examine missing shipping information and postal-code
-- formatting before geographic analysis.

-- Inspect country distribution and identify blank values.
SELECT
    "ship-country",
    COUNT(*) AS row_count
FROM "amazon_sales"
GROUP BY "ship-country"
ORDER BY row_count DESC;

-- Check whether entire shipping addresses are missing
-- rather than only the country field.

SELECT
    "Status",
    COUNT(*) AS rows_without_shipping_address
FROM "amazon_sales"
WHERE NULLIF(TRIM("ship-city"), '') IS NULL
  AND NULLIF(TRIM("ship-state"), '') IS NULL
  AND NULLIF(TRIM("ship-postal-code"), '') IS NULL
  AND NULLIF(TRIM("ship-country"), '') IS NULL
GROUP BY "Status"
ORDER BY rows_without_shipping_address DESC;

-- Validate available postal codes.
-- Postal codes are stored as text but contain a '.0'
-- suffix introduced during the source/import process.

WITH postal_check AS (
    SELECT
        TRIM("ship-postal-code") AS raw_postal,
        REGEXP_REPLACE(
            TRIM("ship-postal-code"),
            '\.0$',
            ''
            ) AS cleaned_postal
    FROM "amazon_sales"
    WHERE NULLIF(TRIM("ship-postal-code"), '') IS NOT NULL)
SELECT
    COUNT(*) AS postal_codes_present,
    COUNT(*) FILTER (
        WHERE raw_postal ~ '\.0$'
         ) AS decimal_suffix_rows,
    COUNT(*) FILTER (
        WHERE cleaned_postal !~ '^[0-9]+$'
         ) AS non_numeric_postal_codes,
    COUNT(*) FILTER (
        WHERE cleaned_postal ~ '^[0-9]+$'
          AND LENGTH(cleaned_postal) <> 6
         ) AS invalid_length_postal_codes
FROM postal_check;
