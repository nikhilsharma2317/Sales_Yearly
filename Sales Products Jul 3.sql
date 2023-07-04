CREATE TABLE sales_yearly_original AS
SELECT * FROM sales_products.sales_january_2019
UNION ALL
SELECT * FROM sales_products.sales_february_2019
UNION ALL
SELECT * FROM sales_products.sales_march_2019
UNION ALL
SELECT * FROM sales_products.sales_april_2019
UNION ALL
SELECT * FROM sales_products.sales_may_2019
UNION ALL
SELECT * FROM sales_products.sales_june_2019
UNION ALL
SELECT * FROM sales_products.sales_july_2019
UNION ALL
SELECT * FROM sales_products.sales_august_2019
UNION ALL
SELECT * FROM sales_products.sales_september_2019
UNION ALL
SELECT * FROM sales_products.sales_october_2019
UNION ALL
SELECT * FROM sales_products.sales_november_2019
UNION ALL
SELECT * FROM sales_products.sales_december_2019;

SELECT *
FROM sales_yearly_original;


# Examining the table structure and column names
DESCRIBE sales_yearly_original;

# Data Cleaning
-- Create a temporary table to hold distinct rows
CREATE TABLE sales_yearly AS
SELECT DISTINCT *
FROM sales_yearly_original;

-- Drop the original table
DROP TABLE sales_yearly_original;

-- Update Quantity Ordered with a default value of 0 for missing values
UPDATE sales_yearly
SET `Quantity Ordered` = 0
WHERE `Quantity Ordered` IS NULL;

-- Update Price Each with a default value of 0.0 for missing values
UPDATE sales_yearly
SET `Price Each` = 0.0
WHERE `Price Each` IS NULL;

# Convert strings to proper case (initial capital, remaining lowercase):
UPDATE sales_yearly
SET Product = CONCAT(UPPER(LEFT(Product, 1)), LOWER(SUBSTRING(Product, 2)))
WHERE Product IS NOT NULL;

# Remove leading and trailing spaces from string columns:
UPDATE sales_yearly
SET `Product` = TRIM(`Product`),
    `Purchase Address` = TRIM(`Purchase Address`)
WHERE `Product` IS NOT NULL OR `Purchase Address` IS NOT NULL;

# Change data types appropriately
-- Alter Quantity Ordered to integer
ALTER TABLE sales_yearly
MODIFY COLUMN `Quantity Ordered` INT;

# There's an issue with the data
# Find the problem row

SELECT *
FROM (
  SELECT *, ROW_NUMBER() OVER () AS row_num
  FROM sales_yearly
) AS subquery
WHERE row_num = 664;


# Check for Null Values

SELECT 
    SUM(CASE WHEN `Order ID` IS NULL OR `Order ID` = '' THEN 1 ELSE 0 END) AS `Order ID_Count`,
    SUM(CASE WHEN `Product` IS NULL OR `Product` = '' THEN 1 ELSE 0 END) AS `Product_Count`,
    SUM(CASE WHEN `Quantity Ordered` IS NULL OR `Quantity Ordered` = '' THEN 1 ELSE 0 END) AS `Quantity_Ordered_Count`,
    SUM(CASE WHEN `Price Each` IS NULL OR `Price Each` = '' THEN 1 ELSE 0 END) AS `Price_Each_Count`,
    SUM(CASE WHEN `Order Date` IS NULL OR `Order Date` = '' THEN 1 ELSE 0 END) AS `Order_Date_Count`,
    SUM(CASE WHEN `Purchase Address` IS NULL OR `Purchase Address` = '' THEN 1 ELSE 0 END) AS `Purchase_Address_Count`
FROM sales_yearly;

# Delete the empty row
DELETE FROM sales_yearly
WHERE `Price Each` IS NULL OR `Price Each` = '';

# Check for Null Values
SELECT 
    SUM(CASE WHEN `Order ID` IS NULL OR `Order ID` = '' THEN 1 ELSE 0 END) AS `Order ID_Count`,
    SUM(CASE WHEN `Product` IS NULL OR `Product` = '' THEN 1 ELSE 0 END) AS `Product_Count`,
    SUM(CASE WHEN `Quantity Ordered` IS NULL OR `Quantity Ordered` = '' THEN 1 ELSE 0 END) AS `Quantity_Ordered_Count`,
    SUM(CASE WHEN `Price Each` IS NULL OR `Price Each` = '' THEN 1 ELSE 0 END) AS `Price_Each_Count`,
    SUM(CASE WHEN `Order Date` IS NULL OR `Order Date` = '' THEN 1 ELSE 0 END) AS `Order_Date_Count`,
    SUM(CASE WHEN `Purchase Address` IS NULL OR `Purchase Address` = '' THEN 1 ELSE 0 END) AS `Purchase_Address_Count`
FROM sales_yearly;

-- Alter Quantity Ordered to integer
ALTER TABLE sales_yearly
MODIFY COLUMN `Quantity Ordered` INT;

# There's an issue with the data
# Find the problem row
# Check Row Number
SELECT *, ROW_NUMBER() OVER () AS RowNumber
FROM sales_yearly
LIMIT 1067, 1;

# Verify the problem
SELECT *
FROM sales_yearly
WHERE `Order ID` LIKE '%Order ID%';

# Delete the problem row
DELETE FROM sales_yearly
WHERE `Order ID` LIKE '%Order ID%';

# Verify
SELECT *, ROW_NUMBER() OVER () AS RowNumber
FROM sales_yearly
LIMIT 1067, 1;

SELECT *
FROM sales_yearly
WHERE `Order ID` LIKE '%Order ID%';

# Try original code again
ALTER TABLE sales_yearly
MODIFY COLUMN `Quantity Ordered` INT;

-- Alter Price Each to float
ALTER TABLE sales_yearly
CHANGE COLUMN `Price Each` `Price Each` FLOAT;
-- Alter Order Date to datetime
ALTER TABLE sales_yearly
MODIFY COLUMN `Order Date` DATETIME;

# There's an issue with the data
# Find the problem rows
SELECT *
FROM sales_yearly
WHERE `Order Date` IS NOT NULL
  AND STR_TO_DATE(`Order Date`, '%m/%d/%y %H:%i') IS NULL;

-- Step 1: Add a temporary column
ALTER TABLE sales_yearly
ADD COLUMN `Order Date_temp` DATETIME;

-- Step 2: Update the temporary column with the converted values
UPDATE sales_yearly
SET `Order Date_temp` = CASE
    WHEN `Order Date` LIKE '%/%/%' THEN STR_TO_DATE(`Order Date`, '%m/%d/%y %H:%i')
    WHEN `Order Date` LIKE '%-%-%' THEN STR_TO_DATE(`Order Date`, '%Y-%m-%d %H:%i:%s')
    ELSE NULL
  END;

SELECT *
FROM sales_yearly
WHERE `Order Date` LIKE '%/%/%' OR `Order Date` LIKE '%-%-%';

SELECT `Order Date`
FROM sales_yearly;


-- Step 3: Update the original column with the values from the temporary column
UPDATE sales_yearly
SET `Order Date` = `Order Date_temp`;

-- Step 4: Remove the temporary column
ALTER TABLE sales_yearly
DROP COLUMN `Order Date_temp`;


-- Alter Order Date to datetime
ALTER TABLE sales_yearly
MODIFY COLUMN `Order Date` DATETIME;


-- Add Order Time column
ALTER TABLE sales_yearly
ADD COLUMN `Order Time` TIME;

UPDATE sales_yearly
SET `Order Time` = TIME(`Order Date`);


-- Remove time from Order Date
ALTER TABLE sales_yearly
ADD COLUMN `Order Date_new` DATE;

UPDATE sales_yearly
SET `Order Date_new` = DATE(`Order Date`);

ALTER TABLE sales_yearly
DROP COLUMN `Order Date`;

ALTER TABLE sales_yearly
CHANGE COLUMN `Order Date_new` `Order Date` DATE;

-- Create Revenue Column
ALTER TABLE sales_yearly
ADD COLUMN `Revenue` DECIMAL(12, 2);

UPDATE sales_yearly
SET `Revenue` = `Quantity Ordered` * `Price Each`;

-- Update the existing Revenue column with the calculated revenue values
UPDATE sales_yearly
SET `Revenue` = ROUND(`Quantity Ordered` * `Price Each`, 2);

-- Warning Ignored after Inspection: raised 1024 warnings (1265 Data truncated). On inspection of the rows, it seemed fine so proceeding further ignoring the warning


-- Add Street, City, State & ZIP columns
ALTER TABLE sales_yearly
ADD COLUMN Street VARCHAR(255),
ADD COLUMN City VARCHAR(255),
ADD COLUMN State VARCHAR(255),
ADD COLUMN ZIP VARCHAR(255);

UPDATE sales_yearly
SET Street = SUBSTRING_INDEX(`Purchase Address`, ',', 1),
    City = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(`Purchase Address`, ',', -2), ',', 1)),
    State = LEFT(TRIM(SUBSTRING_INDEX(`Purchase Address`, ' ', -2)), 2),
    ZIP = SUBSTRING(`Purchase Address`, -5);
    
    
-- Add Order Month & Date columns
ALTER TABLE sales_yearly
ADD COLUMN `Order Month` INT,
ADD COLUMN `Order_Date` INT;

UPDATE sales_yearly
SET `Order Month` = SUBSTRING(`Order Date`, 6, 2);

UPDATE sales_yearly
SET `Order_Date` = SUBSTRING(`Order Date`, 9, 2);

SELECT *
FROM sales_yearly;

-- Create the view with the desired column order
CREATE VIEW sales_view AS
SELECT `Order ID`, `Product`, `Quantity Ordered`, `Price Each`, `Revenue`, `Order_Date`, `Order Month`, `Order Time`, `Street`, `City`, `State`, `ZIP`
FROM sales_yearly;

SELECT *
FROM sales_view;

SELECT COUNT(DISTINCT Product), COUNT(Product)
FROM sales_view;

# Data Analysis

-- Query 1: Overall statistics of the sales data
SELECT 
    COUNT(*) AS TotalRecords, -- Total number of records in the table
    SUM(Revenue) AS TotalRevenue, -- Total revenue
    AVG(`Quantity Ordered`) AS AverageQuantityOrdered, -- Average quantity ordered
    MAX(`Price Each`) AS MaxPriceEach, -- Maximum price per unit
    ROUND(MIN(`Price Each`),2) AS MinPriceEach -- Minimum price per unit
FROM sales_view;

-- Query 2: Top 10 products by total quantity ordered
SELECT 
    `Product`, 
    SUM(`Quantity Ordered`) AS TotalQuantityOrdered -- Total quantity ordered per product
FROM sales_view
GROUP BY `Product`
ORDER BY TotalQuantityOrdered DESC
LIMIT 10;

-- Query 3: Total revenue by city
SELECT 
    `City`, 
    SUM(Revenue) AS TotalRevenue -- Total revenue per city
FROM sales_view
GROUP BY `City`
ORDER BY TotalRevenue DESC;

-- Query 4: Total revenue by state
SELECT 
    `State`, 
    SUM(Revenue) AS TotalRevenue -- Total revenue per state
FROM sales_view
GROUP BY `State`
ORDER BY TotalRevenue DESC;

-- Query 5: Monthly revenue trends
SELECT 
    `Order Month`, -- Extract the month from the order date
    SUM(Revenue) AS TotalRevenue -- Total revenue per month
FROM sales_view
GROUP BY  `Order Month`
ORDER BY `Order Month`;

-- Query 6: Average price per unit by product category
SELECT
    `Product`,
    ROUND(AVG(`Price Each`),2) AS AveragePricePerUnit -- Average price per unit by product category
FROM sales_view
GROUP BY `Product`
ORDER BY AveragePricePerUnit DESC;

-- Query 7: Total revenue by Days
SELECT
    `Order_Date`, `Order Month`,-- Extract the year from the order date
    SUM(Revenue) AS TotalRevenue -- Total revenue per year
FROM sales_view
GROUP BY  `Order_Date`, `Order Month`
ORDER BY  `Order_Date`, `Order Month`;

-- Query 8: Revenue distribution by day of the week
SELECT
    DAYNAME(`Order Date`) AS DayOfWeek, -- Extract the day of the week from the order date
    SUM(Revenue) AS TotalRevenue -- Total revenue per day of the week
FROM sales_yearly
GROUP BY DayOfWeek
ORDER BY FIELD(DayOfWeek, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday');

-- Query 9: Top 10 Streets by total spending
SELECT
    `Street`, 
    City,
    SUM(Revenue) AS TotalSpending -- Total spending per customer
FROM sales_view
GROUP BY `Street`, City
ORDER BY TotalSpending DESC
LIMIT 10;

-- Query 10: Revenue distribution by hour of the day
SELECT
    HOUR(`Order Time`) AS HourOfDay, -- Extract the hour from the order time
    SUM(Revenue) AS TotalRevenue -- Total revenue per hour of the day
FROM sales_yearly
GROUP BY HourOfDay
ORDER BY HourOfDay;


-- Query 11: Revenue breakdown by product category and year
SELECT
    `Order Month`,
    `Product`,
    SUM(Revenue) AS TotalRevenue -- Total revenue per product category and year
FROM sales_view
GROUP BY  `Order Month`, `Product`
ORDER BY  `Order Month`, `Product`;

-- Query 12: Top 5 products by total revenue
SELECT
    `Product`,
    SUM(Revenue) AS TotalRevenue -- Total revenue per product
FROM sales_view
GROUP BY `Product`
ORDER BY TotalRevenue DESC
LIMIT 5;

-- Query 13: Average revenue per order by city
SELECT
    City,
    ROUND(AVG(Revenue),2) AS AverageRevenuePerOrder -- Average revenue per order by city
FROM sales_view
GROUP BY City
ORDER BY AverageRevenuePerOrder DESC;

-- Query 14: Average revenue per product category
SELECT
Product,
ROUND(AVG(Revenue),2) AS AverageRevenue
FROM sales_view
GROUP BY Product;

-- Query 15: Monthly revenue percentage contribution by category
SELECT
	`Order Month`,
    Product,
    (SUM(Revenue) / (SELECT SUM(Revenue) FROM sales_view) * 100) AS RevenuePercentage
FROM sales_view
GROUP BY  Product, `Order Month`
ORDER BY `Order Month`;


-- Query 16: Revenue distribution by state
SELECT
State,
SUM(Revenue) AS TotalRevenue
FROM sales_view
GROUP BY State
ORDER BY TotalRevenue DESC;

-- Query 17: Average revenue per day of the week
SELECT
DAYNAME(`Order Date`) AS DayOfWeek,
AVG(Revenue) AS AverageRevenue
FROM sales_yearly
GROUP BY DayOfWeek;

-- Query 18: Top 5 highest revenue orders
SELECT *
FROM sales_view
ORDER BY Revenue DESC
LIMIT 5;

-- Query 19: Count of orders by day of the week
SELECT DAYNAME(`Order Date`) AS DayOfWeek, COUNT(*) AS OrderCount
FROM sales_yearly
GROUP BY DayOfWeek;

-- Query 20: Total revenue by city and month
SELECT City, `Order Month`, SUM(Revenue) AS TotalRevenue
FROM sales_view
GROUP BY City, `Order Month`;

-- Query 21: Monthly revenue growth rate
SELECT
    `Order Month`,
    (SUM(Revenue) - LAG(SUM(Revenue)) OVER (ORDER BY `Order Month`)) / LAG(SUM(Revenue)) OVER (ORDER BY `Order Month`) * 100 AS GrowthRate
FROM sales_view
GROUP BY `Order Month`;

-- Query 22: Order frequency distribution
SELECT `Order ID`, COUNT(*) AS OrderCount
FROM sales_view
GROUP BY `Order ID`
ORDER BY OrderCount DESC;

-- Query 23: Distribution of order quantities
SELECT `Quantity Ordered`, COUNT(*) AS OrderCount
FROM sales_view
GROUP BY `Quantity Ordered`
ORDER BY `Quantity Ordered`;

-- Query 24: Distribution of order amounts
SELECT ROUND(Revenue, 2) AS OrderAmount, COUNT(*) AS OrderCount
FROM sales_view
GROUP BY ROUND(Revenue, 2)
ORDER BY OrderAmount;
SELECT *
FROM sales_view;

-- Query 25: Cumulative revenue distribution by product
SELECT Product, SUM(Revenue) AS CumulativeRevenue,
       ROUND((SUM(Revenue) / (SELECT SUM(Revenue) FROM sales_view) * 100),2) AS CumulativePercentage
FROM sales_view
GROUP BY Product
ORDER BY CumulativeRevenue DESC;

-- Query 26: Distribution of order counts by month
SELECT `Order Month`, COUNT(DISTINCT `Order ID`) AS OrderCount
FROM sales_view
GROUP BY `Order Month`
ORDER BY `Order Month`;

-- Query 27: Top-selling products by quantity in each month
SELECT `Order Month`, Product, SUM(`Quantity Ordered`) AS TotalQuantity
FROM sales_view
GROUP BY `Order Month`, Product
ORDER BY`Order Month`, TotalQuantity DESC;

-- Query 28: Distribution of order revenue by hour of the day
SELECT HOUR(`Order Time`) AS HourOfDay, SUM(Revenue) AS TotalRevenue
FROM sales_view
GROUP BY HourOfDay
ORDER BY HourOfDay;

-- Query 29: Distribution of order revenue by day of the week
SELECT DAYNAME(`Order Date`) AS DayOfWeek, SUM(Revenue) AS TotalRevenue
FROM sales_yearly
GROUP BY DayOfWeek
ORDER BY TotalRevenue DESC;

-- Query 30: Find the difference in revenue compared to the previous day for each product:
SELECT DISTINCT Product, `Order Month`, Order_Date, Revenue,
       Revenue - LAG(Revenue) OVER (PARTITION BY Product ORDER BY Order_Date) AS RevenueDifference
FROM sales_view
GROUP BY Product, `Order Month`, Order_Date,  Revenue
ORDER BY `Order Month`, Order_Date;

-- Query 31:Find the highest revenue month for each product category
SELECT Product, `Order Month`, SUM(Revenue) AS TotalRevenue
FROM sales_view
GROUP BY Product, `Order Month`
HAVING SUM(Revenue) = (
    SELECT MAX(SumRevenue)
    FROM (
        SELECT Product, `Order Month`, SUM(Revenue) AS SumRevenue
        FROM sales_view
        GROUP BY Product, `Order Month`
    ) AS temp
    WHERE temp.Product = sales_view.Product AND temp.`Order Month` = sales_view.`Order Month`
);



SELECT * FROM sales_view;
