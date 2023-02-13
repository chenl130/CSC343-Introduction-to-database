-- Frequent riders.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q6 CASCADE;

CREATE TABLE q6(
    client_id INTEGER,
    year CHAR(4),
    rides INTEGER
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS everything CASCADE;
DROP VIEW IF EXISTS zeros CASCADE;
DROP VIEW IF EXISTS zeros_update CASCADE;
DROP VIEW IF EXISTS big_table CASCADE;
DROP VIEW IF EXISTS first_level CASCADE;
DROP VIEW IF EXISTS second_level CASCADE;
DROP VIEW IF EXISTS third_level CASCADE;
DROP VIEW IF EXISTS after_first CASCADE;
DROP VIEW IF EXISTS after_second CASCADE;
DROP VIEW IF EXISTS after_third CASCADE;
DROP VIEW IF EXISTS look_up_table CASCADE;

-- Define views for your intermediate steps here:
create view everything as 
select client_id, extract(year from request.datetime) as year, count(request.request_id) as rides
from dropoff, request
where dropoff.request_id = request.request_id
group by client_id, year;


create view zeros as
select client.client_id, extract(year from request.datetime) as year, 0 as rides
from request, client
group by client.client_id, year;

create view zeros_update as
(select * from everything)
union
(select * from zeros);

create view big_table as
select client_id, year, sum(rides) as rides
from zeros_update
group by client_id, year;


create view first_level as 
select year, max(rides) as max, min(rides) as min
from big_table
group by year;

create view after_first as
select client_id, big_table.year, big_table.rides
from big_table, first_level
where rides <> max and rides <> min and big_table.year = first_level.year;


create view second_level as 
select year, max(rides) as max, min(rides) as min
from after_first
group by year;

create view after_second as
select client_id, after_first.year, after_first.rides
from after_first, second_level
where rides <> max and rides <> min and after_first.year = second_level.year;


create view third_level as 
select year, max(rides) as max, min(rides) as min
from after_second
group by year;


create view look_up_table as
(select * from first_level)
union
(select * from second_level)
union 
(select * from third_level);




-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q6
select distinct big_table.client_id, big_table.year, big_table.rides 
from big_table left join look_up_table on big_table.year = look_up_table.year
where big_table.rides = look_up_table.max or big_table.rides = look_up_table.min;
