1 – Use "PostgreSQL 13.4, compiled by Visual C++ build 1914, 64-bit" as data base system and use "Dbeaver Versión22.0.1.202203181646" as IDE.

2 – Export 2 files from the xlsx file “Shopee_FBA_case_v2.xlsx” the first one is “01 - Input_products.csv” with the data of products sheet(Products), and the last one is “02 - Input_orders.csv” with the data of orders sheet(Orders).
3 – You need to create a new database and schema with the next code in postgres:

	-- DROP DATABASE shopee;
	CREATE DATABASE shopee
		WITH 
		OWNER = postgres
		ENCODING = 'UTF8'
		LC_COLLATE = 'Spanish_Colombia.1252'
		LC_CTYPE = 'Spanish_Colombia.1252'
		TABLESPACE = pg_default
		CONNECTION LIMIT = -1;
	CREATE SCHEMA shopee AUTHORIZATION postgres;

4 – Open and run the file “03 -Solution_test_shopee_DDL_tables.sql”, to create the staging (RAW) tables to upload the information of the CSV files of the 2nd step.
5 - Import the data from CSV files: “01 - Input_products.csv” into "shopee.tmp_products" table, “02 - Input_orders.csv” into "shopee.tmp_orders" table
5 - Open and run the file “04 -Solution_test_shopee.sql”, in there you’ll find all the code for the processing of the data and the creation of final outputs for the dashboard.
6 – You can see the outputs for the task in the next files: “05 - output_products_table.txt”, “06 - output_sellers_table.txt” and “07 - output_orders_table.txt”
7 – You have some screenshots for the dashboard that I made: “08 - screen1_no_filter.PNG”, “09 - screen2_canceled_orders.PNG” and “10 - screen3_ok_orders.PNG”
8 – Finally you have the Power BI dashboard. “11 - shopee_dashboard.pbix”

