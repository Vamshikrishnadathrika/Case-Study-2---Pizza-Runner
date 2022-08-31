-- Runner and Customer Experience

-- 1.How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
Select Datediff(day, '2020-12-31', registration_date)/7+1 as week, Count(runner_id) runners
From runners
Group By Datediff(day, '2020-12-31', registration_date)/7+1



-- 2.What was the average time in minutes it took for each runner to arrive at the Pizza Runner 
--HQ to pickup the order?
Select runner_id, Avg(pt) as avg_pickup_time
From
(Select distinct r.order_id, runner_id, DATEDIFF(MINUTE, order_time, pickup_time) as pt
 From runner_orders r
 Left Join customer_orders c
 On r.order_id = c.order_id
 Where r.distance is not null) as tab
Group By runner_id



-- 3.Is there any relationship between the number of pizzas and how long the order takes to prepare?
Select no_of_pizzas, Avg(pt) time
From
(Select r.order_id, count(r.order_id) as no_of_pizzas, DATEDIFF(MINUTE, order_time, pickup_time) as pt
 From runner_orders r
 Left Join customer_orders c
 On r.order_id = c.order_id
 Where r.distance is not null
 Group By r.order_id,DATEDIFF(MINUTE, order_time, pickup_time)) as tab
Group By no_of_pizzas



-- 4.What was the average distance travelled for each customer?
Select customer_id, Avg(distance) avg_distance_travelled
From
(Select Distinct customer_id, r.order_id, cast(distance as float) distance
 From runner_orders r
 Left Join customer_orders c
 On r.order_id = c.order_id) as tab
Where distance is not null
Group By customer_id



-- 5. What was the difference between the longest and shortest delivery times for all orders?
Select max(duration)-min(duration) time_min
From runner_orders



-- 6. What was the average speed for each runner for each delivery and do you notice any trend
--for these values?
Select r.order_id, runner_id, distance,count(*) as pizzas, Round((distance/duration)*60, 2) Average_speed
From runner_orders r
Left Join customer_orders c
On r.order_id = c.order_id
Where distance is not null
Group By r.order_id, runner_id, distance, Round((distance/duration)*60, 2)
Order By runner_id, distance



--7. What is the successful delivery percentage for each runner?
Select runner_id, Sum(Case When distance is not null Then 1 Else 0 End)*100/Count(*) as percentage
From runner_orders
Group By runner_id