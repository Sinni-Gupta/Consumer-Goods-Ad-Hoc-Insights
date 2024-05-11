# 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
SELECT market FROM dim_customer 
where customer = "Atliq Exclusive" and region = "APAC"
group by market
order by market;

# 2. What is the percentage of unique product increase in 2021 vs. 2020? 
#The final output contains these fields,
# unique_products_2020
# unique_products_2021 
# percentage_chg
with cte20 as (
	   select count(distinct product_code) as unique_products_2020 from fact_sales_monthly
       where fiscal_year = 2020 ),
cte21 as (
       select count(distinct product_code) as unique_products_2021 from fact_sales_monthly
       where fiscal_year = 2021 )
select *,
		 (unique_products_2021 - unique_products_2020) as new_products_introduce,
         round((unique_products_2021 - unique_products_2020)*100/ unique_products_2020 ,2) as pct_change
from cte20
cross join 
cte21;  

# 3.Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
# The final output contains 2 fields,
# segment 
# product_count 
SELECT 
    segment,
    count(distinct product_code) as product_count
from dim_product
group by segment
order by product_count desc ;

# 4.Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields,
# segment
# product_count_2020
# product_count_2021
# difference 
with cte20 as (
     select p.segment,
        count(distinct (f.product_code)) as product_count_2020
     from fact_sales_monthly f
     join dim_product p
     on p.product_code = f.product_code
     where fiscal_year = 2020
     group by segment
      ),
cte21 as (
     select p.segment,
	 count(distinct (f.product_code)) as product_count_2021
     from fact_sales_monthly f 
     join dim_product p
     on p.product_code = f.product_code
     where fiscal_year = 2021
     group by segment
    )      
SELECT 
	cte20.segment,
    product_count_2020,
    product_count_2021,
    (product_count_2021 - product_count_2020) as difference
from cte20
join cte21
using (segment)
order by difference desc limit 1;

# 5.Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields, 
# product_code
# product
# manufacturing_cost
SELECT 
    p.product_code,
    p.product,
    m.manufacturing_cost
FROM dim_product p
join fact_manufacturing_cost m
using(product_code)
where
	 manufacturing_cost = (select max(manufacturing_cost) from fact_manufacturing_cost) or
	 manufacturing_cost = (select min(manufacturing_cost) from fact_manufacturing_cost)
order by manufacturing_cost desc;

#6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the
# fiscal year 2021 and in the Indian market. The final output contains these fields, 
#customer_code 
#customer 
#average_discount_percentage 
SELECT 
d.customer_code,
c.customer,
concat(round(avg(d.pre_invoice_discount_pct)*100,2),"%") as avg_discount_percentage
FROM fact_pre_invoice_deductions d
join dim_customer C
using(customer_code)
where
   fiscal_year = 2021 and market = "India" 
group by d.customer_code, c.customer
order by avg(d.pre_invoice_discount_pct) desc limit 5;

#7.Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . 
#This analysis helps to get an idea of low and high-performing months and take strategic decisions. The final report contains these columns:
# Month 
#Year 
#Gross sales Amount
SELECT 
     concat(monthname(fs.date), '(' ,year(fs.date) , ')') as Month ,
     fs.fiscal_year,
     concat(round(sum(g.gross_price * fs.sold_quantity/1000000),2), 'M') as Gross_sales_Amount
FROM fact_sales_monthly fs
join dim_customer c on c.customer_code = fs.customer_code
join fact_gross_price g on g.product_code = fs.product_code and g.fiscal_year = fs.fiscal_year
where c.customer = "Atliq Exclusive"
group by Month , fs.fiscal_year
order by fs.fiscal_year;

#8.In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity,
# Quarter 
#total_sold_quantity
with cte as (
  select *,
       case
           when month(s.date) in (9,10,11) then "Q1"
		   when month(s.date) in (12,1,2) then "Q2"
		   when month(s.date) in (3,4,5) then "Q3"
		   else "Q4"
       end as Quarter    
 FROM fact_sales_monthly as s
 where fiscal_year = 2020
)
select 
     Quarter ,
     sum(sold_quantity) as total_sold_quantity
from cte
group by Quarter 
order by total_sold_quantity desc ; 

--- 9.Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
# The final output contains these fields,
# channel 
# gross_sales_mln
# percentage 
with cte as (
   SELECT 
		 c.channel,
         concat(round(sum(g.gross_price*fs.sold_quantity/1000000),2), "M")  as gross_sales_mln
   FROM dim_customer c
   join fact_sales_monthly fs 
   on 
       fs.customer_code = c.customer_code
   join fact_gross_price g
   on
       g.product_code = fs.product_code and
       g.fiscal_year = fs.fiscal_year
   where fs.fiscal_year = 2021
   group by channel
   order by gross_sales_mln desc )
select *,
     concat(round(gross_sales_mln*100/sum(gross_sales_mln) over() ,2), "%") as percentage
from cte;

# 10.Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
# The final output contains these fields,
# division 
# product_code
with cte as (
     select 
       p.division,
       p.product_code,
       p.product,
       sum(fs.sold_quantity) as total_sold_quantity
     from dim_product p 
     join fact_sales_monthly fs 
     on 
		fs.product_code = p.product_code
     where fs.fiscal_year = 2021
     group by p.product_code, p.division, p.product
     order by total_sold_quantity desc
     ),
cte1 as (  
select 
	 *,
	dense_rank() over(partition by division order by total_sold_quantity desc) as rank_order
from cte)
select
     division,
     product_code,
     product,
     total_sold_quantity,
     rank_order
from cte1
where rank_order<=3;     
      
       
   
     
        
        