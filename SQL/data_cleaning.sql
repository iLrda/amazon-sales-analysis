-- =========================================================
-- AMAZON SALES DATA CLEANING
-- Purpose: Create a cleaned version of the raw dataset 
-- while preserving the original table.
-- =========================================================


-- ---------------------------------------------------------
-- 1. CREATE CLEAN WORKING TABLE
-- ---------------------------------------------------------

-- Preserve the raw amazon_sales table and perform all
-- cleaning operations on a separate copy.

DROP TABLE IF EXISTS amazon_sales_clean;

CREATE TABLE amazon_sales_clean AS
SELECT *
FROM amazon_sales;

-- Validate that all rows were copied successfully.

SELECT
    (SELECT COUNT(*) FROM amazon_sales) AS raw_rows,
    (SELECT COUNT(*) FROM amazon_sales_clean) AS clean_rows;


-- ---------------------------------------------------------
-- 2. CONVERT DATE TO PROPER DATA TYPE
-- ---------------------------------------------------------

-- The raw Date column is stored as VARCHAR using MM-DD-YY.
-- Profiling confirmed that all dates are valid.

-- Convert Date from text to PostgreSQL DATE.

ALTER TABLE amazon_sales_clean
ALTER COLUMN "Date" TYPE DATE
USING TO_DATE("Date", 'MM-DD-YY');

-- Validate the converted Date column.

SELECT
    MIN("Date") AS min_date,
    MAX("Date") AS max_date,
    COUNT(DISTINCT "Date") AS distinct_dates
FROM amazon_sales_clean;

-- Confirm the new data type.

SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'amazon_sales_clean'
  AND column_name = 'Date';


-- ---------------------------------------------------------
-- 3. CLEAN POSTAL CODES
-- ---------------------------------------------------------

-- Remove the '.0' suffix introduced during the
-- source/import process.

-- Postal codes remain text because they are identifiers.

UPDATE amazon_sales_clean
SET "ship-postal-code" = REGEXP_REPLACE(
    TRIM("ship-postal-code"),
    '\.0$',
    '')
WHERE TRIM("ship-postal-code") ~ '\.0$';

-- Validate postal codes after cleaning.

SELECT
    COUNT(*) FILTER (
        WHERE NULLIF(TRIM("ship-postal-code"), '') IS NULL
    ) AS blank_postal_codes,
    COUNT(*) FILTER (
        WHERE "ship-postal-code" ~ '\.0$'
    ) AS decimal_suffix_rows,
    COUNT(*) FILTER (
        WHERE NULLIF(TRIM("ship-postal-code"), '') IS NOT NULL
          AND "ship-postal-code" !~ '^[0-9]{6}$'
    ) AS invalid_postal_codes
FROM amazon_sales_clean;


-- ---------------------------------------------------------
-- 4. REMOVE REDUNDANT COLUMN
-- ---------------------------------------------------------

-- Unnamed: 22 contained only False or blank values and
-- provided no analytical value.

ALTER TABLE amazon_sales_clean
DROP COLUMN "Unnamed: 22";

-- Confirm that the column was removed.

SELECT COUNT(*) AS unnamed_22_columns
FROM information_schema.columns
WHERE table_name = 'amazon_sales_clean'
  AND column_name = 'Unnamed: 22';


-- ---------------------------------------------------------
-- 5. STANDARDIZE BLANK STRINGS
-- ---------------------------------------------------------

-- Convert blank strings to SQL NULL values and remove
-- unnecessary surrounding whitespace.

-- Missing values are standardized, not imputed.

UPDATE amazon_sales_clean
SET
    "currency" = NULLIF(TRIM("currency"), ''),
    "Courier Status" = NULLIF(TRIM("Courier Status"), ''),
    "fulfilled-by" = NULLIF(TRIM("fulfilled-by"), ''),
    "promotion-ids" = NULLIF(TRIM("promotion-ids"), ''),
    "ship-city" = NULLIF(TRIM("ship-city"), ''),
    "ship-state" = NULLIF(TRIM("ship-state"), ''),
    "ship-postal-code" = NULLIF(TRIM("ship-postal-code"), ''),
    "ship-country" = NULLIF(TRIM("ship-country"), '');

-- Check missing-value counts after standarization.

SELECT
    COUNT(*) FILTER (
        WHERE "currency" = '') AS currency_blanks,
    COUNT(*) FILTER (
        WHERE "Courier Status" = '') AS courier_status_blanks,
    COUNT(*) FILTER (
        WHERE "fulfilled-by" = '') AS fulfilled_by_blanks,
    COUNT(*) FILTER (
        WHERE "promotion-ids" = '') AS promotion_ids_blanks,
    COUNT(*) FILTER (
        WHERE "ship-city" = '') AS ship_city_blanks,
    COUNT(*) FILTER (
        WHERE "ship-state" = '') AS ship_state_blanks,
    COUNT(*) FILTER (
        WHERE "ship-postal-code" = '') AS postal_code_blanks,
    COUNT(*) FILTER (
        WHERE "ship-country" = '') AS ship_country_blanks
FROM amazon_sales_clean;

-- Verify NULL counts after standardizing missing values.

SELECT
    COUNT(*) FILTER (
        WHERE "currency" IS NULL) AS currency_nulls,
    COUNT(*) FILTER (
        WHERE "Courier Status" IS NULL) AS courier_status_nulls,
    COUNT(*) FILTER (
        WHERE "fulfilled-by" IS NULL) AS fulfilled_by_nulls,
    COUNT(*) FILTER (
        WHERE "promotion-ids" IS NULL ) AS promotion_ids_nulls,
    COUNT(*) FILTER (
        WHERE "ship-city" IS NULL) AS ship_city_nulls,
    COUNT(*) FILTER (
        WHERE "ship-state" IS NULL) AS ship_state_nulls,
    COUNT(*) FILTER (
        WHERE "ship-postal-code" IS NULL ) AS postal_code_nulls,
    COUNT(*) FILTER (
        WHERE "ship-country" IS NULL) AS ship_country_nulls
FROM amazon_sales_clean;


-- =========================================================
-- 6. FINAL VALIDATION
-- =========================================================

-- Confirm that cleaning preserved the dataset correctly.

-- Check that no rows were accidentally removed.

SELECT
    (SELECT COUNT(*) FROM amazon_sales) AS raw_rows,
    (SELECT COUNT(*) FROM amazon_sales_clean) AS clean_rows;

-- Confirm that no exact duplicate rows exist.

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT to_jsonb(t)) AS distinct_rows,
    COUNT(*) - COUNT(DISTINCT to_jsonb(t)) AS duplicate_rows
FROM amazon_sales_clean AS t;

-- Confirm that the date range remained unchanged.

SELECT
    MIN("Date") AS min_date,
    MAX("Date") AS max_date,
    COUNT(DISTINCT "Date") AS distinct_dates
FROM amazon_sales_clean;

-- Confirm that Date is stored as a proper DATE type.

SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'amazon_sales_clean'
  AND column_name = 'Date';

-- Final postal-code validation.

SELECT
    COUNT(*) FILTER (
        WHERE "ship-postal-code" IS NULL
    ) AS missing_postal_codes,
    COUNT(*) FILTER (
        WHERE "ship-postal-code" ~ '\.0$'
    ) AS decimal_suffix_rows,
    COUNT(*) FILTER (
        WHERE "ship-postal-code" IS NOT NULL
          AND "ship-postal-code" !~ '^[0-9]{6}$'
    ) AS invalid_postal_codes
FROM amazon_sales_clean;

-- Confirm that the redundant column is no longer present.

SELECT COUNT(*) AS unnamed_22_columns
FROM information_schema.columns
WHERE table_name = 'amazon_sales_clean'
  AND column_name = 'Unnamed: 22';