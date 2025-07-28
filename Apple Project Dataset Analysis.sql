-- Apple Retail Sales Project - 1 Million Rows Dataset

-- DROP TABLE commands

DROP TABLE IF EXISTS category;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS stores;
DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS warranty;

-- CREATE TABLE commands

CREATE TABLE category 
	(category_id VARCHAR(10) PRIMARY KEY, 
	category_name VARCHAR(20));

CREATE TABLE products 
(product_id	VARCHAR(10) PRIMARY KEY, 
product_name VARCHAR(35), 
category_id	VARCHAR(10), 
launch_date	date, 
price FLOAT, 
CONSTRAINT fk_category FOREIGN KEY (category_id) REFERENCES category(category_id)
);

CREATE TABLE stores 
(store_id VARCHAR(5) PRIMARY KEY, 
store_name	VARCHAR(30), 
city VARCHAR(25), 
country VARCHAR(25));

CREATE TABLE sales 
(sale_id VARCHAR(15) PRIMARY KEY, 
sale_date DATE, 
store_id VARCHAR(10), 
product_id VARCHAR(10), 
quantity INT, 
CONSTRAINT fk_store FOREIGN KEY (store_id) REFERENCES stores(store_id), 
CONSTRAINT fk_product FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE warranty 
(claim_id VARCHAR(10) PRIMARY KEY, 
claim_date DATE, 
sale_id VARCHAR(15), 
repair_status VARCHAR(15), 
CONSTRAINT fk_orders FOREIGN KEY (sale_id) REFERENCES sales(sale_id)
);

-- SUCCESS MESSAGE
SELECT 'Schema Created Successful' AS Success_Message;


-- Exploratory Data Analysis
SELECT COUNT(*) FROM sales;

SELECT DISTINCT repair_status FROM warranty;

SELECT COUNT(DISTINCT country) FROM stores;
SELECT DISTINCT country FROM stores;

-- Improving Query Performance

EXPLAIN ANALYZE 
SELECT * FROM sales 
WHERE product_id = 'P-44';

-- Et : 750.6 ms
-- Pt : 0.198 ms

CREATE INDEX sales_product_id ON sales(product_id);

EXPLAIN ANALYZE 
SELECT * FROM sales 
WHERE product_id = 'P-44';

-- Et after Index Creation : 8.7 ms

EXPLAIN ANALYZE 
SELECT * FROM sales 
WHERE store_id = 'ST-31';

-- Et : 822.43 ms
-- Pt : 0.256 ms

CREATE INDEX sales_store_id ON sales(store_id);

EXPLAIN ANALYZE 
SELECT * FROM sales 
WHERE store_id = 'ST-31';

-- Et after Index Creation : 2.62 ms

CREATE INDEX sales_sale_date ON sales(sale_date);




-- Business Problems

-- 1. Find the number of stores in each country.

SELECT country, COUNT(*) AS stores_count 
FROM stores 
GROUP BY country 
ORDER BY 2 DESC;

-- 2. Calculate the total number of units sold by each store.

SELECT store_id, SUM(quantity) AS total_units_sold 
FROM sales 
GROUP BY store_id 
ORDER BY 2 DESC;

-- 3. Identify how many sales occurred in December 2023.

SELECT * FROM sales;

SELECT COUNT(sale_id) AS total_sales 
FROM sales 
WHERE TO_CHAR(sale_date, 'YYYY-MM') = '2023-12';

-- 4. Determine how many stores have never had a warranty claim filed.

SELECT * FROM warranty;

SELECT COUNT(store_id) AS total_stores FROM stores 
WHERE store_id NOT IN 
					(SELECT DISTINCT store_id FROM sales s 
					RIGHT JOIN warranty w 
					ON s.sale_id = w.sale_id);

-- 5. Calculate the percentage of warranty claims marked as "Warranty Void".

SELECT 
	ROUND(SUM(CASE WHEN repair_status = 'Warranty Void' THEN 1 ELSE 0 END) * 100 / COUNT(*), 2) 
AS warranty_void_percentage 
FROM warranty;

-- 6. Identify which store had the highest total units sold in the last year.

SELECT st.store_id, st.store_name, SUM(s.quantity) AS highest_units_sold 
FROM stores st 
JOIN sales s 
ON st.store_id = s.store_id 
WHERE TO_CHAR(sale_date, 'YYYY') = '2023' 
GROUP BY 1, 2 
ORDER BY 3 DESC LIMIT 1;

-- 7. Count the number of unique products sold in the last year.

SELECT COUNT(DISTINCT product_id) AS unique_products_count 
FROM sales 
WHERE TO_CHAR(sale_date, 'YYYY') = '2023';

-- 8. Find the average price of products in each category.

SELECT p.category_id, c.category_name, AVG(p.price) AS avg_price 
FROM products p 
JOIN category c 
ON p.category_id = c.category_id 
GROUP BY 1, 2 
ORDER BY 3 DESC;

-- 9. How many warranty claims were filed in 2020?

SELECT * FROM warranty;

SELECT COUNT(claim_id) AS warranty_claims 
FROM warranty 
WHERE EXTRACT(YEAR FROM claim_date) = '2020';

-- 10. For each store, identify the best-selling day based on highest quantity sold.

SELECT * FROM sales;

SELECT * FROM 
	(SELECT store_id, 
	SUM(quantity) AS highest_quantity_sold, 
	TO_CHAR(sale_date::date, 'Day') AS day_of_week, 
	RANK() OVER(PARTITION BY store_id ORDER BY SUM(quantity) DESC) AS rank 
	FROM sales 
	GROUP BY 1, 3 
	ORDER BY 2 DESC) AS best_selling_day 
WHERE rank = 1;

-- 11. Identify the least selling product in each country for each year based on total units sold.

SELECT * FROM 
	(SELECT st.country, p.product_name, 
	TO_CHAR(s.sale_date, 'YYYY') AS year, 
	SUM(s.quantity) AS total_units_sold, 
	RANK() OVER(PARTITION BY st.country ORDER BY SUM(s.quantity)) AS rank 
	FROM sales s 
	JOIN products p ON p.product_id = s.product_id 
	JOIN stores st ON st.store_id = s.store_id 
	GROUP BY 1, 2, 3 
	ORDER BY 4) AS least_selling_product 
WHERE rank = 1;

-- 12. Calculate how many warranty claims were filed within 180 days of a product sale.

SELECT * FROM warranty;

SELECT COUNT(claim_id) AS num_warranty_claims 
FROM warranty w 
LEFT JOIN sales s 
ON w.sale_id = s.sale_id 
WHERE (w.claim_date - s.sale_date) <= 180;

-- 13. Determine how many warranty claims were filed for products launched in the last two years.

SELECT * FROM products;

SELECT COUNT(w.claim_id) AS num_warranty_claims 
FROM warranty w 
JOIN sales s 
ON w.sale_id = s.sale_id 
RIGHT JOIN products p 
ON s.product_id = p.product_id 
WHERE p.launch_date >= CURRENT_DATE - INTERVAL '2 year';

-- 14. List the months in the last three years where sales exceeded 5,000 units in the USA.

SELECT * FROM sales;
SELECT * FROM stores;

SELECT 
	TO_CHAR(s.sale_date, 'MM-YYYY') AS months, 
	SUM(quantity) AS total_units 
FROM sales s 
JOIN stores st 
ON s.store_id = st.store_id 
WHERE st.country = 'USA' 
AND s.sale_date >= CURRENT_DATE - INTERVAL '3 year' 
GROUP BY 1 
HAVING SUM(quantity) > 5000;

-- 15. Identify the product category with the most warranty claims filed in the last two years.

SELECT * FROM category;

SELECT c.category_id, c.category_name, COUNT(w.claim_id) AS max_warranty_claims 
FROM category c 
LEFT JOIN products p 
ON c.category_id = p.category_id 
JOIN sales s 
ON s.product_id = p.product_id 
JOIN warranty w 
ON w.sale_id = s.sale_id 
WHERE w.claim_date >= CURRENT_DATE - INTERVAL '2 year' 
GROUP BY 1, 2 
ORDER BY 3 DESC;

-- 16. Determine the percentage chance of receiving warranty claims after each purchase for each country.

SELECT * FROM stores;
SELECT * FROM warranty;
SELECT * FROM sales;

SELECT st.country, 
	ROUND(COUNT(w.claim_id) * 100 / SUM(s.quantity), 2) AS warranty_claims_percentage 
FROM stores st 
LEFT JOIN sales s 
ON st.store_id = s.store_id 
LEFT JOIN warranty w 
ON s.sale_id = w.sale_id 
GROUP BY 1 
ORDER BY 2 DESC;

-- 17. Calculate the correlation between product price and warranty claims for products sold in the last five years, segmented by price range.

SELECT * FROM warranty;

SELECT CASE 
	WHEN p.price < 500 THEN 'Less Expensive Product' 
	WHEN p.price BETWEEN 500 AND 1000 THEN 'Mid Ranged Product' 
	ELSE 'Highly Expensive Product' 
END AS price_segment, 
COUNT(w.claim_id) AS num_warranty_claims 
FROM warranty w 
LEFT JOIN sales s 
ON s.sale_id = w.sale_id 
JOIN products p 
ON p.product_id = s.product_id 
WHERE w.claim_date >= CURRENT_DATE - INTERVAL '5 years' 
GROUP BY 1;

-- 18. Identify the store with the highest percentage of "Paid Repaired" claims relative to total claims filed.

SELECT * FROM warranty;

WITH total_repairs AS 
(SELECT st.store_id, st.store_name, COUNT(w.claim_id) AS total_claims 
FROM stores st 
JOIN sales s ON st.store_id = s.store_id 
JOIN warranty w ON w.sale_id = s.sale_id 
GROUP BY 1, 2), 
paid_repairs AS 
(SELECT st.store_id, st.store_name, COUNT(w.claim_id) AS repaired_claims 
FROM stores st 
JOIN sales s ON st.store_id = s.store_id 
JOIN warranty w ON w.sale_id = s.sale_id 
WHERE repair_status = 'Paid Repaired' 
GROUP BY 1, 2) 

SELECT 
tr.store_id, 
tr.store_name, 
pr.repaired_claims, 
tr.total_claims, 
ROUND((pr.repaired_claims::numeric / tr.total_claims::numeric) * 100, 2) AS paid_repaired_percentage 
FROM total_repairs tr 
JOIN paid_repairs pr 
ON tr.store_id = pr.store_id 
ORDER BY 5 DESC;

-- 19. Analyze the year-by-year growth ratio for each store.

SELECT * FROM sales;

WITH yearly_sales AS 
(SELECT 
	st.store_id, 
	st.store_name, 
	EXTRACT(YEAR FROM s.sale_date) AS year, 
	SUM(s.quantity * p.price) AS total_sales 
	FROM sales s 
	JOIN products p ON s.product_id = p.product_id 
	JOIN stores st ON s.store_id = st.store_id 
	GROUP BY 1, 2, 3 
	ORDER BY 1, 3), 
growth_ratio AS 
	(SELECT store_id, store_name, year, 
	LAG(total_sales, 1) OVER(PARTITION BY store_id ORDER BY year) 
	AS last_year_sales, 
	total_sales AS current_year_sales 
	FROM yearly_sales) 

SELECT 
	store_id, 
	store_name, 
	year, 
	last_year_sales, 
	current_year_sales, 
	ROUND(((current_year_sales - last_year_sales)::numeric/ last_year_sales::numeric) * 100, 2) 
	AS growth_ratio 
FROM growth_ratio 
WHERE last_year_sales IS NOT NULL;

-- 20. Write a query to calculate the monthly running total of sales for each store over the past four years and compare trends during this period.

WITH monthly_sales AS 
(SELECT 
	s.store_id, 
	TO_CHAR(s.sale_date, 'YYYY') AS year, 
	TO_CHAR(s.sale_date, 'MM') AS month, 
	SUM(s.quantity * p.price) AS total_sales 
FROM sales s 
JOIN products p 
ON s.product_id = p.product_id 
WHERE s.sale_date >= CURRENT_DATE - INTERVAL '4 year' 
GROUP BY 1, 2, 3 
ORDER BY 1, 2, 3)

SELECT *, SUM(total_sales) OVER(PARTITION BY store_id ORDER BY year, month) 
AS running_total 
FROM monthly_sales;

-- 21. Analyze product sales trends over time, segmented into key periods: from launch to 6 months, 6-12 months, 12-18 months, and beyond 18 months.

SELECT * FROM products;
SELECT * FROM sales;

SELECT p.product_name, SUM(s.quantity) AS total_qty_sold, 
CASE 
	WHEN s.sale_date BETWEEN p.launch_date AND p.launch_date + INTERVAL '6 month' THEN 'launch to 6 months' 
	WHEN s.sale_date BETWEEN p.launch_date + INTERVAL '6 month' AND p.launch_date + INTERVAL '12 month' THEN '6 to 12 months' 
	WHEN s.sale_date BETWEEN p.launch_date + INTERVAL '12 month' AND p.launch_date + INTERVAL '18 month' THEN '12 to 18 months' 
	ELSE 'beyond 18 months' 
END AS key_periods 
FROM products p JOIN sales s 
ON p.product_id = s.product_id 
GROUP BY 1, 3 
ORDER BY 1, 2 DESC;




