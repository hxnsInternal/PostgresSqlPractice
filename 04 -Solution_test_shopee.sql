
--> Creation of table "products"
drop table if exists shopee.products;		--> transformation to create the table "products"
create table shopee.products as
select distinct p.seller_id::varchar(6)
	,p.product_id::varchar(10)
	,replace(p.product_price,',','.')::float product_price
from shopee.tmp_products p;


/*Output for the first 10 rows, just for visualize the output
 
seller_id|product_id|product_price|
---------+----------+-------------+
U00344   |P00344_004|         5.06|
U00416   |P00416_002|        38.55|
U00105   |P00105_002|        18.74|
U00164   |P00164_011|         5.02|
U00585   |P00585_002|         5.02|
U00408   |P00408_005|         6.66|
U00489   |P00489_011|        17.41|
U00512   |P00512_001|         8.13|
U00009   |P00009_002|        84.63|
U00082   |P00082_011|         5.64|  
 
 * */

--> Task 1
drop table if exists shopee.sellers;		--> Creating the "sellers" table from products table
create table shopee.sellers as
select pr.seller_id 
	,count(pr.product_id) product_count
	,avg(pr.product_price)::numeric(20,3) avg_product_price	
	,sum(pr.product_price) product_price	--> I added this column just for before calculate the avg.
from shopee.products pr
	group by 1;


/* Output for the 10 first rows, just for visualize the output
 
seller_id|product_count|avg_product_price|product_price     |
---------+-------------+-----------------+------------------+
U00501   |            6|           46.655|            279.93|
U00527   |            2|           54.530|            109.06|
U00149   |            2|           43.525|             87.05|
U00500   |            8|           10.260|             82.08|
U00164   |           23|           15.514| 356.8299999999999|
U00009   |            4|           58.435|            233.74|
U00030   |            2|           43.770|             87.54|
U00579   |            4|           17.913|             71.65|
U00196   |            4|            5.490|             21.96|
U00077   |            4|           15.320|61.279999999999994| 
 
 
  */

--> Task 2

drop table if exists shopee.orders;
create table shopee.orders as
with raw_orders as(		--> getting the raw data from orders
	select o.order_id::varchar(6),
		to_date(o.order_date,'DD/MM/YYYY') order_date,
		o.order_status::varchar(8),
		to_Date(o.delivery_date,'DD/MM/YYYY') delivery_date,
		o.seller_id::varchar(6),
		o.buyer_id::varchar(6),
		o.product_quantities::json
	from shopee.tmp_orders o
),
list_orders as(
		select 	--> extracting information from json's product_quantities field, getting the "product_id" and quantity for each order_id
			o.order_id 
			,(row_to_json(json_each_text(o.product_quantities)) ->> 'key')::varchar(10) product_id 
			,(row_to_json(json_each_text(o.product_quantities)) ->> 'value')::integer quantity
		from raw_orders o			
),
list_orders_price as(	--> getting price for each product Id from the table products, some products IDs from "list_orders" aren't in the "shopee.products" table
		select distinct o.product_id
			,p.product_price 
		from list_orders o
			join shopee.products p on p.product_id = o.product_id
),
pre_insert_ord as(	--> calculating the total values, avgs, etc, for each order_id, I used windows functions (analytics function) to get this information.
	select r.*
		,lo.product_id 
		,lo.quantity 
		,lp.product_price
		,sum(lo.quantity * lp.product_price) over (partition by r.buyer_id) total_price		--> getting the total_price for buyer_id 
		,sum(lo.quantity) over (partition by r.order_id) product_count
		,avg(lp.product_price) over (partition by r.order_id) avg_product_price
		,(sum(lo.quantity * lp.product_price) over (partition by r.order_id) / count(r.order_id) over (partition by r.order_id))::numeric(20,3) avg_product_total_price
		,count(r.order_id) over (partition by r.order_id) cantidad
		,sum(lo.quantity * lp.product_price) over (partition by r.order_id) total_price_order	--> getting the information for the total price for each order
		,row_number () over (partition by order_id) rk
	from raw_orders r
		join list_orders lo using(order_id)	
		left join list_orders_price lp using(product_id)	--> Here I used left join, because I detected that in some orders ("list_orders" of the CTE) some product ids aren't registered in the table "shopee.products"
	--where r.order_id in('O00011','O00002')	--> Just for validations and QA
)															
select p.order_id,
	p.order_date,
	p.order_status,
	p.delivery_date,
	p.seller_id,
	p.buyer_id,
	p.product_quantities,
	p.total_price,
	p.product_count,
	p.avg_product_price,			--> this is the avg price for each individual price product
	p.avg_product_total_price,		--> this one is the avg of (quantity * price) for each product in each order
	p.total_price_order 			--> I added this field to be use in the task #3, for calculating the avg.
from pre_insert_ord p
	where p.rk = 1
order by 1;

/* Output for the 10 first rows, just for visualize the output
 *  
order_id|order_date|order_status|delivery_date|seller_id|buyer_id|product_quantities                                                                   |total_price       |product_count|avg_product_price |avg_product_total_price|total_price_order |
--------+----------+------------+-------------+---------+--------+-------------------------------------------------------------------------------------+------------------+-------------+------------------+-----------------------+------------------+
O00001  |2020-12-08|OK          |   2020-12-20|U00614   |U00450  |{"P00614_011": 3}                                                                    |           2143.58|            3|              5.01|                 15.030|             15.03|
O00002  |2020-11-01|OK          |   2020-11-06|U00626   |U00595  |{"P00505_002": 4,¶"P00505_001": 5,¶"P00505_001": 4,¶"P00505_005": 1,¶"P00505_005": 5}|1951.7399999999998|           19|             9.234|                 31.786|            158.93|
O00003  |2020-11-28|CANCELED    |   0001-01-01|U00624   |U00146  |{"P00624_001": 2}                                                                    | 2468.560000000001|            2|              42.1|                 84.200|              84.2|
O00004  |2020-11-12|OK          |   2020-11-18|U00505   |U00578  |{"P00626_001": 4,¶"P00626_007": 3,¶"P00626_005": 4}                                  |2533.3899999999994|           11| 8.586666666666668|                 32.483|             97.45|
O00005  |2020-12-07|OK          |   2020-12-18|U00536   |U00164  |{"P00536_003": 2,¶"P00536_002": 5,¶"P00536_005": 2}                                  |           1700.07|            9|22.546666666666667|                 50.103|            150.31|
O00006  |2020-12-14|OK          |   2020-12-22|U00581   |U00242  |{"P00581_001": 1,¶"P00581_001": 4}                                                   |           1405.32|            5|              5.45|                 13.625|             27.25|
O00007  |2020-11-26|CANCELED    |   0001-01-01|U00592   |U00110  |{"P00592_001": 3}                                                                    |1792.0700000000002|            3|              9.39|                 28.170|             28.17|
O00008  |2020-12-03|OK          |   2020-12-15|U00406   |U00567  |{"P00406_007": 1,¶"P00406_005": 2}                                                   | 4291.840000000001|            3|42.855000000000004|                 45.360|             90.72|
O00009  |2020-12-05|OK          |   2020-12-17|U00603   |U00050  |{"P00603_001": 3,¶"P00603_001": 2,¶"P00603_001": 4,¶"P00603_001": 4,¶"P00603_001": 2}|           1191.26|           15|              44.9|                134.700|             673.5|
O00010  |2020-12-18|OK          |   2020-12-26|U00576   |U00540  |{"P00576_008": 4,¶"P00576_009": 1}                                                   |           2227.72|            5|             5.515|                 14.545|29.089999999999996| 
  
 */
	
--> task 3: Option A

select avg(product_price)::numeric(20,2) avg_product_price		--> The avarage price for each product is around $25.73 
from shopee.products;  

select (sum(product_price) / sum(product_count))::numeric(20,3) avg_product_price_sellers 		--> In avarage each seller move around $25.729
from shopee.sellers;

select  (sum(total_price_order) / sum(product_count))::numeric(20,2)  			--> the avg value for the total_price_order is $ 20.76
from shopee.orders o
	where o.order_status = 'OK';


/*Explanation:
 
1 - It's important to clarify that the average of an average is not a good measure for values,
    is for that reason I added some extra fields on the tables, to bring a different metrics using weighted average .

2 - The difference between each average calculation are caused by there are different measures, 
	I mean the first one is the average for the price of all products on the table “products”,
	but, on the second average calculation for sellers represent the average price for all the sold products.
	Finally, on the last one calculation we can see the average of the product price for all the orders in our table “orders”.

So basically, each calculation represents different views from different contexts. 
 
 */


--> I created this objets for my dashboard.

create or replace view shopee.vw_month_orders as
select o.order_id 
	,to_char(o.order_date,'YYYYMM') as month
	,o.order_status 
	,o.order_date 
	,o.delivery_date 
	,o.seller_id 
	,o.buyer_id 
	,o.product_count 
	,o.total_price_order 
	,case when (o.delivery_date - o.order_date) < 0 then 0 else (o.delivery_date - o.order_date) end delivery_diff
from shopee.orders o;

drop table if exists shopee.tbl_product_month;		--> getting information about each order.
create table shopee.tbl_product_month as
with order_produc as(
	select o.order_id 
		,o.order_status 
		,to_char(o.order_date,'YYYYMM') mes
		,(row_to_json(json_each_text(o.product_quantities)) ->> 'key')::varchar(10) product_id 
		,(row_to_json(json_each_text(o.product_quantities)) ->> 'value')::integer quantity
	from shopee.orders o
), 
order_product_val as(
	select o.ordeR_id
		,o.mes
		,o.order_status
		,o.product_id 
		,o.quantity
		,p.product_price  
		,o.quantity * p.product_price total_price
	from order_produc o
		join shopee.products p on p.product_id = o.product_id
)
select *
from order_product_val;




