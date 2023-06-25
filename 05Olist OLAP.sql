go
Create Database Olist_DWH
go
use Olist_DWH

/***************************************** Dim_Date table ***************************************/

CREATE TABLE Dim_Date (
    DateKey INT PRIMARY KEY,
    DateFull Date,
    Year INT,
    Quarter INT,
    Month INT,
    Day INT,
    DayOfWeek INT,
    DayName nvarchar(10),
    MonthName nvarchar(10)
);

DECLARE @StartDate DATE = '2016-01-01';
DECLARE @EndDate DATE = '2018-12-31';

WHILE @StartDate <= @EndDate
BEGIN
    INSERT INTO DimDate (
        DateKey,
        DateFull,
        Year,
        Quarter,
        Month,
        Day,
        DayOfWeek,
        DayName,
        MonthName
    )
    VALUES (
        @StartDate,
        CONVERT(VARCHAR(10), @StartDate, 120),
        YEAR(@StartDate),
        DATEPART(QUARTER, @StartDate),
        MONTH(@StartDate),
        DAY(@StartDate),
        DATEPART(WEEKDAY, @StartDate),
        DATENAME(WEEKDAY, @StartDate),
        DATENAME(MONTH, @StartDate)
    );

    SET @StartDate = DATEADD(DAY, 1, @StartDate);
END;


/***************************************** Dim_Products table ***************************************/

---Creating [Dim_Products table]

Select * 
Into Olist_DWH.dbo.Dim_products
From Olist.dbo.olist_products_dataset
Where 1=2

---Rename (product_category_name column) to (product_category_english_name column)

EXEC sp_rename 
    @objname = '[Dim_products].product_category_name',
    @newname = 'product_category_english_name',
    @objtype = 'COLUMN';

/***************************************** Dim_Customers table ***************************************/

---Creating [Dim_customers table]

Select 
	c.customer_id,
	c.customer_unique_id,
	G.geolocation_city   as customer_city,
	G.geolocation_state  as customer_state
Into 
	Olist_DWH.dbo.Dim_customers
from 
			Olist.dbo.olist_customers_dataset as C
		join 
			Olist.dbo.olist_geolocation_dataset as G
		On 
			C.customer_zip_code_prefix = G.geolocation_zip_code_prefix
Where 1=2

/***************************************** Dim_Sellers table ***************************************/

---Creating [Dim_sellers table]

Select 
	S.seller_id,
	G.geolocation_city   as seller_city,
	G.geolocation_state  as seller_state
Into 
	Olist_DWH.dbo.Dim_sellers
from 
			Olist.dbo.olist_sellers_dataset as S
		join 
			Olist.dbo.olist_geolocation_dataset as G
		On 
			S.seller_zip_code_prefix = G.geolocation_zip_code_prefix
Where 1=2

/***************************************** Dim_Orders table ***************************************/
---Creating [Dim_orders table]

Select
		O.order_id      as order_key,
		R.review_id     as review_key,
		S.status_type,
		Pt.payment_type,
		P.payment_sequential,
		P.payment_installments,
		R.review_score,
		R.review_comment_title,
		R.review_comment_message
Into 
		Olist_DWH.dbo.dim_orders
From 
		Olist.dbo.olist_orders_dataset as O
			Join 
			  Olist.dbo.olist_order_payments_dataset as P
			on 
			  o.order_id = P.order_id
			Join 
			  Olist.dbo.payment_types as Pt
			on 
			  P.payment_type_id = Pt.id
			Join 
			  Olist.dbo.olist_order_reviews_dataset as R
			on 
			  o.order_id = R.order_id
			Join 
			  Olist.dbo.order_status_types as S
			on 
			O.order_status_id = S.id
Where 
			1=2



/***************************************** Factsales table ***************************************/
---Creating [Factsales table]

SELECT
		O.order_id                      as order_key,
		O.customer_id                   as customer_key,
		S.seller_id                     as seller_key,
		Pro.product_id                  as product_key,
		O.order_purchase_timestamp      as purchase_timestamp_key,
		O.order_approved_at             as approved_at_key,
        O.order_delivered_carrier_date  as delivered_carrier_date_key,
        O.order_delivered_customer_date as delivered_customer_date_key,
        O.order_estimated_delivery_date as estimated_delivery_date_key,
	    I.shipping_limit_date           as shipping_limit_date_key,
        R.review_creation_date          as review_creation_date_key,
		R.review_answer_timestamp       as review_answer_timestamp_key,
		I.product_counter               as product_amount,
		P.payment_value                 as sales_amount,
		I.freight_value                 as freight_amount
			
Into 
		Olist_DWH.dbo.factsales           
    
FROM 
           [Olist].[dbo].[olist_orders_dataset] as O
		      Join   
			    [Olist].[dbo].olist_order_payments_dataset as P
			  on 
			     O.order_id = P.order_id
			  Join
			    [Olist].[dbo].[items_dataset] as I
			  on 
			    O.order_id = I.order_id
			  Join
			    [Olist].[dbo].[olist_sellers_dataset] as S
			  on
				S.seller_id = I.seller_id
			  
			  Join
			    [Olist].[dbo].[olist_products_dataset] as Pro
			  on
				Pro.product_id = I.product_id
		      Join
			    [Olist].[dbo].[olist_order_reviews_dataset] as R
			  on
				R.order_id = O.order_id
Where 
		1=2



