-->I Used "PostgreSQL 13.4, compiled by Visual C++ build 1914, 64-bit" and "Dbeaver Versión22.0.1.202203181646"

--> RAW Tables for: Products & orders
/*Description: Here I created 2 tables with the same structure of the files, this tables has fields as text type, for integrity of the data.
 * After that I imported the data  Using "Dbeaver" as IDE (you can use any other client SQL tool or ETL tool to import the data) 
 * from 2 CSV files exported from the XLSX File "Shopee_FBA_case_v2.xlsx",
 * the first one was "01 - Input_products.csv" and the other one was "02 - Input_orders.csv" (this files are attached on the solution files)
 */

drop table if exists shopee.tmp_products;		--> First, I created this staging table to import the date of sheet "products" from file -> Shopee_FBA_case_v2.xlsx (RAW Data)
create table shopee.tmp_products(				
	seller_id text,
	product_id text,
	product_price text
);

drop table if exists shopee.tmp_orders; 		--> I created this staging table to import the date of sheet "orders" from file -> Shopee_FBA_case_v2.xlsx (RAW Data)
create table shopee.tmp_orders(
	order_id text,
	order_date text,
	order_status text,
	delivery_date text,
	seller_id text,
	buyer_id text,
	product_quantities text
);

--> End RAW Tables for: Products & orders