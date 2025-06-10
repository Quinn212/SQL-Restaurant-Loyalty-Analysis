/* Question 1 : What is the total amount each customer spent at the restaurant? */ 
SELECT  customer_id, sum(price) AS amount 
FROM sales
LEFT JOIN menu 
ON sales.product_id = menu.product_id
GROUP BY customer_id;


/* Question 2 : How many days has each customer visited the restaurant? */ 
SELECT customer_id, COUNT(DISTINCT(order_date))
FROM sales
GROUP BY customer_id;


/* Question 3 : What was the first item from the menu purchased by each customer? */
/* This Code shows all items purchased for each customer their first day dining there */
SELECT a.product_name, a.order_date, a.customer_id
FROM 
	(SELECT * 
	FROM sales
	LEFT JOIN menu
	ON sales.product_id = menu.product_id) AS a
INNER JOIN 
	(SELECT MIN(order_date) AS order_date, customer_id
	FROM sales
	GROUP BY customer_id) AS b
ON a.order_date = b.order_date AND a.customer_id = b.customer_id
ORDER BY customer_id;


/* Question 4 : What is the most purchased item on the menu and how many times was it purchased by all customers? */ 
SELECT a.product_id, b.product_name, a.count   
FROM
	(SELECT COUNT(product_id) AS count, product_id
	FROM sales
	GROUP BY product_id)
	AS a
JOIN menu AS b
ON a.product_id = b.product_id
ORDER BY a.count DESC;


/* Question 5 : Which item was the most popular for each customer? */
/* This code returns the product ID, name, and count purchased for the most purchased item by customer*/
SELECT a.customer_id, b.product_id, c.product_name, a.count  FROM (
	SELECT MAX(count) AS count, customer_id
	FROM 
		(SELECT COUNT(product_id) AS count, product_id, customer_id
		FROM sales
		GROUP BY customer_id, product_id)
	GROUP BY customer_id
	) AS a
INNER JOIN 
	(SELECT COUNT(product_id) AS count, product_id, customer_id
	FROM sales
	GROUP BY customer_id, product_id ) AS b
ON a.customer_id = b.customer_id AND a.count = b.count
LEFT JOIN 
	(SELECT product_id, product_name
	FROM menu) AS c
ON b.product_id = c.product_id
ORDER BY customer_id, product_id ASC;



/* Question 6 : Which item was purchased first by the customer after they became a member? */ 
SELECT c.customer_id, d.order_date, d.product_id, e.product_name
FROM (
	SELECT MIN(order_date) AS order_date_min, customer_id
	FROM (
		SELECT a.customer_id, b.order_date, b.product_id
		FROM members AS a
		LEFT JOIN sales AS b
		ON a.customer_id = b.customer_id AND a.join_date <= b.order_date)
	GROUP BY customer_id) AS c
INNER JOIN
	(SELECT a.customer_id, b.order_date, b.product_id
	FROM members AS a
	LEFT JOIN sales AS b
	ON a.customer_id = b.customer_id AND a.join_date <= b.order_date) AS d
ON d.order_date = c.order_date_min AND c.customer_id = d.customer_id
LEFT JOIN menu AS e
ON d.product_id = e.product_id
ORDER BY customer_id ASC;


/* Question 7 : Which item was purchased just before the customer became a member? */ 
SELECT c.customer_id, d.order_date, d.product_id, e.product_name
FROM (
	SELECT MAX(order_date) AS max_order_date, customer_id
	FROM (
		SELECT a.customer_id, b.order_date, b.product_id
		FROM members AS a
		LEFT JOIN sales AS b
		ON a.customer_id = b.customer_id AND a.join_date > b.order_date)
	GROUP BY customer_id) AS c
INNER JOIN
	(SELECT a.customer_id, b.order_date, b.product_id
	FROM members AS a
	LEFT JOIN sales AS b
	ON a.customer_id = b.customer_id AND a.join_date > b.order_date) AS d
ON d.order_date = c.max_order_date AND c.customer_id = d.customer_id
LEFT JOIN menu AS e
ON d.product_id = e.product_id
ORDER BY customer_id ASC;


/* Question 8 : What is the total items and amount spent for each member before they became a member? */ 
SELECT customer_id, COUNT(customer_id), SUM(price)
FROM
	(SELECT a.customer_id, b.order_date, b.product_id, c.price
	FROM members AS a
	LEFT JOIN sales AS b
	ON a.customer_id = b.customer_id AND a.join_date > b.order_date
	LEFT JOIN menu AS c
	ON b.product_id = c.product_id)
GROUP BY customer_id
ORDER BY customer_id ASC;


/* Question 9 : If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have? */ 
SELECT customer_id, SUM(points)
FROM
	(SELECT a.customer_id, a.product_id, b.product_name, b.price, (price*10 + price*10*(CASE WHEN b.product_name ='sushi' THEN 1 ELSE 0 END)) AS points
	FROM sales AS a
	LEFT JOIN menu AS b
	ON a.product_id = b.product_id)
GROUP BY customer_id
ORDER BY customer_id;


/* Question 10 : In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January? */ 
--The 3 vars in sales do not uniquely identify obs, make a sales id column.
ALTER TABLE sales ADD COLUMN sale_id bigserial;
SELECT * FROM sales;
	
--INNER JOIN all first membership week orders with all relevant orders to get all 2x points orders
SELECT customer_id, SUM(points) AS points
FROM
	(SELECT c.customer_id, (20*price) AS points
	FROM
		--identify all orders that are within first week of membership
		(SELECT a.customer_id, b.order_date, b.product_id, b.sale_id
		FROM members AS a
		INNER JOIN sales AS b
		ON a.customer_id = b.customer_id AND a.join_date <= b.order_date AND a.join_date+6 > b.order_date) AS c
	INNER JOIN
		--identify all orders that are before end of january and belong to customer A or B (Pool of Relevant Orders)
		(SELECT *
		FROM sales
		LEFT JOIN menu ON sales.product_id = menu.product_id
		WHERE order_date < '2021-02-01' AND customer_id IN ('A', 'B')) AS d
	ON c.sale_id = d.sale_id
	UNION ALL
	--RIGHT JOIN where a.key is null, first membership weeks with all jan orders to get all standard points orders
	SELECT f.customer_id, (price*10 + price*10*(CASE WHEN f.product_name ='sushi' THEN 1 ELSE 0 END)) AS points
	FROM
		--identify all orders that are within first week of membership
		(SELECT a.customer_id, b.order_date, b.product_id, b.sale_id
		FROM members AS a
		INNER JOIN sales AS b
		ON a.customer_id = b.customer_id AND a.join_date <= b.order_date AND a.join_date+6 > b.order_date) AS e
	RIGHT JOIN
		--identify all orders that are before end of january and belong to customer A or B (Pool of Relevant Orders)
		(SELECT *
		FROM sales
		LEFT JOIN menu ON sales.product_id = menu.product_id
		WHERE order_date < '2021-02-01' AND customer_id IN ('A', 'B')) AS f
	ON e.sale_id = f.sale_id
	WHERE e.sale_id IS NULL)
GROUP BY customer_id
ORDER BY customer_id ASC;




