--EDA

-- Display the first few rows of the dataset
SELECT *
FROM Mall_Customers
LIMIT 5;

-- Check column names, data types, and any missing values
DESCRIBE Mall_Customers;

--Data Cleaning

-- Replace missing values with zero for better analysis
UPDATE Mall_Customers
SET Spending_Score = COALESCE(Spending_Score, 0)
WHERE Spending_Score IS NULL;

--customer segmentation

-- Rank customers by total spending
SELECT Customer_ID, Spending_Score,
       RANK() OVER (ORDER BY Spending_Score DESC) AS spending_rank
FROM Mall_Customers;

-- Divide customers into spending segments
SELECT Customer_ID, Spending_Score,
       CASE
           WHEN Spending_Score >= 80 THEN 'High Spenders'
           WHEN Spending_Score >= 60 THEN 'Medium Spenders'
           ELSE 'Low Spenders'
       END AS spending_segment
FROM Mall_Customers;

--cohort analysis

-- Calculate number of new customers each month
SELECT EXTRACT(YEAR_MONTH FROM Registration_Date) AS registration_month,
       COUNT(DISTINCT Customer_ID) AS new_customers
FROM Mall_Customers
GROUP BY registration_month;

-- Calculate retention rate over subsequent (3) months
SELECT EXTRACT(YEAR_MONTH FROM Registration_Date) AS registration_month,
       COUNT(DISTINCT Customer_ID) AS total_customers,
       COUNT(DISTINCT CASE WHEN EXTRACT(YEAR_MONTH FROM Current_Date) = EXTRACT(YEAR_MONTH FROM Registration_Date) + INTERVAL 3 MONTH THEN Customer_ID END) AS retained_customers,
       COUNT(DISTINCT CASE WHEN EXTRACT(YEAR_MONTH FROM Current_Date) = EXTRACT(YEAR_MONTH FROM Registration_Date) THEN Customer_ID END) AS initial_customers,
       (COUNT(DISTINCT CASE WHEN EXTRACT(YEAR_MONTH FROM Current_Date) = EXTRACT(YEAR_MONTH FROM Registration_Date) + INTERVAL 3 MONTH THEN Customer_ID END) / COUNT(DISTINCT CASE WHEN EXTRACT(YEAR_MONTH FROM Current_Date) = EXTRACT(YEAR_MONTH FROM Registration_Date) THEN Customer_ID END)) * 100 AS retention_rate
FROM Mall_Customers
GROUP BY registration_month;

--Trend Analysis

-- Calculate monthly total spending
SELECT EXTRACT(YEAR_MONTH FROM Order_Date) AS order_month,
       SUM(Total_Spending) AS monthly_total_spending
FROM Mall_Customers
GROUP BY order_month;

-- Determine month-over-month growth rates in spending
SELECT order_month,
       monthly_total_spending,
       LAG(monthly_total_spending) OVER (ORDER BY order_month) AS previous_month_total_spending,
       (monthly_total_spending - LAG(monthly_total_spending) OVER (ORDER BY order_month)) / LAG(monthly_total_spending) OVER (ORDER BY order_month) * 100 AS growth_rate
FROM (
    SELECT EXTRACT(YEAR_MONTH FROM Order_Date) AS order_month,
           SUM(Total_Spending) AS monthly_total_spending
    FROM Mall_Customers
    GROUP BY order_month
) AS monthly_spending;

--Further Analysis

-- Identify customers who have spent more than the average spending in their respective age groups
WITH avg_spending_per_age AS (
    SELECT Age, AVG(Spending_Score) AS avg_spending
    FROM Mall_Customers
    GROUP BY Age
)
SELECT c.Customer_ID, c.Age, c.Spending_Score
FROM Mall_Customers c
JOIN avg_spending_per_age a ON c.Age = a.Age
WHERE c.Spending_Score > a.avg_spending;

-- Find the top-spending customers in each age group
WITH ranked_customers AS (
    SELECT Customer_ID, Age, Spending_Score,
           ROW_NUMBER() OVER (PARTITION BY Age ORDER BY Spending_Score DESC) AS spending_rank
    FROM Mall_Customers
)
SELECT Customer_ID, Age, Spending_Score
FROM ranked_customers
WHERE spending_rank = 1;

-- Calculate average spending per gender
SELECT Gender, AVG(Spending_Score) AS avg_spending
FROM Mall_Customers
GROUP BY Gender;

-- Rank customers within each gender based on their spending
SELECT Gender, Customer_ID, Spending_Score,
       RANK() OVER (PARTITION BY Gender ORDER BY Spending_Score DESC) AS spending_rank
FROM Mall_Customers;
