CREATE DATABASE SUPERSTORE_DB;
USE SUPERSTORE_DB;

-- DATA EXPLORATION

select count(*) AS Total_rows from orders;
show tables;
select * from orders 
limit 5;

alter table orders
rename column `order id` to order_id;
ALTER TABLE orders
RENAME COLUMN `order date` TO order_date,
RENAME COLUMN `ship date` TO ship_date,
RENAME COLUMN `ship mode` TO ship_mode,
RENAME COLUMN `customer id` TO customer_id,
RENAME COLUMN `customer name` TO customer_name,
RENAME COLUMN `postal code` TO postal_code,
RENAME COLUMN `product id` TO product_id,
RENAME COLUMN `product name` TO product_name,
RENAME COLUMN `sub-category` TO sub_category;

describe orders;
-- unique   values
select distinct category from orders;
select distinct region from orders;
select distinct segment from orders;
select distinct ship_mode from orders;
select distinct sub_category from orders group by sub_category;


-- DATA CLEANING

create table order_clean as select * from orders;
select count(*) from order_clean;
select * from order_clean limit 5;
-- duplicates records
select order_id,product_id,count(*) as duplicate_count
from order_clean 
group by order_id,product_id
having count(*)>1;
-- null values
select  * from order_clean
where order_id is null 
or  product_id is null 
or  order_date is null 
or  sales is null 
or   profit is null 
or   customer_name is null 
or ship_date is null;


-- blank values
select * from order_clean
where trim(customer_name)='' 
or trim(category)=''
or trim(region)=''
or trim(product_name)='';

describe order_clean;
describe orders;

update order_clean
set order_date =str_to_date(order_date,"%m/%d/%Y");

alter table order_clean
modify column order_date date;

select 
min(order_date) as first_order,
max(order_date) as last_order
from order_clean;
select * from order_clean;


-- checking all the numeric values
select 
min(sales) as min_sales,
max(sales) as max_sales,
min(profit) as min_profit,
max(profit) as max_profit,
min(quantity) as min_quantity,
max(quantity) as max_quantity,
min(discount) as min_discount,
max(discount) as max_discount from order_clean;

show columns from order_clean;
select * from order_clean;

update order_clean
set customer_name=trim(customer_name),
product_name=trim(product_name),
region=trim(region),
city=trim(city),
state=trim(state),
ship_mode=trim(ship_mode);

select count(*) from order_clean;

-- KPIS

# 1.Total Sales
select round(sum(sales),2) as total_sales from order_clean;

# 2.Total Profit
select round(sum(profit),2) as total_profit from order_clean;

# 3.Total Orders
select count(distinct order_id) as total_orders
from order_clean;

# 4.total customers
select count(distinct customer_id) as total_customers
from order_clean;

# 5.Total Products Sold
select sum(quantity) as total_products_sold
from order_clean;

# 6.Average Order value
select round(sum(sales)/count(order_id),2) as avg_order_value
from order_clean;

# 7.Proft Margin%
select round((sum(profit) /sum(sales)) * 100,0) as profit_margin_percentage
from order_clean;

-- CATEGORY ANALYSIS

# 8.sales & profit by category
select category,round(sum(sales),2) as total_category_sales,
round(sum(profit),2) as total_category_profit
from order_clean
group by Category
order by total_category_sales desc;

# 9.Sales & Profit By Sub-Category
select sub_category ,round(sum(sales),2) as total_sales,
round(sum(profit),2) as total_profit
from order_clean
group by sub_category
order by total_sales desc;

# 10.Profit Margin by Category?
select category,round(sum(sales),2) as total_sales,
round(sum(profit),2) as total_profit,
round(sum(profit)/sum(sales),2) as profit_percent
from order_clean
group by category
order by profit_percent desc;

-- REGIONAL ANALYSIS

# 11.Which region generates the highest sales and profit?
select region,round(sum(sales),2) as total_sales,
round(sum(profit),2) as total_profit,
round((SUM(profit)/SUM(sales))*100,2) AS profit_margin_percent
from order_clean
group by region
order by total_sales desc;

# 12.Which states contribute the highest sales and profit?
select state,round(sum(sales),2) as total_sales,
round(sum(profit),2) as total_profif
from order_clean
group by state
order by total_sales desc;

# 13.Which states are generating losses despite making sales?
select state,round(sum(sales),2) as total_sales,
round(sum(profit),2) as total_profit
from order_clean
group by state
having sum(profit)<0
order by total_profit;

-- TIME ANALYSIS
select * from order_clean limit 5;

# 14.How have sales and profit changed over the years?
select year(order_date) as order_year,
round(sum(sales),2) as sales ,
round(sum(profit),2) as profit 
from order_clean
group by year(order_date)
order by order_year desc;

# 15.What is the monthly sales and profit trend?
select 
year(order_date) as order_year,
month(order_date) as order_month,
monthname(order_date) as month_name,
round(sum(sales),2) as sales ,
round(sum(profit),2) as profit 
from order_clean
group by 
     year(order_date),
     month(order_date),
     monthname(order_date)
order by
   order_year,
   order_month desc;
   
# 16.Which month records the highest sales?
select monthname(order_date) as month_name,
round(sum(sales),0)  as total_sales
from order_clean
group by monthname(order_date)
order by total_sales desc;

# 17. What is the Month-over-Month (MoM) sales growth?
with  monthly_sales as (
select date_format(order_date,'%Y-%m') as month,
round(sum(sales),2) as total_sales
from order_clean
group by date_format(order_date,'%Y-%m')
)
select month,total_sales,
lag(total_sales) over(order by month ) as previous_month_sales,
round(
((total_sales-lag(total_sales) over(order by month ))
/lag(total_sales) over(order by month ))*100,2 
)as growth_percentage
from monthly_sales;

select * from order_clean limit 5;

-- BUSINESS INSIGHTS

# 18.Does offering higher discounts increase sales but reduce profit?
Select discount,
round(sum(sales),2) as total_sales,
round(sum(profit),2) as total_profit,
round((sum(profit)/sum(sales))*100,2) as profit_percent
from order_clean
group by discount
order by discount;

# 19.Which products are generating losses for the business?
Select product_name,category,sub_category,
round(sum(sales),2) as total_sales,
round(sum(profit),2) as total_profit
from order_clean
group by product_name,category,sub_category
having sum(profit)<0
order by total_profit;

select * from order_clean limit 5;
# 20.Which customer segment is the most profitable?
select segment,count(distinct customer_id) as total_customers,
round(sum(sales),2) as total_sales,
round(sum(profit),2) as total_profit,
round((sum(profit)/sum(sales))*100,2) as profit_percent
from order_clean
group by segment
order by total_profit desc;

# 21.Which shipping mode provides the best profitability?
select ship_mode,count(distinct order_id) as total_customers,
round(sum(sales),2) as total_sales,
round(sum(profit),2) as total_profit,
round((sum(profit)/sum(sales))*100,2) as profit_percent
from order_clean
group by ship_mode
order by total_profit desc;

# 22.How can we classify products based on their profitability?
select product_name,
round(sum(sales),2) as total_sales,
round(sum(profit),2) as total_profit,
CASE
  when sum(profit) > 5000 then"hight profit"
  when sum(profit) between 1000 AND 5000 then "medium profit"
  else "low profit"
  end as profit_category
from order_clean
group by product_name
order by total_profit desc;

# 23.Which sub-categories have generated more than ₹50,000 in sales?
select sub_category,
round(sum(sales),2) as total_sales
from order_clean
group by sub_category
having sum(sales)>50000
order by total_sales desc;

# 24.Which products have sales higher than the average product sales?
select product_name,
round(sum(sales),2) as total_sales
from order_clean
group by product_name 
having sum(sales) >
(
   select avg(total_sales) 
   from 
   (
    select sum(sales) as total_sales
    from order_clean
    group by product_name 
    ) as avg_sales 
    );
    
# 25.Which categories generate above-average profit?
with category_profit AS
(
select category,sum(profit) as total_profit
from order_clean
group by category
)
select * from category_profit
where total_profit >
(
select avg(total_profit)
from category_profit
);

# 26.Rank products based on total sales.
select product_name,
round(sum(sales),2) as total_sales,
rank() over(order by sum(sales) desc) as sales_rank
from order_clean
group by product_name;

# 27.Rank customers based on total profit without skipping ranks.
with customer_profit as
( select customer_name,
round(sum(sales),2) as total_profit
from order_clean
group by customer_name
)
select customer_name,total_profit,
dense_rank() over(order by total_profit desc) as profit_rank
from customer_profit;

# 28. How has cumulative sales grown over time?
with monthly_sales as
(
select date_format(order_date,'%y-%m') as month,
sum(sales) as total_sales
from order_clean
group by date_format(order_date,'%y-%m')
)
select month,total_sales,
sum(total_sales) over(order by month) as running_total_sales
from monthly_sales;

# 29.Create a reusable summary of category performance.
create view category_summary as
select category,
round(sum(sales),2) as total_sales,
round(sum(profit),2) as total_profit
from order_clean
group by category;

select * from category_summary;





















