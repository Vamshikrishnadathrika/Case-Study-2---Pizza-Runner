-- Ingredient Optimisation
-- Creating #pizza_recipes
DROP TABLE IF EXISTS #pizza_recipes;
select pizza_id, trim(value) toppings
into #pizza_recipes
from 
	(select pizza_id, cast(toppings as varchar(max)) toppings
	 from pizza_recipes) a 
CROSS APPLY STRING_SPLIT(toppings, ',')
order by pizza_id
Select *
From #pizza_recipes

-- Getting row number
Select ROW_NUMBER() OVER(order by order_id, pizza_id) no,*
Into #customer_orders
From customer_orders

-- split row in exclusions and extras columns
DROP TABLE IF EXISTS #customer_orders_split
WITH customer_orders_CTE (no,order_id, customer_id, pizza_id, exclusions, extras, order_time)  
AS  
(SELECT  no,order_id, customer_id, pizza_id, trim(value) exclusions, extras, order_time 
 FROM #customer_orders 
 CROSS APPLY STRING_SPLIT(exclusions, ',')
 Union all
 Select no,order_id, customer_id, pizza_id,  exclusions, extras, order_time
 From #customer_orders
 Where extras is not null and exclusions is null
)
SELECT no,order_id, customer_id, pizza_id, exclusions,trim(value) extras, order_time  
Into #customer_orders_split
FROM customer_orders_CTE
CROSS APPLY STRING_SPLIT(extras, ',')
Union all
 Select no,order_id, customer_id, pizza_id,  exclusions, extras, order_time
 From #customer_orders
 Where extras is null and exclusions is not null and len(exclusions) < 2
Order by order_id, customer_id, pizza_id, exclusions, extras;
Alter table #customer_orders_split
	alter column exclusions int;
Alter table #customer_orders_split
	alter column extras int;
Select *
From #customer_orders_split

-- total orders
DROP TABLE IF EXISTS #total;
Select p.pizza_id, Count(c.pizza_id) count
Into #total
From customer_orders  c
Join runner_orders  r
On c.order_id = r.order_id
Join pizza_names  p
On c.pizza_id = p.pizza_id
Where r.distance is not null
Group By p.pizza_id





-- 1.What are the standard ingredients for each pizza?
Select pizza_name, STRING_AGG(topping_name,', ') toppings
From pizza_names pn
Left Join #pizza_recipes pr
On pn.pizza_id =pr.pizza_id
Left Join pizza_toppings pt
On pt.topping_id = pr.toppings
Group By pizza_name



-- 2.What was the most commonly added extra?
Select topping_name, count(extras) no_of_times_added
Into #extra
From
(Select distinct no, extras
 From #customer_orders_split
 Where extras is not null) as tab
Left Join pizza_toppings pt
On tab.extras = pt.topping_id
Group by topping_name
Select*
From #extra



-- 3.What was the most common exclusion?
Select topping_name, count(exclusions) no_of_times
Into #exclusions
From
(Select distinct no, exclusions
 From #customer_orders_split
 Where exclusions is not null) as tab
Left Join pizza_toppings pt
On tab.exclusions = pt.topping_id
Group by topping_name
Select*
From #exclusions



-- 4. Generate an order item for each record in the customers_orders table in the 
-- format of one of the following:
Select order_id, customer_id, CONCAT(pizza_name,exc,ext) order_item
From
(select order_id, customer_id,  pizza_name,
 case when tc1 is null then ''
	  when tc2 is null then CONCAT('- Exclude', ' ', tc1)
	  else CONCAT('- Exclude', ' ', tc1, ', ', tc2) end exc,
 case when tx1 is null then ''
	  when tx2 is null then CONCAT('- Extra', ' ', tx1)
	  else CONCAT('- Extra', ' ', tx1, ', ', tx2) end ext
 From
 (select order_id, customer_id,n.pizza_name, tc1.topping_name tc1, tc2.topping_name tc2,
  tx1.topping_name tx1, tx2.topping_name tx2
  From
  (Select *,
   CAST(LEFT(exclusions, CHARINDEX(',', exclusions + ',') -1) as int) exc1,
   CAST(STUFF(exclusions, 1, Len(exclusions) +1- CHARINDEX(',',Reverse(exclusions)), '') as int) exc2,
   CAST(LEFT(extras, CHARINDEX(',', extras + ',') -1) as int) ext1,
   CAST(STUFF(extras, 1, Len(extras) +1- CHARINDEX(',',Reverse(extras)), '') as int) ext2
   From #customer_orders ) a
   left join pizza_names n on a.pizza_id = n.pizza_id
   left join pizza_toppings tc1 on a.exc1 = tc1.topping_id
   left join pizza_toppings tc2 on a.exc2 = tc2.topping_id
   left join pizza_toppings tx1 on a.ext1 = tx1.topping_id
   left join pizza_toppings tx2 on a.ext2 = tx2.topping_id ) b ) c


-- 5.Generate an alphabetically ordered comma separated ingredient list for each pizza order 
-- from the customer_orders table and add a 2x in front of any relevant ingredients
SELECT f.order_id, cn.customer_id, cn.pizza_id, cn.exclusions, cn.extras, cn.order_time,
CONCAT(f.pizza_name, ': ', f.list) ingredient_list
FROM 
(SELECT no, order_id, pizza_id, pizza_name, STRING_AGG(counts, ', ') list
 FROM
 (SELECT no, order_id, pizza_id, pizza_name, topping_id,
  CASE WHEN counts = 1 THEN topping_name 
	   ELSE CONCAT(counts, 'x ',topping_name) END counts
  FROM
  (SELECT no, order_id, customer_id, pizza_id, pizza_name, topping_id, topping_name, COUNT(topping_id) counts
   FROM 
   (SELECT b.*, t.topping_name
    FROM
    (SELECT no, order_id, customer_id, pizza_id, pizza_name, topping_id
	 FROM
	 (Select c.no, c.order_id, c.customer_id, n.*, t.*
	  from #customer_orders c
	  left join pizza_names n on c.pizza_id = n.pizza_id
	  left join #pizza_recipes r on c.pizza_id = r.pizza_id
	  left join pizza_toppings t on r.toppings = t.topping_id ) a
	  EXCEPT
      SELECT *
	  FROM
	  (SELECT c.no, c.order_id, c.customer_id, c.pizza_id, n.pizza_name, cast(trim(value) as int) exclusions
	   FROM #customer_orders c
	   left join pizza_names n on c.pizza_id = n.pizza_id
	   CROSS APPLY STRING_SPLIT(c.exclusions, ',') ) exclusions_orders
	  UNION ALL
      SELECT *
	  FROM
	  (SELECT c.no, c.order_id, c.customer_id, c.pizza_id, n.pizza_name, cast(trim(value) as int) extras
	   FROM #customer_orders c
	   left join pizza_names n on c.pizza_id = n.pizza_id
	   CROSS APPLY STRING_SPLIT(c.extras, ',')
	   where cast(trim(value) as int) != 0) extras_orders ) b
  left join pizza_toppings t on b.topping_id = t.topping_id ) c
  GROUP BY no, order_id, customer_id, pizza_id, pizza_name, topping_id, topping_name) d )e
 GROUP BY no, order_id, pizza_id, pizza_name)f
left join #customer_orders cn on cn.no = f.no
ORDER BY f.no, f.order_id, f.pizza_id;



-- What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
Select a.topping_name ,
Case 
When e2 is null and e1 is null then total_added
When e2 is not null and e1 is null then total_added+e2
When e2 is null and e1 is not null then total_added+e1
When e2 is not null and e1 is not null then total_added+e1+e2
Else null End  total
From
(Select topping_name, sum(number) as total_added
From
(Select pizza_name, topping_name, 
Case When pr.pizza_id = 1 Then (Select count From #total Where pizza_id=1)
When pr.pizza_id = 2 Then (Select count From #total Where pizza_id=2) 
End as number
From pizza_names pn
Left Join #pizza_recipes pr
On pn.pizza_id =pr.pizza_id
Left Join pizza_toppings pt
On pt.topping_id = pr.toppings) totals
Group By topping_name) a
Left join (Select topping_name, (-1)*no_of_times e2 From #exclusions) ec on ec.topping_name=a.topping_name
Left join (Select topping_name, no_of_times_added  e1 From #extra) ex on ex.topping_name=a.topping_name
Order By total desc
