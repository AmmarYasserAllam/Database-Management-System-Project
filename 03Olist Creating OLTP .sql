                               /* Exploratory and Cleaning data */

/*********************************** orders table ***********************************************/
/***********************************************************************************************/

---Cleaning order_id column and make all values without ""

UPDATE olist_orders_dataset
SET order_id = REPLACE(TRIM('"'FROM order_id ), '"','');

--------------------------------------
---Checking for order_id duplicates in Orders table

Select *
From 
     (Select 
	     order_id ,count(order_id) as [orders number]
	  From 
	     [dbo].[olist_orders_dataset] 
	  Group by
	     order_id ) as temp
Where 
      [orders number] > 1

--------------------------------------
---Checking for customer_id duplicates in Orders table

Select * 
From 
  (
    Select 
      customer_id, count(customer_id) as [customers number] 
    from 
      [dbo].[olist_orders_dataset] 
    group by 
      customer_id ) as temp 
Where 
  [customers number] > 1

--------------------------------------
---Cleaning the orders table

--Select * 
--from olist_orders_dataset
Delete from 
  [dbo].[olist_orders_dataset] 
Where 
  order_status = 'delivered' 
  and order_delivered_customer_date is null

--------------------------------------
---Cleaning the orders table

--Select * 
--from olist_orders_dataset
Delete from 
  [dbo].[olist_orders_dataset]
Where 
  order_status = 'shipped' 
  and order_delivered_carrier_date is null
  
/*********************************** order_status table *****************************************/
/***********************************************************************************************/

---Creating New_table [order_status_types] 

Create table order_status_types(
  id int not null, 
  status_type varchar(50) null Constraint PK_status_types primary key clustered(id asc)
)

--------------------------------------
---Inserting values into [order_status_types] table

Insert into [order_status_types] (id, status_type) 
Values 
  (1, 'created'), 
  (2, 'shipped'), 
  (3, 'canceled'), 
  (4, 'approved'), 
  (5, 'processing'),
  (6,'unavailable'),
  (7,'delivered'),
  (8,'invoiced')
   
--Select *
--from [order_status_types]

--------------------------------------
---Renaming (order_status)column to (order_status_id)column in [olist_orders_dataset]

--Alter Table 
--dbo.[olist_orders_dataset] RENAME Column (order_status) to (order_status_id)

--------------------------------------
---Cleaning the (order_status_id) column in [olist_orders_dataset] table

Update [olist_orders_dataset]
Set order_status_id = Case 
							When order_status_id = 'created'     then 1
							When order_status_id = 'shipped'     then 2
							When order_status_id = 'canceled'    then 3
							When order_status_id = 'approved'    then 4
							When order_status_id = 'processing'  then 5
							When order_status_id = 'unavailable' then 6
							When order_status_id = 'delivered'   then 7
							When order_status_id = 'invoiced'    then 8
							When order_status_id = 'not_defined' then 9
					  End

 Select *
 From 
  [olist_orders_dataset]
 Where 
   order_status_id not in (1,2,3,4,5,6,7,8,9)


/*********************************** order_Items table ******************************************/
/***********************************************************************************************/

---Cleaning order_id column and make all values without ""

UPDATE items_dataset
SET order_id = REPLACE(TRIM('"'FROM order_id ), '"','');

---Checking, is every order has only one distinct product ?

Select 
  order_id,COUNT(distinct product_id) 
From 
  [olist_order_items_dataset] 
Group by 
  order_id 
Having 
  COUNT(distinct product_id) > 1

--------------------------------------
---    Summarize the [olist_order_items] table and add (product_counter) column 
---    and insert the returned result into New_Table [items_dataset]

Select 
   order_id,seller_id,shipping_limit_date,price,freight_value,
   product_id,COUNT(product_id) as [product_counter]
into 
   [items_dataset]

From 
   [olist_order_items_dataset]

Group by 
   order_id,seller_id,shipping_limit_date,price,freight_value,product_id
Order by
   order_id asc
--------------------------------------
---Delete [olist_order_items_dataset] table from database

Drop Table [olist_order_items_dataset]

--------------------------------------
---Checking for (order_id and product_id) duplicates in items_dataset table
Select * 
From (
      Select 
	     *,ROW_NUMBER() Over(Partition by order_id,product_id Order by order_id,product_id) as RN
      From
	     [items_dataset]) as te
		 
  Where
	  RN > 1
/*********************************** order_Reviews table ****************************************/
/***********************************************************************************************/

---Cleaning order_id column and make all values without ""

UPDATE olist_order_reviews_dataset
SET order_id = REPLACE(TRIM('"' FROM order_id ), '"','')

-----------------------------------------------

---Delete duplicated reviews from order_reviews table

With deleted_duplicates as 
   (
  Select * 
  From (
      Select 
	     *,ROW_NUMBER() Over(Partition by review_id Order by review_id) as RN
      From
	     [olist_order_reviews_dataset] ) as temp 
  Where
	  RN > 1
    )
      Delete From
          deleted_duplicates
      Where 
          RN >1

--------------------------------------
--- Cleaning review_id from null

With deleted_review_id_null as
(
  Select top 90 * 
  From (
      Select 
	     *,ROW_NUMBER() Over(Partition by review_id Order by review_id) as RN
      From
	     [olist_order_reviews_dataset] ) as temp 
  Where
	  RN = 1
	order by review_id asc)

Delete From deleted_review_id_null
--------------------------------------
--- Cleaning order_id from null

With deleted_order_id_null as 
(
  Select top 1330 * 
  From (
      Select 
	     *,ROW_NUMBER() Over(Partition by review_id Order by review_id) as RN
      From
	     [olist_order_reviews_dataset] ) as temp 
  Where
	  RN = 1
	order by order_id asc )

Delete From deleted_order_id_null

--------------------------------------
--- Cleaning (review_creation_date) from fake date

With Date_cleaning as
(
SELECT 
       [review_creation_date]
FROM 
       [Olist].[dbo].[olist_order_reviews_dataset]
Where 
     	[review_creation_date] = ''
	 or [review_creation_date] like '%[x]%'
	 or [review_creation_date] like '[a-z]%' 
	 or [review_creation_date] like '[" "]%'
	 or [review_creation_date] like '["0"]%'
	 or [review_creation_date] like '%[^0]'
	    )

Delete Date_cleaning

--------------------------------------
--- Cleaning (review_answer_timestamp) from fake date

With Date_cleaning as 
(
SELECT 
     [review_answer_timestamp]
FROM 
     [Olist].[dbo].[olist_order_reviews_dataset]
Where 
       [review_answer_timestamp] = ''
	or [review_answer_timestamp] like '[a-z]%'
    or [review_answer_timestamp] like '[" "]%'
	or[review_answer_timestamp] like '[","]%' 
	or [review_answer_timestamp] like '%[^0123456789]'
	 )

Delete Date_cleaning


	 
/*********************************** order_Payments table ***************************************/
/***********************************************************************************************/

---Cleaning order_id column and make all values without ""

UPDATE olist_order_payments_dataset
SET order_id = REPLACE(TRIM('"' FROM order_id ), '"','')

-----------------------------------------------
---Creating New_table [payment_types] 

Create table payment_types(
  id int not null, 
  payment_type varchar(50) null Constraint PK_payment_types primary key clustered(id asc)
)

--------------------------------------
---Inserting values into [payment_types] table

Insert into [payment_types] (id, payment_type) 
Values 
  (1, 'credit_card'), 
  (2, 'voucher'), 
  (3, 'boleto'), 
  (4, 'debt_card'), 
  (5, 'not_defined') 
   
--Select *
--from [payment_types]

--------------------------------------
---Renaming (payment_type)column to (payment_type_id)column in [olist_order_payments_dataset]

EXEC sp_rename 
    @objname = '[olist_order_payments_dataset].payment_type',
    @newname = 'payment_type_id',
    @objtype = 'COLUMN';

--------------------------------------
---Cleaning the (payment_type_id)column in [olist_order_payments_dataset] table

Update [olist_order_payments_dataset]
Set payment_type_id = Case 
							When payment_type_id = 'credit_card' then 1
							When payment_type_id = 'voucher'     then 2
							When payment_type_id = 'boleto'      then 3
							When payment_type_id = 'debit_card'  then 4
							When payment_type_id = 'not_defined' then 5
					  End

 Select *
 From 
   [olist_order_payments_dataset]
 Where 
   payment_type_id not in (1,2,3,4,5)


/*************************** Customer , Seller and Geolocation Tables ***************************/
/***********************************************************************************************/

---Checking for customer_id duplicates in Customers table

Select 
  customer_id, 
  COUNT(customer_id) as [Customers Number] 
From 
  [dbo].[olist_customers_dataset] 
Group by 
  customer_id 
Having 
  COUNT(customer_id) > 1

--------------------------------------
---Inserting the Customer's table (Zip_Codes, Cities and States) into the [geolocation table]

insert into [dbo].[olist_geolocation_dataset] (
									           geolocation_zip_code_prefix, 
									           geolocation_city, 
								               geolocation_state
									          ) 
Select 
  distinct customer_zip_code_prefix, 
		   customer_city, 
           customer_state 
From 
  [dbo].[olist_customers_dataset] 
Where 
  customer_zip_code_prefix not in (
									  Select 
										   geolocation_zip_code_prefix 
								      From 
										   [dbo].[olist_geolocation_dataset]
								  )
--------------------------------------
---Inserting the Seller's table (Zip_Codes, Cities and States) into the [geolocation table]

insert into [dbo].[olist_geolocation_dataset] (
									           geolocation_zip_code_prefix, 
									           geolocation_city, 
								               geolocation_state
									          ) 
Select 
  distinct seller_zip_code_prefix, 
		   seller_city, 
           seller_state 
From 
  [dbo].[olist_sellers_dataset] 
Where 
  seller_zip_code_prefix not in (
									  Select 
										   geolocation_zip_code_prefix 
								      From 
										   [dbo].[olist_geolocation_dataset]
								  )
--------------------------------------
----Update the geolocation's Cities by the Customer's Cities which they have the same zip_code 

Update 
  [dbo].[olist_geolocation_dataset] 
Set 
  geolocation_city = (
    Select 
      distinct customer_city 
    From 
      [dbo].[olist_customers_dataset] as cus 
    Where 
	  cus.customer_zip_code_prefix = [olist_geolocation_dataset].geolocation_zip_code_prefix 
	  and
      cus.customer_city Not in (
                                 Select 
                                   distinct geolocation_city
                                 From 
                                   [dbo].[olist_geolocation_dataset] 
                                 Where 
                                   geolocation_zip_code_prefix in (
                                                           Select 
															 customer_zip_code_prefix 
														   From 
															 [dbo].[olist_customers_dataset]
       )
    )
 )

Where Exists(
	Select 
      distinct customer_city 
    From 
      [dbo].[olist_customers_dataset] as cus 
    Where 
	  cus.customer_zip_code_prefix = [olist_geolocation_dataset].geolocation_zip_code_prefix 
	  and
      cus.customer_city Not in (
                                 Select 
                                   distinct geolocation_city
                                 From 
                                   [dbo].[olist_geolocation_dataset] 
                                 Where 
                                   geolocation_zip_code_prefix in (
                                                               Select 
																 customer_zip_code_prefix 
															   From 
															     [dbo].[olist_customers_dataset]
     )
   )
 )
--------------------------------------
---Delete duplicated locations from geolocation table 

--SELECT *
--FROM olist_geolocation_dataset

With deleted_duplicates as
(
Select * 
From (Select *,ROW_NUMBER()over(partition by geolocation_zip_code_prefix order by geolocation_zip_code_prefix asc) as RN
      From [olist_geolocation_dataset] )as temp
)
Delete From deleted_duplicates
where RN > 1 
-------------------------------------------
---Delete city column and state column from customer table

Alter Table 
  [olist_customers_dataset] 
drop Column
  customer_city, 
  customer_state

-------------------------------------------
---Delete city column and state column from seller table

Alter Table 
  [olist_sellers_dataset] 
drop Column
  seller_city, 
  seller_state

/************************************ Matching Relationship *************************************/
/***********************************************************************************************/

---- Matching between (product_category_name)in [olist_products_dataset] 
----------------- and (product_category_name) in [olist_products_translation]
Insert into 
    [olist_products_translation] (product_category_name)
SELECT  
    p.product_category_name
FROM
    [olist_products_dataset] as p
WHERE 
    p.[product_category_name] NOT IN ( SELECT 
										    product_category_name
									     FROM 
										    [olist_products_translation]  )
and p.[product_category_name] is not null

-------------------------------------------
---- Matching between (product_id)in [olist_products_dataset] 
----------------- and (product_id) in [items_dataset]

UPDATE items_dataset
SET product_id = REPLACE(TRIM('"'FROM product_id ), '"','');

-------------------------------------------
---Checking are there any product_id values in in items table that not exist in products table 

SELECT  
    p.product_id
FROM
    [items_dataset] as p
WHERE 
    p.product_id NOT IN ( SELECT 
								product_id
							  FROM 
							    [olist_products_dataset]  )

---- Matching between (seller_zip_code_prefix)in [olist_sellers_dataset]
----------------- and (geolocation_zip_code_prefix) in [olist_geolocation_dataset]

Insert into [olist_geolocation_dataset] (geolocation_zip_code_prefix)
SELECT  seller_zip_code_prefix
FROM
    [olist_sellers_dataset] 
WHERE 
    seller_zip_code_prefix NOT IN ( SELECT 
							           geolocation_zip_code_prefix
							        FROM 
							          [olist_geolocation_dataset]  )

---- Matching between (customer_zip_code_prefix)in [olist_customers_dataset]
----------------- and (geolocation_zip_code_prefix) in [olist_geolocation_dataset]

Insert into [olist_geolocation_dataset] (geolocation_zip_code_prefix)
SELECT distinct customer_zip_code_prefix
FROM
    [olist_customers_dataset] 
WHERE 
    customer_zip_code_prefix NOT IN ( SELECT 
							             geolocation_zip_code_prefix
							          FROM 
							            [olist_geolocation_dataset]  )

---- Matching between (order_id)in [olist_orders_dataset] 
----------------- and (order_id) in [olist_order_reviews_dataset]

---Cleaning order_id in reviews table from fake ids
With deleted_fake_order_id as (
  SELECT 
    order_id 
  FROM 
    [olist_order_reviews_dataset] 
  WHERE 
    order_id NOT IN (
                     SELECT  order_id 
                     FROM  olist_orders_dataset  )
 ) 
Delete From 
  deleted_fake_order_id


-------------------------------------------
---Checking are there any null values in review_id column to make it primary key
SELECT 
     [review_id]   
  FROM 
     [Olist].[dbo].[olist_order_reviews_dataset]
  order by
     review_id asc
-------------------------------------------------------------------------





