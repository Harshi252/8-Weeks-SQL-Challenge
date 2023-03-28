--------------------------------
--CASE STUDY #1: DANNY'S DINER--
--------------------------------
CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

------------------------
--CASE STUDY QUESTIONS--
------------------------

---1. What is the total amount each customer spent at the restaurant?
select 
  customer_id, 
  sum(price)
from 
  dannys_diner.sales s
join dannys_diner.menu m
  on s.product_id = m.product_id
group by 
  s.customer_id
order by 
  s.customer_id;

---2. How many days has each customer visited the restaurant?
select 
  s.customer_id, 
  count(s.order_date)
from 
  dannys_diner.sales s
group by 
  s.customer_id
order by 
  s.customer_id;

---3. What was the first item from the menu purchased by each customer?
with ranked as (
    select
      s.customer_id,
      s.order_date,
      s.product_id,
      m.product_name,  
        row_number() over(
       	partition by s.customer_id
       	order by s.order_date, s.product_id
     	) as ranking
    	from dannys_diner.sales s
          join dannys_diner.menu m
     	on s.product_id = m.product_id
      )
select
    customer_id,
    product_name,
    order_date::varchar   #used varchar to remove timestamp, cast is used
from
    ranked
where
    ranking = 1;
    
---4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select
    s.product_id,
    m.product_name,
    count(s.product_id) as total_count
from
   	dannys_diner.sales s
join dannys_diner.menu m
   	on s.product_id = m.product_id
group by
    s.product_id,
    m.product_name
order by
    s.product_id desc
    Limit 1;

---5. Which item was the most popular for each customer?
with ranked as(
  select
      s.customer_id,
      s.product_id,
      m.product_name,
	count(s.product_id) as total_count,
      rank() over(
  	partition by s.customer_id
  	order by count(s.product_id) desc
  	) as ranking
   from dannys_diner.sales s
   join dannys_diner.menu m
   on s.product_id = m.product_id
   group by
      1, 2, 3
 )

select
  customer_id,
  product_id,
  product_name, 
  total_count
from
  ranked
where
  ranking = 1;
 

---6. Which item was purchased first by the customer after they became a member?
with joined as (
  select
    s.customer_id,
    s.order_date::varchar,
    s.product_id,
    m.product_name,
    mm.join_date::varchar,
    row_number() over
     	(partition by s.customer_id
     	order by order_date) as rank
 from
    dannys_diner.sales s
 join
    dannys_diner.menu m on s.product_id = m.product_id
 join
    dannys_diner.members mm on s.customer_id = mm.customer_id
 where
    s.order_date >= mm.join_date)

SELECT
    customer_id,
    product_id,
    product_name
from
   joined
where
   rank = 1;

---7. Which item was purchased just before the customer became a member?
with joined as (
  select
    s.customer_id,
    s.order_date::varchar,
    s.product_id,
    m.product_name,
    mm.join_date::varchar,
    rank() over
     	(partition by s.customer_id
        order by order_date) as rank
  from
    dannys_diner.sales s
  join
    dannys_diner.menu m on s.product_id = m.product_id
  join
    dannys_diner.members mm on s.customer_id = mm.customer_id
  where
    s.order_date <= mm.join_date)

SELECT
    customer_id,
    product_id,
    product_name
from
   joined
where
   rank = 1;


---8. What is the total items and amount spent for each member before they became a member?
with joined as (
  select
      s.customer_id,
      count(s.product_id),
      sum(m.price) as total_spent
  from
      dannys_diner.sales s
  join
      dannys_diner.menu m on s.product_id = m.product_id
  join
      dannys_diner.members mm on s.customer_id = mm.customer_id
  where
    s.order_date < mm.join_date
  group by
    1
  order by
    s.customer_id)

SELECT
    *
from
   joined;

---9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with points as(
    select
    	s.customer_id,
    	m.product_name,
    	m.price,
    	case
      	when m.product_name = 'curry' or m.product_name = 'ramen'
      	then m.price * 10
      	else m.price * 20
    	end as points
    FROM
    	dannys_diner.sales s
    	join dannys_diner.menu m on s.product_id = m.product_id
   	order by
      	s.customer_id, m.product_name
      )

SELECT
    customer_id,
    sum(points)
FROM
   points
group by
   1
order by
    customer_id;

---10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January
with points as(
    select
    	s.customer_id,
     	s.order_date,
    	m.product_name,
    	m.price,
    	case
     		 WHEN m.product_name = 'sushi' THEN 2 * 10 * m.price
     		 WHEN s.order_date BETWEEN mm.join_date AND mm.join_date + integer '6' THEN 2 * 10 * m.price
     		 ELSE 10 * m.price
    	end as points
    FROM
    	dannys_diner.sales s
    join dannys_diner.menu m on s.product_id = m.product_id
    join dannys_diner.members mm on s.customer_id = mm.customer_id
    where
     	date_part('month', s.order_date) = 01
   	order by
      	s.customer_id, m.product_name
      )

SELECT
    customer_id,
    sum(points)
FROM
   	points
group by
   	1
order by
   	1;

---Bonus Question: The following questions are related creating basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL.
select
    s.customer_id,
	s.order_date::varchar,
	m.product_name,
	m.price,
    (case
   	 when s.order_date >= mm.join_date
   	 then 'Y'
   	 else 'N'
    end) as member
from 
    dannys_diner.sales s
join dannys_diner.menu m on s.product_id = m.product_id
left join dannys_diner.members mm on s.customer_id = mm.customer_id
order by 
    1,2,3;

---Bonus Question: Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.
WITH members AS (
	SELECT
  	s.customer_id,
  	s.order_date::varchar,
  	m.product_name,
  	m.price,
  	CASE
    	WHEN s.order_date >= mm.join_date THEN 'Y'
    	ELSE 'N'
  	END AS member
	FROM
  	dannys_diner.sales AS s
  	JOIN dannys_diner.menu AS m ON s.product_id = m.product_id
  	LEFT JOIN dannys_diner.members AS mm ON s.customer_id = mm.customer_id
  )
SELECT
  *,
  CASE
	WHEN member = 'Y' THEN rank() OVER (
  	PARTITION BY customer_id, member
  	ORDER by order_date
	)
  END AS ranking
FROM
  members
ORDER BY
  1,2,3;
