/* Pizza Sales Data Exploration 
This is exploratory data analysis on a year's worth of sales data from a fictitious pizza store.
The raw data is available at Maven Analytics (https://www.mavenanalytics.io/data-playground) in 4 CSV files, and it includes the date and time of each order, pizza purchased, and additional details such as type, size, quantity, price, ingredients, and price of each pizza.

Here is the data field discription provided with the data by Maven Analytics (downloadable at the same link)
Table	  	Field	  		Description
orders		order_id		Unique identifier for each order placed by a table
orders		date			Date the order was placed (entered into the system prior to cooking & serving)
orders		time			Time the order was placed (entered into the system prior to cooking & serving)
order_details	order_details_id	"Unique identifier for each pizza placed within each order 
					(pizzas of the same type and size are kept in the same row, and the quantity increases)"
order_details	order_id		Foreign key that ties the details in each order to the order itself
order_details	pizza_id		Foreign key that ties the pizza ordered to its details, like size and price
order_details	quantity		Quantity ordered for each pizza of the same type and size
pizzas		pizza_id		Unique identifier for each pizza (constituted by its type and size)
pizzas		pizza_type_id		Foreign key that ties each pizza to its broader pizza type
pizzas		size			Size of the pizza (Small, Medium, Large, X Large, or XX Large)
pizzas		price			Price of the pizza in USD
pizza_types	pizza_type_id		Unique identifier for each pizza type
pizza_types	name			Name of the pizza as shown in the menu
pizza_types	category		Category that the pizza fall under in the menu (Classic, Chicken, Supreme, or Veggie)
pizza_types	ingredients		"Comma-delimited ingredients used in the pizza as shown in the menu 
					(They all include Mozzarella Cheese, even if not specified; and they all include Tomato Sauce, unless another sauce is specified)"
*/

select * from PizzaSalesPortfolio.dbo.Orders order by order_id
select * from PizzaSalesPortfolio.dbo.OrderDetails order by order_details_id
select * from PizzaSalesPortfolio.dbo.Pizzas order by pizza_id
select * from PizzaSalesPortfolio.dbo.PizzaTypes order by pizza_type_id

--<Let's look at Number of Customers> 
--daily customers (orders)
select date, count(order_id) as daily_orders, AVG(cast(count(order_id) as decimal(10,1))) over() as Average_daily_orders_overall
from PizzaSalesPortfolio.dbo.Orders 
group by date order by date

--Highlight days that have more 90 percentile of daily orders.
select date, datename(dw, date) as day_of_week, count(order_id) as daily_orders,  
	   AVG(cast(count(order_id) as decimal(10,1))) over() as Average_daily_orders_overall, 
	   AVG(cast(count(order_id) as decimal(10,1))) over(partition by month(date)) as Average_daily_orders_by_month,
	   percentile_cont(0.9) within group(order by count(order_id)) over() as Ninety_Percent, 
	   CASE WHEN count(order_id)>=percentile_cont(0.9) within group(order by count(order_id)) over() THEN 'Over 90%' END
from PizzaSalesPortfolio.dbo.Orders 
group by date 
order by date

--Customers by each day of week
select datename(dw, date) as day_of_week, count(order_id) as total_orders
from PizzaSalesPortfolio.dbo.Orders 
group by datename(dw, date), datepart(dw,date) order by datepart(dw, date)

--Monthly customers(orders)
select datename(month,date) as Month, count(order_id) as Monthly_orders, RANK() over (order by count(order_id) desc) as Rank
from PizzaSalesPortfolio.dbo.Orders 
group by datename(month,date), month(date)
order by month(date)
--July, May, January, August, are top 4 peak months.

--Peak Time of day?
select datepart(hour, time) as Hour_of_day, count(order_id) as Total_orders
from PizzaSalesPortfolio.dbo.Orders 
group by datepart(hour, time)
order by datepart(hour, time)


--<Let's look at Orders in Details>
--How many pizzas are in one order? 
--1) Total Average number of Pizzas per order
WITH NumOfPizzasForEachOrder AS
(select O.order_id, count(O.order_id) as Number_of_pizzas
 from PizzaSalesPortfolio.dbo.Orders as O left join PizzaSalesPortfolio.dbo.OrderDetails as OD on O.order_id=OD.order_id
 group by O.order_id)
SELECT AVG(cast(Number_of_pizzas as decimal(5,1))) as Total_Avg_num_of_pizzas_per_order 
from NumOfPizzasForEachOrder;

--2)Average number of pizzas per order by each month  (It doesn't vary much by month)
WITH NumOfPizzasForEachOrder1 AS
(select month(O.date) as Month, O.order_id, count(O.order_id) as Number_of_pizzas
 from PizzaSalesPortfolio.dbo.Orders as O left join PizzaSalesPortfolio.dbo.OrderDetails as OD on O.order_id=OD.order_id
 group by month(O.date), O.order_id)
SELECT Month, AVG(cast(Number_of_pizzas as decimal(5,1))) as Avg_Num_of_Pizzas_per_order
from NumOfPizzasForEachOrder1
group by Month 
order by Month;    

--3) What are most common number of pizzas per orders?  (Number of orders for different numbers of pizzas per orders)
WITH NumOfPizzasForEachOrder2 AS
(select O.order_id, count(O.order_id) as Number_of_pizzas
 from PizzaSalesPortfolio.dbo.Orders as O left join PizzaSalesPortfolio.dbo.OrderDetails as OD on O.order_id=OD.order_id
 group by O.order_id)
SELECT Number_of_pizzas, count(order_id) as Number_of_orders
from NumOfPizzasForEachOrder2
group by Number_of_pizzas
order by Number_of_pizzas


--<Let's find out What type of pizzas are more popular>
--1) What are the BEST seller and WORST seller?>
select PT.name, sum(quantity) as Quantity_sold
from PizzaSalesPortfolio.dbo.Orders as O left join PizzaSalesPortfolio.dbo.OrderDetails as OD on O.order_id=OD.order_id 
     left join PizzaSalesPortfolio.dbo.pizzas as P on OD.pizza_id=P.pizza_id
	 left join PizzaSalesPortfolio.dbo.PizzaTypes as PT on P.pizza_type_id=PT.pizza_type_id
group by PT.name
order by Quantity_sold desc
--BEST: Classic Deluxe, WORST: Brie Carre

--2) Top 3 sellers of each month
select month, name, Quantity_sold 
from (select month(date) as month, PT.name, sum(quantity) as Quantity_sold, rank() over (partition by month(date) order by sum(quantity) desc) as QuantityRank
      from PizzaSalesPortfolio.dbo.Orders as O left join PizzaSalesPortfolio.dbo.OrderDetails as OD on O.order_id=OD.order_id 
		   left join PizzaSalesPortfolio.dbo.pizzas as P on OD.pizza_id=P.pizza_id
		   left join PizzaSalesPortfolio.dbo.PizzaTypes as PT on P.pizza_type_id=PT.pizza_type_id
      group by month(date), PT.name) as A
where QuantityRank <4
order by month, Quantity_sold desc

--3) bottom 3 sellers of each month
select month, name, Quantity_sold 
from (select month(date) as month, PT.name, sum(quantity) as Quantity_sold, rank() over (partition by month(date) order by sum(quantity) desc) as QuantityRank
	  from PizzaSalesPortfolio.dbo.Orders as O left join PizzaSalesPortfolio.dbo.OrderDetails as OD on O.order_id=OD.order_id 
		   left join PizzaSalesPortfolio.dbo.pizzas as P on OD.pizza_id=P.pizza_id
		   left join PizzaSalesPortfolio.dbo.PizzaTypes as PT on P.pizza_type_id=PT.pizza_type_id
	  group by month(date), PT.name) as A
where QuantityRank >29
order by month, Quantity_sold desc

--4) top 3 sellers of each Day of week
set datefirst 1

select day_of_week, name, Quantity_sold, Quantity_rank 
from (select datepart(dw,date) as dn, datename(dw,date) day_of_week, PT.name, sum(quantity) as Quantity_sold,
			 rank() over (partition by datename(dw,date) order by sum(quantity) desc) as Quantity_rank
	  from PizzaSalesPortfolio.dbo.Orders as O left join PizzaSalesPortfolio.dbo.OrderDetails as OD on O.order_id=OD.order_id 
	       left join PizzaSalesPortfolio.dbo.pizzas as P on OD.pizza_id=P.pizza_id
		   left join PizzaSalesPortfolio.dbo.PizzaTypes as PT on P.pizza_type_id=PT.pizza_type_id
	  group by datename(dw,date), datepart(dw,date), PT.name) as A
where Quantity_rank < 4
order by dn

--5) top 3 sellers of each hour of day
select hour, name, Quantity_sold, Quantity_rank 
from (select datepart(hour, time) as hour, PT.name, sum(quantity) as Quantity_sold,
             rank() over (partition by datepart(hour,time) order by sum(quantity) desc) as Quantity_rank
      from PizzaSalesPortfolio.dbo.Orders as O left join PizzaSalesPortfolio.dbo.OrderDetails as OD on O.order_id=OD.order_id 
           left join PizzaSalesPortfolio.dbo.pizzas as P on OD.pizza_id=P.pizza_id
	   	   left join PizzaSalesPortfolio.dbo.PizzaTypes as PT on P.pizza_type_id=PT.pizza_type_id
	  group by datepart(hour,time), PT.name) as A
where Quantity_rank<4
order by hour, Quantity_sold desc


--<How much money was made?>
--1) Yearly Revenue
select sum(revenue) as Total_revenue 
from(select O.*, OD.pizza_id, OD.quantity, OD.order_details_id, P.pizza_type_id, P.price, P.size, quantity*price as revenue
	 from PizzaSalesPortfolio.dbo.Orders as O left join PizzaSalesPortfolio.dbo.OrderDetails as OD on O.order_id=OD.order_id 
		  left join PizzaSalesPortfolio.dbo.pizzas as P on OD.pizza_id=P.pizza_id) as A

--2) Monthly Revenue
select month(date) as Month, sum(revenue) as Total_revenue 
from(select O.*, OD.pizza_id, OD.quantity, OD.order_details_id, P.pizza_type_id, P.price, P.size, quantity*price as revenue
	 from PizzaSalesPortfolio.dbo.Orders as O left join PizzaSalesPortfolio.dbo.OrderDetails as OD on O.order_id=OD.order_id 
		  left join PizzaSalesPortfolio.dbo.pizzas as P on OD.pizza_id=P.pizza_id) as A
group by month(date)
order by month(date)

--3) Weekly Revenue (assuming weeks start from Monday)
select Beginning_of_week_Mon, sum(revenue) as Total_revenue 
from (select O.date, datepart(week, date) as Week, 
			 CAST(DATEADD(week, DATEDIFF(week, '20141230', datediff(day,1,date)),'20141229') as date) as Beginning_of_week_Mon, 
		     O.order_id, O.time, OD.pizza_id, OD.quantity, OD.order_details_id, P.pizza_type_id, P.price, P.size, 
			 quantity*price as revenue
	  from PizzaSalesPortfolio.dbo.Orders as O left join PizzaSalesPortfolio.dbo.OrderDetails as OD on O.order_id=OD.order_id 
           left join PizzaSalesPortfolio.dbo.pizzas as P on OD.pizza_id=P.pizza_id) as A
group by Beginning_of_week_Mon
order by Beginning_of_week_Mon

--4) Daily Revenue
select date, sum(revenue) as Total_revenue 
from (select O.*, OD.pizza_id, OD.quantity, OD.order_details_id, P.pizza_type_id, P.price, P.size, quantity*price as revenue
	  from PizzaSalesPortfolio.dbo.Orders as O left join PizzaSalesPortfolio.dbo.OrderDetails as OD on O.order_id=OD.order_id 
		   left join PizzaSalesPortfolio.dbo.pizzas as P on OD.pizza_id=P.pizza_id) as A
group by date
order by date

--5) Total(of year 2015) revenue by Pizza Type
select name, sum(revenue) as Total_revenue 
from(select O.*, OD.pizza_id, OD.quantity, OD.order_details_id, P.pizza_type_id, P.price, P.size, PT.name, quantity*price as revenue
	 from PizzaSalesPortfolio.dbo.Orders as O left join PizzaSalesPortfolio.dbo.OrderDetails as OD on O.order_id=OD.order_id 
	      left join PizzaSalesPortfolio.dbo.pizzas as P on OD.pizza_id=P.pizza_id
	      left join PizzaSalesPortfolio.dbo.PizzaTypes as PT on P.pizza_type_id=PT.pizza_type_id) as A
group by name
order by Total_revenue desc

--6) Monthly Revenue by Pizza Type
select month(date) as Month, name, sum(revenue) as Total_revenue 
from(select O.*, OD.pizza_id, OD.quantity, OD.order_details_id, P.pizza_type_id, P.price, P.size, PT.name, quantity*price as revenue
	 from PizzaSalesPortfolio.dbo.Orders as O left join PizzaSalesPortfolio.dbo.OrderDetails as OD on O.order_id=OD.order_id 
	 left join PizzaSalesPortfolio.dbo.pizzas as P on OD.pizza_id=P.pizza_id
	 left join PizzaSalesPortfolio.dbo.PizzaTypes as PT on P.pizza_type_id=PT.pizza_type_id) as A
group by month(date), name
order by month(date), Total_revenue desc

--7) Monthly Revenue by Pizza Type (Pivot Table)
WITH myTable as
(select month(date) as Month, Name, sum(revenue) as Total_revenue 
 from(select O.*, OD.pizza_id, OD.quantity, OD.order_details_id, P.pizza_type_id, P.price, P.size, substring(name, 5, len(name)-10) as Name, 
			 quantity*price as revenue
	  from PizzaSalesPortfolio.dbo.Orders as O left join PizzaSalesPortfolio.dbo.OrderDetails as OD on O.order_id=OD.order_id 
	  left join PizzaSalesPortfolio.dbo.pizzas as P on OD.pizza_id=P.pizza_id
	  left join PizzaSalesPortfolio.dbo.PizzaTypes as PT on P.pizza_type_id=PT.pizza_type_id) as A
 group by month(date), Name)
SELECT * from myTable
PIVOT(sum(Total_revenue) for Name in ([Barbecue Chicken],[Big Meat],[Brie Carre],[Calabrese],[California Chicken],[Chicken Alfredo],[Chicken Pesto],[Classic Deluxe],[Five Cheese],[Four Cheese],
[Greek],[Green Garden],[Hawaiian],[Italian Capocollo],[Italian Supreme],[Italian Vegetables],[Mediterranean],[Mexicana],[Napolitana],[Pepper Salami],[Pepperoni],
[Pepperoni, Mushroom, and Peppers],[Prosciutto and Arugula],[Sicilian],[Soppressata],[Southwest Chicken],[Spicy Italian],[Spinach and Feta],[Spinach Pesto],
[Spinach Supreme],[Thai Chicken],[Vegetables + Vegetables])) as MyPivot
order by Month


--8) Weekly Revenue by Pizza Type
select Beginning_of_week_Mon, Name, sum(revenue) as Total_revenue 
from (select O.date, datepart(week, date) as Week, 
			 CAST(DATEADD(week, DATEDIFF(week, '20141230', datediff(day,1,date)),'20141229') as date) as Beginning_of_week_Mon, 
		     O.order_id, O.time, OD.pizza_id, OD.quantity, OD.order_details_id, P.pizza_type_id, P.price, P.size, substring(name, 5, len(PT.name)-10) as Name, 
			 quantity*price as revenue
	  from PizzaSalesPortfolio.dbo.Orders as O left join PizzaSalesPortfolio.dbo.OrderDetails as OD on O.order_id=OD.order_id 
	       left join PizzaSalesPortfolio.dbo.pizzas as P on OD.pizza_id=P.pizza_id
		   left join PizzaSalesPortfolio.dbo.PizzaTypes as PT on P.pizza_type_id=PT.pizza_type_id) as A
group by Beginning_of_week_Mon, Name
order by Beginning_of_week_Mon, Total_revenue desc;

--9) Weekly Revenue by Pizza Type(Pivot Table)
WITH myTable as
(select Beginning_of_week_Mon, Name, sum(revenue) as Total_revenue 
 from (select O.date, datepart(week, date) as Week, 
			  CAST(DATEADD(week, DATEDIFF(week, '20141230', datediff(day,1,date)),'20141229') as date) as Beginning_of_week_Mon, 
		      O.order_id, O.time, OD.pizza_id, OD.quantity, OD.order_details_id, P.pizza_type_id, P.price, P.size, substring(name, 5, len(PT.name)-10) as Name, 
			  quantity*price as revenue
 from PizzaSalesPortfolio.dbo.Orders as O left join PizzaSalesPortfolio.dbo.OrderDetails as OD on O.order_id=OD.order_id 
	  left join PizzaSalesPortfolio.dbo.pizzas as P on OD.pizza_id=P.pizza_id
	  left join PizzaSalesPortfolio.dbo.PizzaTypes as PT on P.pizza_type_id=PT.pizza_type_id) as A
group by Beginning_of_week_Mon, Name)
SELECT * from myTable
PIVOT(sum(Total_revenue) for Name in ([Barbecue Chicken],[Big Meat],[Brie Carre],[Calabrese],[California Chicken],[Chicken Alfredo],[Chicken Pesto],[Classic Deluxe],[Five Cheese],[Four Cheese],
[Greek],[Green Garden],[Hawaiian],[Italian Capocollo],[Italian Supreme],[Italian Vegetables],[Mediterranean],[Mexicana],[Napolitana],[Pepper Salami],[Pepperoni],
[Pepperoni, Mushroom, and Peppers],[Prosciutto and Arugula],[Sicilian],[Soppressata],[Southwest Chicken],[Spicy Italian],[Spinach and Feta],[Spinach Pesto],
[Spinach Supreme],[Thai Chicken],[Vegetables + Vegetables])) as MyPivot
order by Beginning_of_week_Mon

--10) Daily Revenue by Pizza Type (Note: this doesn't include NULL. i,e., no revenue from brie_carre pizza on 2015-01-01, so there's no such row)
select date, Name, sum(revenue) as Total_revenue 
from (select O.*, OD.pizza_id, OD.quantity, OD.order_details_id, P.pizza_type_id, P.price, P.size, substring(name, 5, len(PT.name)-10) as Name, quantity*price as revenue
	  from PizzaSalesPortfolio.dbo.Orders as O left join PizzaSalesPortfolio.dbo.OrderDetails as OD on O.order_id=OD.order_id 
		   left join PizzaSalesPortfolio.dbo.pizzas as P on OD.pizza_id=P.pizza_id
		   left join PizzaSalesPortfolio.dbo.PizzaTypes as PT on P.pizza_type_id=PT.pizza_type_id) as A
group by date, Name
order by date, Total_revenue desc;

--11) Daily Revenue by Pizza Type (Pivot Table); Unlike table right above, this shows every pizza type (even with 0 revenue) as we specified column names.
WITH myTable as
(select date, Name, sum(revenue) as Total_revenue from
	(select O.*, OD.pizza_id, OD.quantity, OD.order_details_id, P.pizza_type_id, P.price, P.size, substring(name, 5, len(PT.name)-10) as Name, quantity*price as revenue
	 from PizzaSalesPortfolio.dbo.Orders as O left join PizzaSalesPortfolio.dbo.OrderDetails as OD on O.order_id=OD.order_id 
	 left join PizzaSalesPortfolio.dbo.pizzas as P on OD.pizza_id=P.pizza_id
	 left join PizzaSalesPortfolio.dbo.PizzaTypes as PT on P.pizza_type_id=PT.pizza_type_id) as A
	 group by date, Name)
SELECT * from myTable
PIVOT(sum(Total_revenue) for Name in ([Barbecue Chicken],[Big Meat],[Brie Carre],[Calabrese],[California Chicken],[Chicken Alfredo],[Chicken Pesto],[Classic Deluxe],[Five Cheese],[Four Cheese],
[Greek],[Green Garden],[Hawaiian],[Italian Capocollo],[Italian Supreme],[Italian Vegetables],[Mediterranean],[Mexicana],[Napolitana],[Pepper Salami],[Pepperoni],
[Pepperoni, Mushroom, and Peppers],[Prosciutto and Arugula],[Sicilian],[Soppressata],[Southwest Chicken],[Spicy Italian],[Spinach and Feta],[Spinach Pesto],
[Spinach Supreme],[Thai Chicken],[Vegetables + Vegetables])) as MyPivot
order by date

--<What are Popular Ingredients>
select * from PizzaSalesPortfolio.dbo.PizzaTypes order by pizza_type_id

--First, separate each ingredient from the list of ingredients
select pizza_type_id, name, trim(value) as Ingredient from PizzaSalesPortfolio.dbo.PizzaTypes
cross apply string_split(ingredients, ',')

--Second, get a list of ALL ingredients
select distinct trim(value) as Ingredient from PizzaSalesPortfolio.dbo.PizzaTypes
cross apply string_split(ingredients, ',')
order by Ingredient

--Third, assign Ingredient_category for each ingredient
select pizza_type_id, name, trim(value) as Ingredient, 
	case when trim(value) like '%Sauce%' then 'Sauce' when trim(value) like '%Cheese%' then 'Cheese' else 'Topping' end as Ingredient_category
from PizzaSalesPortfolio.dbo.PizzaTypes
cross apply string_split(ingredients, ',')

--Fourth, fix a few details below:
--1) Every pizza has Mozzarella Cheese even if not specified.  
--2) Every pizza include Tomato Sauce, unless another sauce is specified.
--3) Artichoke and Artichokes have to be just Artichoke.
--Make these revision and create a new table dbo.PizzaTypesRevised.
select pizza_type_id, name, category, replace(trim(value), 'Artichokes','Artichoke') as Ingredient, 
	  case when trim(value) like '%Sauce%' then 'Sauce' when trim(value) like '%Cheese%' then 'Cheese' else 'Topping' end as Ingredient_category
into PizzaSalesPortfolio.dbo.PizzaTypesRevised
from PizzaSalesPortfolio.dbo.PizzaTypes
cross apply string_split(ingredients, ',')
UNION ALL
select pizza_type_id, name, category,'Mozzarella Cheese', 'Cheese' from PizzaSalesPortfolio.dbo.PizzaTypes
UNION ALL
select pizza_type_id, name, category,'Tomatoe Sauce','Sauce' from PizzaSalesPortfolio.dbo.PizzaTypes 
where pizza_type_id not in
	(select pizza_type_id from PizzaSalesPortfolio.dbo.PizzaTypes
	 cross apply string_split(ingredients, ',') where trim(value) like '%Sauce')
order by pizza_type_id;

select * from PizzaSalesPortfolio.dbo.PizzaTypesRevised 

--Fifth, join Quantity_Sold of Each Pizza sold and its Ingredient Info
select QS.*, PTR.name, PTR.category, PTR.Ingredient,PTR.Ingredient_category 
from (select pizza_type_id, sum(quantity) as Quantity_sold
	  from PizzaSalesPortfolio.dbo.Orders as O left join PizzaSalesPortfolio.dbo.OrderDetails as OD on O.order_id=OD.order_id 
	  left join PizzaSalesPortfolio.dbo.pizzas as P on OD.pizza_id=P.pizza_id
      group by pizza_type_id) as QS 
join PizzaSalesPortfolio.dbo.PizzaTypesRevised PTR on QS.pizza_type_id=PTR.pizza_type_id
order by QS.pizza_type_id

--Sixth, with the Joined table, show Quantity sold for each ingredient in different category
WITH myTable AS 
(select QS.*, PTR.name, PTR.category, PTR.Ingredient,PTR.Ingredient_category 
 from (select pizza_type_id, sum(quantity) as Quantity_sold
	   from PizzaSalesPortfolio.dbo.Orders as O left join PizzaSalesPortfolio.dbo.OrderDetails as OD on O.order_id=OD.order_id 
	   left join PizzaSalesPortfolio.dbo.pizzas as P on OD.pizza_id=P.pizza_id
       group by pizza_type_id) as QS 
      join PizzaSalesPortfolio.dbo.PizzaTypesRevised PTR on QS.pizza_type_id=PTR.pizza_type_id) 
SELECT Ingredient_category, Ingredient, sum(Quantity_sold) Times_sold, rank() over (partition by Ingredient_category order by sum(Quantity_sold) desc) as Rank
from myTable 
group by Ingredient_category, Ingredient
order by Ingredient_category, sum(Quantity_sold) desc

