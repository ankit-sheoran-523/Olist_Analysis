## CREATING DATABASE
create database olist_project;
use olist_project;



## ALL THE TABLES AND DATASETS ARE LOADED USING PYMYSQL


## CHECK DATASET FOR TABLES
select count(distinct(order_id)) from orders;
select * from orders limit 5;
 

SELECT COUNT(*) FROM order_items;
SELECT COUNT(DISTINCT order_id) FROM order_items;
select * from orders limit 5; 


SELECT COUNT(*) FROM cust;
SELECT COUNT(DISTINCT cust_unique_id) FROM cust;


SELECT COUNT(*) FROM geolocation;
SELECT COUNT(DISTINCT geolocation_zip_code_prefix) FROM geolocation;


SELECT COUNT(*) FROM order_payments;
SELECT COUNT(DISTINCT order_id) FROM order_payments;


SELECT COUNT(*) FROM order_reviews;
SELECT COUNT(DISTINCT review_id) FROM order_reviews;



SELECT AVG(review_score) FROM order_reviews;

SELECT COUNT(*) FROM products;
SELECT DISTINCT prod_category_name FROM products;	

SELECT COUNT(*) FROM sellers;
SELECT COUNT(DISTINCT seller_state) FROM sellers;


SELECT COUNT(*) FROM prod_cat_translation;
SELECT DISTINCT prod_cat_name FROM prod_cat_translation;


## ESTABLISHING FOREIGN KEYS

ALTER TABLE order_items 
ADD CONSTRAINT fk_items_order FOREIGN KEY (order_id) REFERENCES orders(order_id),
ADD CONSTRAINT fk_items_prod FOREIGN KEY (prod_id) REFERENCES products(prod_id),
ADD CONSTRAINT fk_items_seller FOREIGN KEY (seller_id) REFERENCES sellers(seller_id);


ALTER TABLE orders 
ADD CONSTRAINT fk_orders_cust 
FOREIGN KEY (cust_id) REFERENCES cust(cust_id);


ALTER TABLE order_payments 
ADD CONSTRAINT fk_payments_order 
FOREIGN KEY (order_id) REFERENCES orders(order_id);


ALTER TABLE order_reviews 
ADD CONSTRAINT fk_reviews_order 
FOREIGN KEY (order_id) REFERENCES orders(order_id);


ALTER TABLE products 
ADD CONSTRAINT fk_prod_translation 
FOREIGN KEY (prod_category_name) REFERENCES prod_cat_translation(prod_cat_name);



-- ==========================================================================
-- MODULE 1: Executive Dashboard & Revenue Trajectory
-- ==========================================================================

-- 1. Total Marketplace Scale
with cte1 as
(select sum(payment_value) as GMV,ROUND(SUM(payment_value) / COUNT(DISTINCT order_id), 2) AS Average_Order_Value
from order_payments),
cte2 as
(select sum(price) as 'Net revenue',count(distinct prod_id) as 'Total Unique Products',sum(freight_value) as 'Total Shipping Charges'
from order_items),
cte3 as
(select count(distinct order_id) as 'Total orders' from orders)

select cte1.*,cte2.*,cte3.* from cte1,cte2,cte3;


-- 2. Average Order Value (AOV)

select count(payment_value) from order_payments where payment_value is null;
select avg(payment_value) as Avg_order_value from order_payments;


with cte1 as 
(select sum(payment_value) as payment_order from order_payments group by order_id),

cte2 as 
(select avg(cte1.payment_order) as AOV from cte1),

cte3 as 
(select avg(coalesce(freight_value,0)) as Avg_shipping_charges from order_items),

cte4 as 
(select order_id,count(order_id) as items_order from order_items group by order_id),

cte5 as
(select avg(cte4.items_order) as Avg_item_order from cte4)

select  round(AOV,2) as AOV, round(cte3.Avg_shipping_charges,2) as 'Avg Shipping Charges', round(cte5.Avg_item_order,0) as 'Avg products per order'
from cte2,cte3,cte5;


-- 3. Payment Distribution Matrix
select 
	payment_type as Payment_Type,
	count(payment_type) as Total_Transaction, 
    sum(payment_value) as Total_Transaction_Revenue,
    round(sum(payment_value)*100/sum(sum(payment_value)) over(),2) as revenue_share_percentage
from order_payments
group by payment_type;

-- 4. Credit Installment Impact

select distinct payment_type from order_payments;


DELIMITER //
create procedure installment_analysis(in pt varchar(20))
begin 
select payment_installments,
count(*) as Total_Transactions,
round(avg(payment_value),2) as Avg_Transaction_Amount,
sum(payment_value) as Total_Transaction_Amount
from order_payments
where payment_type = pt
group by payment_installments
order by payment_installments;
end
// DELIMITER ;

call installment_analysis('credit_card'); -- select from these [credit_card, boleto, voucher, debit_card, not_defined]
call installment_analysis('boleto');



-- 5. Peak Traffic Mapping

select dt.hrs,count(dt.hrs) as orders_time from(
select hour(order_purchase_timestamp) as hrs
from orders) as dt
group by dt.hrs
order by orders_time desc;


select dt.weekday,count(dt.weekday) as weekday_orders from
(select dayname(order_purchase_timestamp) as weekday
from orders) as dt
group by weekday
order by weekday_orders desc;


-- 6. Cumulative Financial Momentum
select *,sum(total_revenue) over ( order by year,month) as cummulative_Revenue
from
(
select Year,month,monthname,sum(payment_value) as total_revenue
from 
(select order_id,year(order_purchase_timestamp) as Year,month(order_purchase_timestamp) as month, monthname(order_purchase_timestamp) as monthname from orders) as o 
inner join order_payments as op on op.order_id=o.order_id
group by Year,month,monthname
) as dt1;



-- 7. Month-over-Month (MoM) Growth Velocity

## using window function

-- select *,ifnull(round(((total_revenue-lag(total_revenue) over(order by month))/lag(total_revenue) over())*100,2),0) as 'MoM%' 
-- from(
-- select month,monthname,sum(payment_value) as total_revenue
-- from 
-- (select order_id,month(order_purchase_timestamp) as month, monthname(order_purchase_timestamp) as monthname from orders) as o 
-- inner join order_payments as op on op.order_id=o.order_id
-- group by month,monthname
-- ) as dt1;

## using CTE

with cte1 as
(select order_id,year(order_purchase_timestamp) as Year,month(order_purchase_timestamp) as month,monthname(order_purchase_timestamp) as Month_Name
from orders),

cte2 as 
(select Year,month,Month_Name,sum(payment_value) as Revenue
from cte1 as c1 inner join order_payments as op on c1.order_id=op.order_id
group by Year,month,month_name),

cte3 as
(select cte2.Year,cte2.month as 'Month',cte2.month_name as 'Month Name' ,cte2.Revenue,ifnull(round(((Revenue-lag(Revenue) over(order by Year,month))/lag(Revenue) over())*100,2),0) as 'MoM%'
from cte2)
select * from cte3;

-- ==========================================================================

-- ==========================================================================
-- MODULE 2: Supply Chain, Logistics, & Partner SLAs
-- ==========================================================================

-- 8. Delivery SLA (Service Level Agreement) Matrix
with cte1 as
(select order_id,
case 
		when date(order_delivered_cust_date) > date(order_est_delivery_date) then "Late (SLA breach)"
		when date(order_delivered_cust_date) <= date(order_est_delivery_date) then "Early / Ontime"
		else "Not Delivered / Unresolved status"
		end as sla_performance_status,
datediff(date(order_delivered_cust_date),date(order_est_delivery_date)) as delivery_days_deviation
from orders),
cte2 as 
( select sla_performance_status,count(*) as Total_Orders, 
avg(coalesce(delivery_days_deviation,0)) as Avg_Delivery_Deviation
from cte1
group by cte1.sla_performance_status),

cte3 as
(select sla_performance_status as 'SLA Performance Status',
cte2.Avg_Delivery_Deviation as 'Avg Delivery Deviation',
cte2.Total_Orders 'Total Orders',
(cte2.Total_Orders/sum(cte2.Total_Orders) over ())*100 as 'SLA Status%'
from cte2)

select * from cte3;


-- 9. Logistics Milestone Lag Analysis

with cte1 as 
(select distinct oi.order_id,date(order_purchase_timestamp) as order_date,date(shipping_limit_date) as est_shipping_date,date(order_delivered_carrier_date) as order_to_carrier,
date(order_est_delivery_date) as est_delivery_date,date(order_delivered_cust_date) as delivery_date
from orders as o inner join order_items as oi on o.order_id=oi.order_id),

cte2 as 
(select *, case when order_to_carrier > est_shipping_date then 'shipping_delay'
			else 'carrier_delay' end as delay_reason
from cte1
where delivery_date > est_delivery_date),

cte3 as 
(select delay_reason,case when delay_reason like 'shipping_delay' then datediff(order_to_carrier,est_shipping_date) else datediff(delivery_date,est_delivery_date) end as delay_days
from cte2),

cte4 as
(select delay_reason,round(avg(delay_days),2) as avg_days_delay , count(*) as num_delay_orders,round((count(*)/sum(count(*)) over())*100,2) as delay_orders_percentage
from cte3
group by delay_reason)

select * from cte4;




-- 10. Geographic Shipping Bottlenecks


  select seller_state,cust_state,
  count(distinct oi.order_id) as total_orders,
  COUNT(DISTINCT CASE WHEN DATE(o.order_delivered_cust_date) > DATE(oi.shipping_limit_date) THEN oi.order_id END) AS total_orders_delayed,
  round(avg(datediff(date(o.order_delivered_cust_date),date(o.order_purchase_timestamp))),2) as Avg_transit_days,
  ROUND(COUNT(DISTINCT CASE WHEN DATE(o.order_delivered_cust_date) > DATE(oi.shipping_limit_date) THEN oi.order_id END) * 100.0 / COUNT(DISTINCT oi.order_id), 2) AS sla_breach_rate_percentage
  from sellers as s 
  inner join order_items as oi on oi.seller_id=s.seller_id
  inner join orders as o on o.order_id=oi.order_id
  inner join cust as c on c.cust_id=o.cust_id
  WHERE o.order_status = 'delivered'
  GROUP BY s.seller_state, c.cust_state
  order by Avg_transit_days desc;


-- 11. Freight Pricing Elasticity

select prod_volume_cm3, weight_gm,
case when  weight_gm  < 5000 then 'light Weight'
	when weight_gm between 5000 and 12000 then 'Medium'
    when weight_gm > 12000 then 'Heavy' end as weight_buckets,
shipping_charge from
(select distinct oi.prod_id,prod_length_cm*prod_height_cm*prod_width_cm as prod_volume_cm3,prod_weight_g as weight_gm, oi.freight_value as shipping_charge 
from products as p inner join order_items oi on oi.prod_id=p.prod_id
order by shipping_charge desc) as dt;

-- 12. Logistics Impact on Customer Sentiment

select sla_performance_status,round(avg(coalesce(review,0)),2) as Avg_Reviews from
(select
case 
		WHEN DATEDIFF(o.order_delivered_cust_date, o.order_purchase_timestamp) <= 5 THEN 'Ultra Fast (0-5 Days)'
        WHEN DATEDIFF(o.order_delivered_cust_date, o.order_purchase_timestamp) BETWEEN 6 AND 10 THEN 'Fast (6-10 Days)'
        WHEN DATEDIFF(o.order_delivered_cust_date, o.order_purchase_timestamp) BETWEEN 11 AND 15 THEN 'Standard (11-15 Days)'
        WHEN DATEDIFF(o.order_delivered_cust_date, o.order_purchase_timestamp) BETWEEN 16 AND 25 THEN 'Slow (16-25 Days)'
        ELSE 'Extremely Delayed (>25 Days)'
		end as sla_performance_status,
        review_score as review
from orders as o inner join order_reviews as odr on odr.order_id=o.order_id) as dt
group by sla_performance_status
order by Avg_Reviews desc;



-- 13. Regional Order Cancellation Trends

SELECT 
    c.cust_state,
    COUNT(*) AS total_placed_orders,
    SUM(CASE WHEN o.order_status = 'canceled' THEN 1 ELSE 0 END) AS total_canceled_orders,
    ROUND(SUM(CASE WHEN o.order_status = 'canceled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS cancellation_rate_percentage
FROM orders o
INNER JOIN cust c ON o.cust_id = c.cust_id
GROUP BY c.cust_state
HAVING total_placed_orders >= 500
ORDER BY cancellation_rate_percentage DESC;



-- 14. Merchant Fulfillment Reliability

select s.seller_id,s.seller_state,
		count(oi.order_item_id) total_shipped_items,
		SUM(CASE WHEN o.order_delivered_carrier_date > oi.shipping_limit_date THEN 1 ELSE 0 END) AS total_shipping_delayed_orders,
        ROUND(SUM(CASE WHEN o.order_delivered_carrier_date > oi.shipping_limit_date THEN 1 ELSE 0 END) * 100.0 / COUNT(oi.order_item_id), 2) AS merchant_sla_breach_rate
FROM orders o
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN sellers s ON oi.seller_id = s.seller_id
group by s.seller_id,s.seller_state
having merchant_sla_breach_rate>20 and total_shipping_delayed_orders >=5
order by merchant_sla_breach_rate desc;

-- ==========================================================================

-- ==========================================================================
-- MODULE 3: Product Intelligence & Customer Insights
-- ==========================================================================

-- 15. Category Performance Matrix (Volume vs. GMV)

select distinct prod_category_name as category,prod_cat_name_english as e_category,
	COUNT(oi.order_item_id) AS items_sold,
	sum(oi.price + oi.freight_value) as Total_cust_spend,
	round(sum(oi.price + oi.freight_value)*100/(sum(sum(oi.price + oi.freight_value)) over()),2) as category_share_percentage
from products as p inner join prod_cat_translation as pct on p.prod_category_name=pct.prod_cat_name
inner join order_items as oi on oi.prod_id=p.prod_id
group by category,e_category
order by category_share_percentage desc
limit 10;


-- 16. Product Listing Optimization (Photo Count Impact)

with cte1 as
(select oi.prod_id,avg(r.review_score) as avg_product_score
from order_items as oi 
inner join order_reviews as r on r.order_id=oi.order_id
group by prod_id),

cte2 AS (
    SELECT prod_id, COUNT(order_item_id) AS total_units_sold
    FROM order_items
    GROUP BY prod_id
)
select ifnull(p.prod_photos_qty,0) as no_of_photos,
		COUNT(DISTINCT p.prod_id) AS distinct_products_in_tier,
		IFNULL(SUM(cte2.total_units_sold), 0) AS total_items_sold,
		ROUND(AVG(cte1.avg_product_score), 2) AS average_review_score
from products as p
LEFT JOIN cte2 ON p.prod_id = cte2.prod_id
LEFT JOIN cte1 ON p.prod_id = cte1.prod_id
GROUP BY no_of_photos
ORDER BY no_of_photos ASC;

-- 17. Quality Control by Category (Review Sentiment)

select p.prod_category_name,pt.prod_cat_name_english,
COUNT(DISTINCT oi.order_id) AS total_orders,
round(avg(r.review_score),2) as avg_review_Score
from products as p
inner join prod_cat_translation as pt on p.prod_category_name = pt.prod_cat_name
inner join order_items as oi on oi.prod_id = p.prod_id
inner join order_reviews as r on r.order_id = oi.order_id
group by p.prod_category_name,pt.prod_cat_name_english
order by avg_review_Score desc;

-- 18. Category-Level Cancellation Rates
select p.prod_category_name,pt.prod_cat_name_english,
	count(oi.order_id) as total_orders,
	sum( case when order_status = 'canceled' then 1 else 0 end) as canceled_orders,
    round(sum( case when order_status = 'canceled' then 1 else 0 end)*100/count(oi.order_id),2) as canceled_orders_share,
    sum(case when order_status = 'unavailable' then 1 else 0 end) as unavailable_orders
from products as p 
inner join prod_cat_translation as pt on p.prod_category_name = pt.prod_cat_name
inner join order_items as oi on oi.prod_id = p.prod_id
inner join orders as o on o.order_id = oi.order_id
group by p.prod_category_name,pt.prod_cat_name_english
HAVING total_orders >= 10
order by canceled_orders_share desc
;

-- 19. Customer Retention & Repeat Purchase Behavior
WITH cte1 AS (
    SELECT o.cust_id, SUM(op.payment_value) AS order_spend
    FROM orders o
    INNER JOIN order_payments op ON o.order_id = op.order_id
    GROUP BY o.cust_id
)
select 
	c.cust_unique_id as customer_id,
	count(distinct o.order_id) as orders_count,
    sum(cte1.order_spend) as total_spent,
    round(avg(r.review_score),1) as avg_order_review_score
from cust as c
inner join orders as o on o.cust_id=c.cust_id
inner join cte1 on o.cust_id=cte1.cust_id
inner join order_reviews as r on o.order_id=r.order_id
group by customer_id
having orders_count>1
order by orders_count desc,total_spent desc;


-- ==========================================================================

-- ==========================================================================
-- MODULE 4: Customer Segmentation & Seller Economics
-- ==========================================================================

-- 20. RFM (Recency, Frequency, Monetary) Customer Segmentation
-- Objective: Ranking customers based on when they last bought (Recency), how 
-- often they buy (Frequency), and how much they spend (Monetary) to identify 
-- the platform's most valuable users.

with cte1 as
(select o.order_id,sum(op.payment_value) as order_value
from orders as o
inner join order_payments as op on op.order_id=o.order_id
group by order_id)

select 
	c.cust_unique_id,
    max(date(o.order_purchase_timestamp)) as most_recent_order,
    min(date(o.order_purchase_timestamp)) as first_order,
	datediff((select max(date(order_purchase_timestamp)) from orders), max(date(o.order_purchase_timestamp))) as recency_days,
	count(distinct o.order_id) as total_orders,
    case when datediff(max(date(o.order_purchase_timestamp)),min(date(o.order_purchase_timestamp))) = 0 then null
    else round(count(distinct o.order_id)/datediff(max(date(o.order_purchase_timestamp)),min(date(o.order_purchase_timestamp))),2) end as order_Frequency,
    
    case when datediff(max(date(o.order_purchase_timestamp)),min(date(o.order_purchase_timestamp))) = 0 then 'Single-Day Buyer'
    else 'Returning Buyer' end as buyer_cohort, 
    datediff(max(date(o.order_purchase_timestamp)),min(date(o.order_purchase_timestamp))) as 'user_since(days)',
    sum(cte1.order_value) as total_spent
from cust as c 
inner join orders as o on o.cust_id=c.cust_id
inner join cte1 on cte1.order_id=o.order_id	
group by c.cust_unique_id
order by order_Frequency desc;


-- 21. Seller Revenue Concentration (The Pareto Principle / 80-20 Rule)
-- Objective: Calculating the cumulative revenue share of top sellers to determine 
-- if a small percentage of merchants (e.g., 20%) generate the majority of platform GMV.
with cte1 as (
select oi.seller_id as seller, sum(oi.price+oi.freight_value) as total_revenue
from order_items as oi
group by oi.seller_id)

select 
	seller,
	total_revenue,
    total_revenue*100/sum(total_revenue) over() as revenue_share,
    sum(total_revenue) over(order by total_revenue desc) as cumulative_revenue,
    sum(total_revenue) over(order by total_revenue desc)*100/sum(total_revenue) over() as cumulative_revenue_share,
    round(row_number() over (order by total_revenue desc)*100/count(seller) over (),2) as cumulative_seller_share
from cte1;


-- 22. Freight Burden Ratio by State
-- Objective: Calculating shipping costs as a percentage of total order value 
-- for each customer state to identify regions where shipping costs are pricing out customers.

with cte1 as
(select sum(payment_value) as total_revenue from order_payments),
cte2 as 
(select order_id,sum(freight_value) as shipping_charges, sum(freight_value + price) as total_charges from order_items group by order_id)

select 
	c.cust_state as customer_state,
    round(sum(cte2.shipping_charges)*100/sum(cte2.total_charges),2) as Freight_Burden_Ratio_State,
	round(sum(cte2.shipping_charges)*100/max(cte1.total_revenue),2) as Freight_Burden_Ratio_total_revenue
from cte1,cust as c
inner join orders as o on o.cust_id=c.cust_id
inner join cte2 on cte2.order_id=o.order_id
group by c.cust_state
order by Freight_Burden_Ratio_State desc;

-- 23. Review Response SLA
-- Objective: Analyze the time gap between when a review is sent to the customer 
-- and when they respond, correlating faster response times with positive/negative sentiments.

select 
	case when datediff(date(review_answer_timestamp),date(review_creation_date)) = 0 then '0 Days (Same Day)'
		 when datediff(date(review_answer_timestamp),date(review_creation_date)) between 1 and 2 then '1-2 Days'
		 when datediff(date(review_answer_timestamp),date(review_creation_date)) between 3 and 5 then '3-5 Days'
         else '6+ Days (Late Response)' end as survey_response_time,
	round(avg(review_score),2) avg_review_score,
    count(review_id) as total_survey_answered
from order_reviews
group by survey_response_time
order by survey_response_time;


-- ==========================================================================

-- ==========================================================================
-- MODULE 5: Analysis
-- ==========================================================================

-- ◯ XYZ Demand Volatility Analysis (Module 2)
	-- Objective: Evaluating inventory predictability. In supply chain management, products are classified based on demand stability:
		-- X Class: Stable, predictable demand (Low variation).
        -- Y Class: Variable demand with seasonal fluctuations.
        -- Z Class: Highly volatile, sporadic, and unpredictable demand.

with cte1 as
( select
	p.prod_category_name as prod_cat,pt.prod_cat_name as Prod_cat_e,
    date_format(order_purchase_timestamp,'%Y-%m') as sales_month,
    count(oi.order_item_id) as sold_units
from products as p
inner join prod_cat_translation as pt on pt.prod_cat_name=p.prod_category_name
inner join order_items as oi on oi.prod_id=p.prod_id
inner join orders as o on oi.order_id=o.order_id
group by prod_cat,prod_cat_e,sales_month
),
cte2 as
(
select 
	prod_cat,prod_cat_e,
	round(avg(sold_units),2) as avg_monthly_demand,
	round(stddev(sold_units),2) as std_monthly_demand,
    round(stddev(sold_units)/avg(sold_units),2) as cv
from cte1
group by prod_cat,prod_cat_e
)

select 
	prod_cat,prod_cat_e,
	avg_monthly_demand,
    std_monthly_demand,
    cv,
    case when cv <=0.2 then 'X (Stable/Predictable)'
		 when cv between 0.21 and 0.5 then 'Y (Variable/Seasonal)'
         else 'Z (Highly Volatile/unpredictable)'
         end as xyz_demand_class
from cte2
where prod_cat is not null and prod_cat_e is not null
order by cv asc;


-- ◯ ABC Revenue Classification (Module 2)
-- 		Objective: Applying the Pareto principle across all product categories to sort inventory by financial value:
			-- Group A: Top product lines contributing to 80% of total revenue (High Priority).
            -- Group B: Mid-tier product lines contributing to the next 15% of revenue.
            -- Group C: Long-tail product lines contributing to the final 5% of revenue.

with cte1 as
(
select
	p.prod_category_name as prod_cat,pt.prod_cat_name as Prod_cat_e,
    sum(oi.price + oi.freight_value) as revenue
from products as p
inner join prod_cat_translation as pt on pt.prod_cat_name=p.prod_category_name
inner join order_items as oi on oi.prod_id=p.prod_id
where p.prod_category_name is not null and pt.prod_cat_name is not null
group by prod_cat,prod_cat_e
),

cte2 as 
(
select 
	prod_cat,prod_cat_e,
    revenue,
    sum(revenue) over (order by revenue desc)*100 / sum(revenue) over() as cumulative_revenue_share
from cte1)

select 
	prod_cat,prod_cat_e,
    revenue,
    cumulative_revenue_share,
    case when cumulative_revenue_share <=80 then 'Group A (Core Value - Top 80%)'
		 when cumulative_revenue_share  between 81 and 95 then 'Group B (Mid-Tier - Next 15%)'
         else 'Group C (Long-Tail - Bottom 5%)'
		 end as ABC_revenue_class
from cte2
order by cumulative_revenue_share;


-- Product Affinity / Market Basket Analysis
	-- Objective: Identifying pairs of product categories most frequently bundled together inside the same order ID. 
	-- This uses a high-performance self-join structural map to isolate dual purchases while systematically removing duplicates using an alphabetical filter

select 
	p1.prod_category_name as primary_product_category,
    pt1.prod_cat_name_english as primary_product_category_transl,
    p2.prod_category_name as secondary_product_category,
    pt2.prod_cat_name_english as secondary_product_category_transl,
    count(distinct oi1.order_id) as co_purchase_count
from order_items as oi1
inner join order_items as oi2 on oi1.order_id=oi2.order_id
inner join products as p1 on oi1.prod_id=p1.prod_id
inner join prod_cat_translation as pt1 on pt1.prod_cat_name=p1.prod_category_name
inner join products as p2 on oi2.prod_id=p2.prod_id
inner join prod_cat_translation as pt2 on pt2.prod_cat_name=p2.prod_category_name
where p1.prod_category_name < p2.prod_category_name and
	  p1.prod_category_name is not null and
      p2.prod_category_name is not null
group by primary_product_category,secondary_product_category
having co_purchase_count>1
order by co_purchase_count desc;



-- STORED PROCEDURE

-- Merchant Audit
DELIMITER //
create procedure Merchant_Audit(in seller varchar(50))
begin
select 
	s.seller_id,
	s.seller_city,
    s.seller_state,
    count(distinct oi.order_id) as total_orders,
    sum(oi.price + oi.freight_value) as total_revenue,
    round(avg(r.review_score),2) as average_review_score
from sellers as s
inner join order_items as oi on s.seller_id = oi.seller_id
left join order_reviews as r on oi.order_id = r.order_id
where s.seller_id = seller
group by s.seller_id;

end //
DELIMITER ;

call Merchant_Audit('4869f7a5dfa277a7dca6462dcf3b52b2');


-- State Audit

DELIMITER //
create procedure State_Sudit(in state varchar(20))
begin
select
	s.seller_state,
    count(distinct s.seller_id) as total_sellers,
    count(distinct oi.order_id) as total_orders_placed,
    sum(oi.price+oi.freight_value) as Total_revenue,
    round(avg(oi.freight_value),2) as avg_shipping_charges
from sellers as s
inner join order_items as oi on s.seller_id = oi.seller_id
where s.seller_state = state
group by s.seller_state ;
end //
DELIMITER ;

call State_Sudit('SP');

    
 
