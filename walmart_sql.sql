USE walmart_db;

SELECT * FROM walmart;

-- Distinct payment method 
SELECT DISTINCT payment_method FROM walmart;

-- Total number of payment method.
SELECT 
    payment_method, COUNT(payment_method) AS count
FROM
    walmart
GROUP BY payment_method
;

-- Distinct branch.
SELECT COUNT(DISTINCT branch) FROM walmart;

-- Maximum and minimum quantity ordered.
SELECT MAX(quantity) FROM walmart;
SELECT MIN(quantity) FROM walmart;


-- BUSINESS PROBLEMS

-- Q.1. Which payment method is used most frequently by customers?

SELECT 
    payment_method,
    COUNT(*) AS no_payments,
    SUM(quantity) AS no_qty_sold
FROM
    walmart
GROUP BY payment_method;

-- Q.2.For each branch, which product category has the highest average customer rating?

SELECT branch, category, avg_rating
FROM
(
SELECT 
    branch, category, AVG(rating) AS avg_rating,
    RANK() OVER (PARTITION BY branch ORDER BY AVG(rating) DESC) AS ranks
FROM
    walmart
GROUP BY 1,2)ranked
WHERE ranks = 1;

-- Q.3. Identify the busiest day for each branch based on the number of transactions.

SET SQL_SAFE_UPDATES = 0;

SELECT date,
       STR_TO_DATE(date, '%d/%m/%y')
FROM walmart;

UPDATE walmart
SET date = STR_TO_DATE(date, '%d/%m/%y');

ALTER TABLE walmart
MODIFY date DATE;

SELECT branch, 
    day_name,
    all_transactions
FROM
(SELECT 
    branch, 
    DAYNAME(date) AS day_name, 
    COUNT(*) AS all_transactions,
    RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS rankings
FROM
    walmart
GROUP BY 1,2
ORDER BY 1,3 DESC) ranked
WHERE rankings = 1;

-- Q.4. Calculate the total quantity of items sold per payment method. List payment method and total quantity.

SELECT 
    payment_method, COUNT(quantity), SUM(quantity)
FROM
    walmart
GROUP BY 1
ORDER BY 2 DESC;

-- Q.5.Determine the most frequently used payment method for each branch.
-- Display branch and the preferred_payment method.

SELECT 
branch,
    payment_method,
    number_of_payments
FROM
(SELECT 
    branch,
    payment_method,
    COUNT(payment_method) AS number_of_payments,
    DENSE_RANK() OVER(PARTITION BY branch) AS rankings
FROM
    walmart
GROUP BY 1 , 2)ranked
WHERE rankings = 1;


WITH cte AS
(SELECT
branch,
payment_method,
COUNT(*) AS total_transactions,
RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS rankings
FROM walmart
GROUP BY 1,2)
SELECT branch, payment_method, total_transactions FROM cte
WHERE rankings = 1;

-- Q.6. Categorise sales into 3 groups MORNING, AFTERNOON, EVENING.
--  Find out which of the shift and number of invoices.

SELECT 
branch,
    CASE
        WHEN HOUR(TIME(time)) < 12 THEN 'MORNING'
        WHEN HOUR(TIME(time)) BETWEEN 12 AND 17 THEN 'AFTERNOON'
        ELSE 'EVENING'
    END day_time,
    COUNT(*)
FROM
    walmart
GROUP BY 1,2
ORDER BY 1,3 DESC;

-- Q.7. What is the total revenue and profit by branch city?

SELECT 
    branch,
    city,
    SUM(total) AS total_revenue,
    SUM(total * profit_margin) AS total_profit
FROM walmart
GROUP BY 1,2
ORDER BY total_revenue DESC;


-- Q.9. Which product categories generate the highest revenue?

SELECT 
    category,
    ROUND(SUM(total),2) AS total_revenue
FROM walmart
GROUP BY category
ORDER BY total_revenue DESC;


-- Q.10. What is the most profitable category based on average profit margin?

SELECT 
    category, ROUND(AVG(profit_margin),2) AS average_profit_margin
FROM
    walmart
GROUP BY 1
ORDER BY AVG(profit_margin) DESC;

-- What are the top 3 categories by revenue in each city?

SELECT * FROM
(SELECT
    city, category, SUM(total),
    RANK() OVER(PARTITION BY city ORDER BY SUM(total) DESC) AS rankings
FROM
    walmart
GROUP BY 1,2)ranked
WHERE rankings <=3
;

-- Q.12. Are higher-rated transactions associated with higher sales?

SELECT * FROM walmart;

SELECT 
    CASE 
        WHEN rating >= 8 THEN 'High Rating'
        WHEN rating >= 5 THEN 'Medium Rating'
        ELSE 'Low Rating'
    END AS rating_group,
    ROUND(AVG(total), 2) AS avg_sales
FROM walmart
GROUP BY rating_group;



-- Q.13. Identify 5 branch with highest decrease percentage ratio in revenue compare to last year (current year is 2023).

WITH 
rev_2023 AS
(
SELECT 
	branch,
	SUM(total) AS total_revenue_2023
FROM walmart
WHERE YEAR(date) = 2023
GROUP BY 1),
rev_2022 AS
(
SELECT 
	branch,
	SUM(total) AS total_revenue_2022
FROM walmart
WHERE YEAR(date) = 2022
GROUP BY 1)

SELECT 
    ls.branch, total_revenue_2022, total_revenue_2023,
    ROUND(((total_revenue_2022 - total_revenue_2023)/total_revenue_2022),4) * 100 AS ratio
FROM
    rev_2022 AS ls
        JOIN
    rev_2023 AS cs ON ls.branch = cs.branch
WHERE
    total_revenue_2022 > total_revenue_2023
ORDER BY 4 DESC
LIMIT 5;