-- Lure them back.
-- DONE

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q2 CASCADE;

CREATE TABLE q2(
    client_id INTEGER,
    name VARCHAR(41),
  	email VARCHAR(30),
  	billed FLOAT,
  	decline INTEGER
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS id_year_cost CASCADE;
DROP VIEW IF EXISTS id_before_2020_expensive CASCADE;
DROP VIEW IF EXISTS id_2020 CASCADE;
DROP VIEW IF EXISTS id_2021 CASCADE;
DROP VIEW IF EXISTS id_2021_less CASCADE;
DROP VIEW IF EXISTS id_2021_union CASCADE;
DROP VIEW IF EXISTS id_2021_zero CASCADE;
DROP VIEW IF EXISTS final_output CASCADE;


-- Define views for your intermediate steps here:
create view id_year_cost as
select client_id, Billed.request_id as request_id, extract(year from request.datetime) as year, amount
from Billed, Request, dropoff
where Billed.request_id = Request.request_id and dropoff.request_id = request.request_id;

create view id_before_2020_expensive as 
select id_year_cost.client_id, sum(amount) as billed 
from id_year_cost
where year < 2020
group by id_year_cost.client_id
having sum(amount) >= 500;

-- create all rides 
create view all_rides as 
select dropoff.request_id, request.client_id, extract(year from request.datetime) as year
from dropoff, request
where dropoff.request_id = request.request_id;


create view id_2020 as 
select client_id, count(request_id) as num2020
from all_rides
where year = 2020
group by client_id
having count(request_id) <= 10;

-- need to consider if client never took a ride in 2021
create view id_2021 as
select client_id, count(request_id) as num2021
from all_rides
where year = 2021
group by client_id;

-- also consider never take a ride in 2021, but between 1 and 10 rides in 2020
create view id_2021_union as
(select * from id_2021)
union
(select client_id, 0 as num2021 from id_2020);

-- now have table of all 2021 clients, including 0 rides.
create view id_2021_zero as
select client_id, sum(num2021) as num2021
from id_2021_union
group by client_id;


create view id_2021_less as
select id_2020.client_id, num2021-num2020 as decline
from id_2020, id_2021_zero
where id_2020.client_id = id_2021_zero.client_id and num2020 > num2021;


create view final_output as 
select id_before_2020_expensive.client_id, billed, decline
from id_2021_less, id_before_2020_expensive
where id_before_2020_expensive.client_id = id_2021_less.client_id;



-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q2
select Client.client_id, firstname || ' ' || surname as name, email, billed, decline
from Client, final_output
where Client.client_id = final_output.client_id;