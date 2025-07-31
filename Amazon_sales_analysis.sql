-- Which users are the top 5 reviewers by the number of reviews they have written? 

SELECT 
    user_id, user_name, COUNT(review_id) AS review_count
FROM
    reviews
GROUP BY user_id , user_name
ORDER BY review_count DESC
LIMIT 5;

-- Which day of the week has the highest number of orders on Amazon?

SELECT 
    DAYNAME(order_date) AS day_of_week, COUNT(*) AS total_orders
FROM
    orders
GROUP BY day_of_week
ORDER BY total_orders DESC;

-- Is there a relationship between higher ratings and units sold for products on Amazon?

SELECT 
    p.product_id,
    p.rating,
    IFNULL(SUM(o.units_sold), 0) AS total_units_sold
FROM
    products AS p
        JOIN
    orders AS o ON o.product_id = p.product_id
GROUP BY p.product_id

ORDER BY total_units_sold aSC, rating desc;
    
-- Which products generate the highest total revenue for Amazon?

SELECT 
    product_name,
    SUBSTRING_INDEX(category, '|', 1) AS category,
    SUM(units_sold) AS total_units_sold,
    ROUND(SUM(o.units_sold * p.discounted_price) / 1E6,
            2) AS total_revenue_million
FROM
    products AS p
        JOIN
    orders AS o ON o.product_id = p.product_id
GROUP BY product_name , category
ORDER BY total_revenue_million DESC
LIMIT 20;

-- Identify the top 5 categories with the highest revenue per unit sold on Amazon.

with top_5 as (SELECT 
    SUBSTRING_INDEX(category, '|', 1) AS category,
    ROUND(SUM(o.units_sold * p.discounted_price),
            2) AS total_revenue,
    SUM(units_sold) AS total_units_sold
FROM
    products AS p
        JOIN
    orders AS o ON o.product_id = p.product_id 
    group by 
   SUBSTRING_INDEX(category, '|', 1) ) 
  SELECT 
    category,
    total_revenue,
    ROUND(total_revenue / total_units_sold, 2) AS revenue_per_unit
FROM
    top_5
ORDER BY revenue_per_unit DESC
LIMIT 5;
    
-- Identify High Discount Products with Low Sales 

SELECT 
    p.product_name,
    SUBSTRING_INDEX(p.category, '|', 1) AS category,
    ROUND(p.discount_percentage * 100, 2) AS discount_percent,
    COALESCE(SUM(o.units_sold), 0) AS total_units_sold,
    ROUND(p.rating, 2) AS rating
FROM products AS p
LEFT JOIN orders AS o ON p.product_id = o.product_id
GROUP BY p.product_id, p.product_name, category, p.discount_percentage, p.rating
HAVING 
    discount_percent > 50 AND 
    total_units_sold < 10
ORDER BY discount_percent DESC;

-- Catergory wise sales summary

CREATE VIEW category_sales_summary AS
    SELECT 
        SUBSTRING_INDEX(p.category, '|', 1) AS category,
        ROUND(SUM(o.units_sold * p.discounted_price) / 1E6,
                2) AS total_revenue_millions,
        FORMAT(SUM(o.units_sold), 0) AS units_sold,
        ROUND(AVG(p.discount_percentage), 2) AS average_discount,
        ROUND(AVG(p.rating), 2) AS average_rating,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM
        orders AS o
            JOIN
        products AS p ON o.product_id = p.product_id
    GROUP BY SUBSTRING_INDEX(p.category, '|', 1)
    ORDER BY total_revenue_millions DESC;
    
-- Store Procedure to get Top_N Products by Revenue

DELIMITER $$

CREATE PROCEDURE GetTopProductsByRevenue(IN top_n INT)
BEGIN
    SELECT 
        p.product_name,
        ROUND(SUM(o.units_sold * p.discounted_price), 2) AS total_revenue,
        SUM(o.units_sold) AS units_sold,
        ROUND(AVG(p.rating), 2) AS avg_rating
    FROM orders AS o
    JOIN products AS p ON o.product_id = p.product_id
    GROUP BY p.product_name
    ORDER BY total_revenue DESC
    LIMIT top_n;
END $$

DELIMITER ;

call GetTopProductsByRevenue();





