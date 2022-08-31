-- Cleaning 
-- customers_orders
Update customer_orders
set 
exclusions = case when exclusions = '' then null else exclusions end,
extras = case when extras = '' then null else extras end

-- runner_orders
Update runner_orders
Set
distance = case when distance like '%km' then trim('km' from distance) else distance end,
duration = Case
            when duration like '%minutes' then trim('minutes' from duration)
			when duration like '%mins' then trim('mins' from duration)
			when duration like '%minute' then trim('minute' from duration)
            else duration end

Update runner_orders
Set
distance = case  when distance = '' then null else distance end,
duration = case when duration = '' then null else duration end,
cancellation = case when cancellation = '' then null else cancellation end



-- Pizza Metrics
-- 1.How many pizzas were ordered?
Select Count(*) as [total pizzas ordered]
From customer_orders



-- 2.How many unique customer orders were made?
Select Count(Distinct order_id) as [Unique customer orders]
From customer_orders



-- 3.How many successful orders were delivered by each runner?
Select runner_id, Count(*) delivered_orders
From runner_orders
Where pickup_time is not null
Group By runner_id



-- 4.How many of each type of pizza was delivered?
Select p.pizza_name, Count(c.pizza_id) delivered_pizza_count
From customer_orders  c
Join runner_orders  r
On c.order_id = r.order_id
Join pizza_names  p
On c.pizza_id = p.pizza_id
Where r.distance is not null
Group By p.pizza_name



-- 5.How many Vegetarian and Meatlovers were ordered by each customer?
Select *
From
(Select c.customer_id, p.pizza_name
 From customer_orders c
 Join pizza_names p
 On c.pizza_id= p.pizza_id) as Tab
Pivot (Count(pizza_name) For pizza_name In ([Meatlovers],[Vegetarian]) ) as Tab2



-- 6.What was the maximum number of pizzas delivered in a single order?
Select Top(1) c.order_id, count(*) as [Number of pizzas]
From customer_orders c
left Join runner_orders r
On c.order_id =r.order_id
Where r.distance is not null
Group By c.order_id
Order by [Number of pizzas] desc



-- 7.For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
Select c.customer_id,
Sum(Case When c.exclusions is not null or c.extras  is not null Then 1 Else 0 End) change,
Sum(Case When c.exclusions is null and c.extras is null Then 1 Else 0 End) no_change
From customer_orders  c
Join runner_orders  r
On c.order_id = r.order_id
Where r.distance is not null
Group By c.customer_id
Order By c.customer_id



-- 8.How many pizzas were delivered that had both exclusions and extras?
Select Sum(Case When exclusions is not null and extras  is not null Then 1 Else 0 End) [Pizzas Delivered]
From customer_orders  c
Join runner_orders  r
On c.order_id = r.order_id
Where r.distance is not null



-- 9.What was the total volume of pizzas ordered for each hour of the day?
Select Datepart(Hour, order_time) hour_of_day, Count(order_id) [Pizzas ordered]
FROM customer_orders
Group By Datepart(Hour, order_time)



-- 10.What was the volume of orders for each day of the week?
Select Datepart(DW, order_time) day_num,Datename(DW,order_time) day_of_week , Count(order_id) [Pizzas ordered]
FROM customer_orders
Group By Datename(DW, order_time), Datepart(DW, order_time)
Order By Datepart(DW, order_time)