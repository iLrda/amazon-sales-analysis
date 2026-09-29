# Amazon Sales Data Analysis

## Project Overview

This project analyzes Amazon sales data using SQL, Python, and Power BI to explore sales performance, order outcomes, product performance, and geographic trends.

The project follows an end-to-end data analysis workflow, including data profiling and cleaning in PostgreSQL, exploratory data analysis in Python, and the development of an interactive Power BI dashboard.

The final dashboard provides a clear view of key business metrics such as total orders, delivered revenue, average order value, cancellation rate, product performance, and sales distribution across categories and states.

## Business Questions

The analysis focuses on answering the following business questions:

- How many unique orders were placed, and what proportion were cancelled?
- How much revenue was generated from successfully delivered orders?
- What is the average order value for delivered orders?
- How are orders distributed across delivery statuses?
- How does delivered revenue change over time?
- Which product categories generate the most delivered revenue and sales volume?
- Which SKUs generate the highest delivered revenue?
- Which states contribute the most to delivered revenue?
- What patterns can be identified among failed, returned, and cancelled orders?

## Dataset

The dataset contains Amazon sales transactions with information about orders, products, fulfilment, shipping destinations, quantities, and order amounts.

Key fields used in the analysis include:

- `Order ID` - Unique identifier used to count distinct orders
- `Date` - Order date
- `Status` - Current order or delivery status
- `SKU` - Product stock keeping unit
- `Category` - Product category
- `Qty` - Quantity associated with each order line
- `Amount` - Monetary value associated with each order line
- `ship-city` and `ship-state` - Shipping destination
- `Fulfilment` - Order fulfilment method

### Data Source

The dataset used in this project is publicly available on Kaggle:

[Amazon Sales Dataset - Kaggle](https://www.kaggle.com/datasets/karkavelrajaj/amazon-sales-dataset)

The raw dataset is not included in this repository and is excluded from version control through `.gitignore`.

### Data Granularity

Each row represents an **order line rather than necessarily a unique order**. Therefore, order-level metrics are calculated using distinct `Order ID` values instead of row counts.

As part of the data validation process, each `Order ID` was also checked for multiple distinct statuses. No orders with conflicting statuses were found, allowing status-based order metrics to be calculated consistently.

The dataset covers the period from **March 31, 2022 to June 29, 2022**.

## Tools & Technologies

- **PostgreSQL** - Database used to store and query the sales data
- **DBeaver** - SQL client used for data profiling, cleaning, and analysis
- **Python** - Used for exploratory data analysis and validation
- **Pandas** - Data manipulation and analysis
- **Matplotlib** - Data visualization during exploratory analysis
- **SQLAlchemy** - Connection between Python and PostgreSQL
- **Visual Studio Code** - Code editor used for project development and file management
- **Jupyter Notebook** - Interactive environment used for exploratory analysis
- **Power BI** - Interactive dashboard development and business intelligence reporting
- **Git & GitHub** - Version control and project documentation

## Project Workflow

### 1. Data Profiling

The raw dataset was first explored in PostgreSQL to understand its structure and identify potential data quality issues.

The profiling process included:

- Reviewing the dataset structure and row count
- Checking for duplicate records
- Identifying missing values
- Examining order statuses and categorical fields
- Reviewing numeric fields such as quantity and amount
- Investigating the relationship between rows and unique orders

The profiling stage established the data quality issues that needed to be addressed before analysis.

### 2. Data Cleaning

A cleaned version of the dataset was created in PostgreSQL to preserve the raw data while preparing an analysis-ready table.

The cleaning process focused on:

- Handling identified data quality issues
- Standardizing relevant fields
- Preserving appropriate missing values where necessary
- Preparing data types and fields for downstream analysis
- Creating a clean dataset that could be used consistently across SQL, Python, and Power BI

The resulting `amazon_sales_clean` table became the primary source for the rest of the project.

### 3. SQL Analysis

SQL was used to investigate the cleaned dataset and calculate core business metrics.

The analysis included:

- Unique order counts
- Order status distribution
- Cancellation analysis
- Revenue and average order value
- Product category performance
- SKU performance
- Geographic sales patterns
- Quantity and order-level analysis

Distinct `Order ID` values were used for order-level calculations because the dataset contains multiple order-line records rather than one row per order.

### 4. Python Exploratory Data Analysis

The cleaned PostgreSQL data was loaded into Python using SQLAlchemy and Pandas for further exploratory analysis.

Python was used to:

- Reproduce and validate key metrics
- Group detailed shipping statuses into broader business categories
- Explore sales and order patterns
- Analyze failed, returned, and cancelled orders
- Create exploratory visualizations with Matplotlib
- Investigate patterns that were useful for the final dashboard

The Python analysis is documented in `Notebooks/exploratory_analysis.ipynb`.

### 5. Power BI Dashboard

The cleaned PostgreSQL data was imported into Power BI to build an interactive business dashboard.

The dashboard includes:

- Total Orders
- Delivered Revenue
- Delivered Average Order Value
- Cancellation Rate
- Orders by Status
- Delivered Revenue by Month
- Delivered Revenue and Units by Category
- Top 10 SKUs by Delivered Revenue
- Top 10 States by Delivered Revenue
- Date and Category filters

Revenue-focused visuals use delivered orders to distinguish completed sales from cancelled, pending, in-transit, or failed/returned orders.

### 6. Validation

Key Power BI measures were independently validated against SQL results to confirm that the dashboard calculations were consistent with the underlying data.

Validated metrics included:

- Total Orders: **120,378**
- Delivered Orders: **26,566**
- Cancelled Orders: **17,185**
- Cancellation Rate: **14.28%**
- Delivered Revenue: **₹18,650,815**
- Delivered Units: **28,886**
- Delivered Average Order Value: **₹702.06**

The SQL and Power BI results matched, providing a final consistency check before completing the dashboard.

## Key Insights

- The dataset contains **120,378 unique orders**, confirming that row counts should not be used directly as order counts because the data is recorded at the order-line level.

- **26,566 orders were successfully delivered**, generating approximately **₹18.65M in delivered revenue**.

- The average value of a delivered order was approximately **₹702.06**.

- **17,185 orders were cancelled**, resulting in an overall **cancellation rate of 14.28%**.

- Most orders were still classified as **In Transit** within the dataset, while delivered and cancelled orders represented the next largest status groups. This makes order status an important consideration when interpreting overall sales amounts.

- The **Set** category generated the highest delivered revenue, followed by **kurta** and **Western Dress**. These categories accounted for the majority of delivered revenue in the dataset.

- At the SKU level, **JNE3797-KR-L** generated the highest delivered revenue among the products analyzed.

- **Maharashtra** generated the highest delivered revenue among shipping states, followed by Karnataka and Uttar Pradesh.

- Monthly revenue comparisons should be interpreted carefully because the dataset covers **March 31 to June 29, 2022**. March and June therefore represent incomplete periods, while April and May provide more comparable full-month observations.

## Power BI Dashboard

The interactive Power BI dashboard summarizes the main findings of the analysis and allows users to filter the results by date and product category.

![Amazon Sales Dashboard](Images/Amazon%20Sales%20Dashboard.jpg)

The Power BI file is available in the `PowerBI/` directory.

## Repository Structure

```text
Sales Analysis/
│
├── Data/    # Raw data (not tracked by Git)
│
├── Images/
│   └── Amazon Sales Dashboard.jpg
│
├── Notebooks/
│   └── exploratory_analysis.ipynb
│
├── PowerBI/
│   └── Amazon Sales Dashboard.pbix
│
├── SQL/
│   ├── data_analysis.sql
│   ├── data_cleaning.sql
│   └── data_profiling.sql
│
├── src/
│   └── test_connection.py
│
├── .gitignore
├── README.md
└── requirements.txt
```

## How to Run the Project

1. Clone the repository.

2. Install the required Python packages:

```bash
pip install -r requirements.txt
```

3. Download the source dataset from [Kaggle](https://www.kaggle.com/datasets/karkavelrajaj/amazon-sales-dataset), set up a PostgreSQL database, and load the data into PostgreSQL.

4. Run the SQL scripts in the following order:

```text
SQL/data_profiling.sql
SQL/data_cleaning.sql
SQL/data_analysis.sql
```

5. Open `Notebooks/exploratory_analysis.ipynb` to review or run the Python exploratory analysis.

6. Open `PowerBI/amazon_sales_dashboard.pbix` in Power BI Desktop to explore the interactive dashboard.

> Database credentials are not included in the repository and must be configured locally.