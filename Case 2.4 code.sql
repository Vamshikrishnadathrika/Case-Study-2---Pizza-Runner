--1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes 
-- how much money has Pizza Runner made so far if there are no delivery fees?
select sum(case when pizza_id = 1 then 12
			when pizza_id = 2 then 10 end) money
from customer_orders c
left join runner_orders r on r.order_id = c.order_id
where distance is not null



-- 2.What if there was an additional $1 charge for any pizza extras? Add cheese is $1 extra
select sum(case when pizza_id = 1 then 12 when pizza_id = 2 then 10 end) +
sum(len(REPLACE(REPLACE(extras,',',''),' ',''))) money
from customer_orders c
left join runner_orders r 
on r.order_id = c.order_id
where distance is not null



-- 3.rating table
DROP TABLE IF EXISTS #rating_orders;
CREATE TABLE #rating_orders (order_id INTEGER,rating INTEGER);

Insert into #rating_orders
(order_id, rating)
Values (1, 3),(2, 4),(3, 2),(4, 5),(5, 1),(6, 4),(7, 3),(8, 2),(9, 3),(10, 5);
select * from #rating_orders



-- 4.generated table
DROP TABLE IF EXISTS #generated_table;
select c.customer_id, c.order_id, r.runner_id,ro.rating, c.order_time, r.pickup_time,
DATEPART(MINUTE, r.pickup_time - c.order_time) time_between_order_and_pickup,r.duration delivery_duration,
round(r.distance/r.duration * 60, 2) average_speed,count(*) Total_number_of_pizzas
into #generated_table
from #rating_orders ro
left join customer_orders c on c.order_id = ro.order_id
left join runner_orders r on ro.order_id = r.order_id
where r.distance is not null
group by c.customer_id, c.order_id, r.runner_id, ro.rating, c.order_time, r.pickup_time, r.distance, r.duration;
select * from #generated_table
order by order_id



-- 5.total profit
select sum(case when pizza_id = 1 then 12 when pizza_id = 2 then 10 end)+
(select  sum(distance) * -0.3 from runner_orders where distance is not null) money
from customer_orders c
left join runner_orders r on r.order_id = c.order_id
where distance is not null