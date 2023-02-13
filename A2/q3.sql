-- Rest bylaw.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q3 CASCADE;

CREATE TABLE q3(
    driver_id INTEGER,
    start DATE,
    driving INTERVAL,
    breaks INTERVAL
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS more_than_12 CASCADE;
DROP VIEW IF EXISTS early_dropoff CASCADE;
DROP VIEW IF EXISTS inter_pickup CASCADE;
DROP VIEW IF EXISTS inter_dropoff CASCADE;
DROP VIEW IF EXISTS late_pickup CASCADE;
DROP VIEW IF EXISTS less_than_15 CASCADE;
DROP VIEW IF EXISTS crime CASCADE;
DROP VIEW IF EXISTS no_break_crime CASCADE;
DROP VIEW IF EXISTS find_all_interval CASCADE;
DROP VIEW IF EXISTS less_than_15_final CASCADE;
DROP VIEW IF EXISTS okk CASCADE;


-- Define views for your intermediate steps here:
-- find all occurance where more than 12 hours of driving
create view more_than_12 as 
select driver_id, DATE(pickup.datetime) as start, sum(dropoff.datetime-pickup.datetime) as driving
from dropoff, pickup, dispatch, clockedin
where dropoff.request_id = pickup.request_id and dropoff.request_id = dispatch.request_id and dispatch.shift_id = clockedin.shift_id
and extract(year from dropoff.datetime) = extract(year from pickup.datetime)
and extract(day from dropoff.datetime) = extract(day from pickup.datetime)
group by driver_id, DATE(pickup.datetime)
having extract(hour from sum(dropoff.datetime-pickup.datetime)) >= 12 and extract(day from sum(dropoff.datetime-pickup.datetime)) = 0;


-- intermediate
create view inter_dropoff as 
select driver_id, dropoff.datetime as dd
from dropoff, dispatch, clockedin
where dropoff.request_id = dispatch.request_id and clockedin.shift_id = dispatch.shift_id;

create view inter_pickup as 
select driver_id, pickup.datetime as pd
from pickup, dispatch, clockedin
where pickup.request_id = dispatch.request_id and clockedin.shift_id = dispatch.shift_id;

-- find earliest dropoff time in a day 
create view early_dropoff as
select driver_id, dd
from inter_dropoff id
where id.dd <= all (select inter_dropoff.dd from inter_dropoff where id.driver_id = inter_dropoff.driver_id and date(id.dd) = date(inter_dropoff.dd));

-- find latest pickup time in a day
create view late_pickup as
select driver_id, pd
from inter_pickup ip
where ip.pd >= all (select inter_pickup.pd from inter_pickup where ip.driver_id = inter_pickup.driver_id and date(ip.pd) = date(inter_pickup.pd));

-- find all days where driver took less than 15 min of break, this table only find the total  break time for driver
create view less_than_15 as
select driver_id, date(early_dropoff.dd) as start, 
case 
when date(early_dropoff.dd) not in (select date(pd) from late_pickup) then early_dropoff.dd - early_dropoff.dd
when early_dropoff.dd >= (select pd from late_pickup where date(late_pickup.pd) = date(early_dropoff.dd) and late_pickup.driver_id = driver_id) then early_dropoff.dd - early_dropoff.dd
else (select pd from late_pickup where date(late_pickup.pd) = date(early_dropoff.dd) and late_pickup.driver_id = driver_id) - early_dropoff.dd  - 
(
    select COALESCE(sum(d.datetime-p.datetime), early_dropoff.dd - early_dropoff.dd)
    from dropoff d, pickup p, clockedin, dispatch 
    where d.request_id = p.request_id 
    and d.request_id = dispatch.request_id
    and clockedin.shift_id = dispatch.shift_id
    and clockedin.driver_id = driver_id
    and date(d.datetime) = date(early_dropoff.dd)
    and date(p.datetime) = date(d.datetime)
    and p.datetime >= early_dropoff.dd
    and d.datetime <= (select pd from late_pickup where date(late_pickup.pd) = date(early_dropoff.dd) and late_pickup.driver_id = driver_id)
)
end as breaks
from early_dropoff
group by driver_id, date(early_dropoff.dd), early_dropoff.dd;


-- find all driver_id and start day where this driver took a break more than 15 mins
create view find_all_interval as
select dropoff.request_id, date(dropoff.datetime) as start, min(pickup.datetime - dropoff.datetime) as break_time
from pickup, dropoff, dispatch d1, dispatch d2, clockedin c1, clockedin c2
where pickup.request_id = d1.request_id and dropoff.request_id = d2.request_id
and d1.shift_id = c1.shift_id and d2.shift_id = c2.shift_id and c1.driver_id = c2.driver_id
and extract(year from pickup.datetime) = extract(year from dropoff.datetime)
and extract(day from pickup.datetime) = extract(day from dropoff.datetime)
and dropoff.datetime <= pickup.datetime
group by dropoff.request_id, date(dropoff.datetime);


-- find all no break BREAK LAW
create view no_break_crime as
select distinct clockedin.driver_id, start
from find_all_interval, dispatch, clockedin
where break_time > make_interval(mins => 15)
and find_all_interval.request_id = dispatch.request_id
and dispatch.shift_id = clockedin.shift_id;



-- final table
create view okk as
select less_than_15.driver_id, less_than_15.start, breaks
from less_than_15, no_break_crime
where less_than_15.driver_id = no_break_crime.driver_id
and less_than_15.start = no_break_crime.start;


create view less_than_15_final as
(select * from less_than_15)
except
(select * from okk);


-- find all days of CRIME
create view crime as
select less_than_15_final.driver_id as driver_id, less_than_15_final.start as start, driving, breaks
from less_than_15_final, more_than_12
where less_than_15_final.driver_id = more_than_12.driver_id 
and less_than_15_final.start = more_than_12.start;



-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q3
select d1.driver_id, d1.start, d1.driving + d2.driving + d3.driving as driving, d1.breaks + d2.breaks + d3.breaks as breaks
from crime d1, crime d2, crime d3
where d1.driver_id = d2.driver_id and d2.driver_id = d3.driver_id 
and d2.start - d1.start = 1
and d3.start - d2.start = 1;