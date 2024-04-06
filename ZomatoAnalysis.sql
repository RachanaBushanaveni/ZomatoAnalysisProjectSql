create database zomato;
use zomato;
create table goldusers_signup(userid int ,gold_signup_date DATE);
insert into goldusers_signup values(1,'2017-09-22'),(3,'2017-04-21');

create table users(userid int,signup_date DATE);
insert into users values(1,'2014-09-02'),(2,'2015-01-15'),(3,'2014-04-11');

create table sales(userid int,created_date date, product_id int);
insert into sales values(1,'2017-04-19',2),(3,'2019-12-18',1),(2,'2020-07-20',3),(1,'2019-10-23',2),(1,'2018-03-19',3),(3,'2016-12-20',2),
(1,'2016-11-09',1),(1,'2016-05-20',3),(2,'2017-09-24',1),(1,'2017-03-11',2),(1,'2016-03-11',1),(3,'2016-11-10',1),(3,'2017-12-07',2),
(3,'2016-12-15',2),(2,'2017-11-08',2),(2,'2018-09-10',3);

create table product(product_id int,product_name varchar(11),price int);
insert into product values(1,'p1',980),(2,'p2',870),(3,'p3',330);

select * from goldusers_signup;
select * from product;
select * from users;
select * from sales;


# 1 What is the total amount each customer spent on zomato?

select userid, sum(price)  as total_amount from sales inner join product on product.product_id=sales.product_id group by userid;

#2 how many days has each customer visited zomato?

select userid, count(distinct created_date) as distinct_days from sales group by userid;

#3 what was the first product purchased by each customer?

SELECT * from(
SELECT * ,rank() over(PARTITION BY userid ORDER BY created_date) rnk from sales) a where rnk=1;

#4 what is the most purchased item on the on the menu and how many times was it purchased by all customers? 

select userid ,COUNT(product_id) cnt  from sales
where product_id= (select product_id from sales GROUP BY product_id order by count(product_id) desc limit 1)
 group by userid;


#5 which item was the most popular for each customer?

SELECT * FROM(
SELECT * , rank() over(PARTITION BY userid order by cnt desc) rnk from
(select userid,product_id,count(product_id) cnt from sales GROUP BY userid,product_id)a)b where rnk=1;


#6 WHICH ITEM WAS PURCHASED FIRST BY THE CUSTOMER AFTER THEY BECAME A MEMBER?

select * from 
(select c.* ,rank() over(PARTITION BY userid ORDER BY created_date) rnk from
(select a.userid, a.created_date,a.product_id , b.gold_signup_date from sales a inner join
 goldusers_signup b on a.userid=b.userid and created_date>=gold_signup_date)c)d where rnk=1 ;
 
#7 WHICH ITEM WAS PURCHASED FIRST BY THE CUSTOMER BECAME A MEMBER?

select * from 
(select c.* ,rank() over(PARTITION BY userid ORDER BY created_date desc ) rnk from
(select a.userid, a.created_date,a.product_id , b.gold_signup_date from sales a inner join
 goldusers_signup b on a.userid=b.userid and created_date<=gold_signup_date)c)d where rnk=1 ;

#8 what is the total orders and amount spent for each member before they became a memer?

select userid , count(created_date) order_purchased ,sum(price)  total_amt_spent from
(select c.* ,d.price from
(select a.userid  , a.created_date,a.product_id , b.gold_signup_date from sales a inner join
 goldusers_signup b on a.userid=b.userid and created_date<=gold_signup_date)c inner join product d on c.product_id=d.product_id)e 
 group by userid ;
 
/*9 1> if buying each product generates points for eg 5rs=2 zomato point and each product has different purchasing points for eg for p1 5rs=1
 zomato point , for p2 10rs=5zomato point and p3 5rs=1 zomato point
 2> calculate points collected by each customers and for which product most points have been given till now */

SELECT userid , sum(total_points)*2.5  total_money_earned from(
SELECT e.*, amt/points total_points from
(select d.* , case when product_id=1 then 5 when product_id=2 then 2 WHEN product_id=3 then 5 else 0 end as points from
(select c.userid, c.product_id, sum(price) amt from 
(SELECT a.*,b.price from sales a inner join product b on  a.product_id=b.product_id)c GROUP BY userid, product_id)d)e)f GROUP BY userid ; 

select * from(
SELECT *, rank() over(ORDER  BY total_points_earned desc ) rnk from(
SELECT product_id , sum(total_points) total_points_earned from(
SELECT e.*, amt/points total_points from
(select d.* , case when product_id=1 then 5 when product_id=2 then 2 WHEN product_id=3 then 5 else 0 end as points from
(select c.userid, c.product_id, sum(price) amt from 
(SELECT a.*,b.price from sales a inner join product b on  a.product_id=b.product_id)c GROUP BY userid, product_id)d)e)f GROUP BY product_id )f)g
 where rnk=1; 


#10 rnk all the transaction of the customers

SELECT* , rank() over (PARTITION BY userid ORDER BY created_date) rnk FROM sales;

#11 rank all the transactions for each member whenever they are a zomato gold member fr every non gold member transaction  mark as na

select e.*, case when rnk=0 THEN 'na' else rnk end as rnkk from(
SELECT c.*, cast((case when gold_signup_date is null then 0 else rank() over(PARTITION BY userid order by created_date desc) end)  as char) as rnk from
(SELECT a.userid, a.created_date ,a.product_id,b.gold_signup_date from sales a left join 
goldusers_signup b on a.userid=b.userid and created_date>= gold_signup_date)c)e; 

