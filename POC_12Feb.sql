create table members(
customer_id varchar2(20) primary key,
join_date Date
);

--drop table members;
create table menu(
product_id number(10) primary key,
product_name VARCHAR2(20),
price number(5)
);


create table sales(
customer_id VARCHAR2(20) REFERENCES members(customer_id),
order_date Date,
product_id number(10) references menu(product_id)
);

insert into menu values (1,'sushi',10);
insert into menu values (2,'curry',15);
insert into menu values (3,'ramen',12);

insert into members values ('A','07/01/2021');
insert into members values ('B','09/01/2021');
insert into members values ('C','07/01/2021');

INSERT ALL
INTO SALES VALUES ('A',to_date('2021-01-01','YYYY-MM-DD'),1)
INTO SALES VALUES ('A',to_date('2021-01-01','YYYY-MM-DD'),2)
INTO SALES VALUES ('A',to_date('2021-01-07','YYYY-MM-DD'),2)
INTO SALES VALUES ('A',to_date('2021-01-10','YYYY-MM-DD'),3)
INTO SALES VALUES ('A',to_date('2021-01-11','YYYY-MM-DD'),3)
INTO SALES VALUES ('A',to_date('2021-01-11','YYYY-MM-DD'),3)
INTO SALES VALUES ('B',to_date('2021-01-01','YYYY-MM-DD'),2)
INTO SALES VALUES ('B',to_date('2021-01-02','YYYY-MM-DD'),2)
INTO SALES VALUES ('B',to_date('2021-01-04','YYYY-MM-DD'),1)
INTO SALES VALUES ('B',to_date('2021-01-11','YYYY-MM-DD'),1)
INTO SALES VALUES ('B',to_date('2021-01-16','YYYY-MM-DD'),3)
INTO SALES VALUES ('B',to_date('2021-02-01','YYYY-MM-DD'),3)
INTO SALES VALUES ('C',to_date('2021-01-01','YYYY-MM-DD'),3)
INTO SALES VALUES ('C',to_date('2021-01-01','YYYY-MM-DD'),3)
INTO SALES VALUES ('C',to_date('2021-01-07','YYYY-MM-DD'),3)
select * from DUAL;

select * from menu;

--1) What is the total amount each customer spent at the restaurant? 
select s.customer_id,sum(m.price) as totalSpent from sales s join menu m on s.product_id = m.product_id group by s.customer_id;

--2) How many days has each customer visited the restaurant? 
select t.customer_id,count(totalTimeVisited) as tVisit from
(select customer_id,count(order_date) as totalTimeVisited from sales  group by customer_id,order_date) t group by customer_id 
order by customer_id ;

--3) What was the first item from the menu purchased by each customer? 
 select t.customer_id, m.product_name 
 from (select s.*, dense_rank() over(order by order_date asc) as dnk from sales s)  t join menu m
 on t.product_id = m.product_id
 where t.dnk = 1 order by t.customer_id;
 
--4) What is the most purchased item on the menu and how many times was it purchased by all customers?
select m.product_name, t.cnt from
(select s.product_id,count(s.product_id) as cnt from sales s group by s.product_id order by cnt desc) t join menu m
on t.product_id = m.product_id where rownum = 1;

--5) Which item was the most popular for each customer? 
select * from 
(select t.customer_id,m.product_name,t.cnt,rank() over(partition by customer_id order by customer_id asc, cnt desc) as rnk from
(select customer_id,product_id,count(product_id) cnt from sales group by customer_id,product_id order by customer_id asc,cnt desc) t
join menu m
on t.product_id = m.product_id) where rnk =1;

--6) Which item was purchased first by the customer after they became a member?

select t.customer_id,m.product_name from 
(select s.customer_id,s.product_id,s.order_date,mem.join_date,rank() over(partition by s.customer_id order by s.order_date) as rnk 
from sales s join members mem on s.customer_id = mem.customer_id where s.order_date >= mem.join_date) t join menu m 
on t.product_id = m.product_id where t.rnk= 1;

--7) Which item was purchased just before the customer became a member? 
select t.customer_id,m.product_name from 
(select s.customer_id,s.product_id,s.order_date,mem.join_date,rank() over(partition by s.customer_id order by s.order_date desc) as rnk 
from sales s join members mem on s.customer_id = mem.customer_id where s.order_date < mem.join_date) t join menu m 
on t.product_id = m.product_id where t.rnk= 1;

--8) What is the total items and amount spent for each member before they became a member? 
select t.customer_id,count(m.product_name) as TotalItem, sum(m.price) as amountSpent from 
(select s.customer_id,s.product_id,s.order_date,mem.join_date,rank() over(partition by s.customer_id order by s.order_date desc) as rnk 
from sales s join members mem on s.customer_id = mem.customer_id where s.order_date < mem.join_date) t join menu m 
on t.product_id = m.product_id group by t.customer_id;

--9) If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have? 
select customer_id,sum(pointsEarned) from
(select s.customer_id,
(case m.price 
 when 10 then m.price*20
 else m.price*10
 end
)as pointsEarned
from sales s join menu m
on s.product_id = m.product_id) group by customer_id;

--10) In the first week after a customer joins the program (including their join date) they earn
--2x points on all items, not just sushi - how many points do customer A and B have at the
--end of January? 
select customer_id,sum(totalpoints) as Total from
(select s.customer_id,
(case
when s.order_date between mem.join_date and mem.join_date + 6 then m.price*20
else m.price*10
end
)as totalPoints
from sales s join menu m on s.product_id = m.product_id
join members mem on s.customer_id = mem.customer_id) group by customer_id;

