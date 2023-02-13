-- Do drivers improve?

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q4 CASCADE;

CREATE TABLE q4(
    type VARCHAR(9),
    number INTEGER,
    early FLOAT,
    late FLOAT
);

CREATE TABLE temp(
    type VARCHAR(9),
    number INTEGER,
    early FLOAT,
    late FLOAT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS more_than_10_first CASCADE;
DROP VIEW IF EXISTS request_with_rating CASCADE;
DROP VIEW IF EXISTS inter CASCADE;
DROP VIEW IF EXISTS more_than_10_second CASCADE;
DROP VIEW IF EXISTS more_than_10_final CASCADE;
DROP VIEW IF EXISTS fifth CASCADE;
DROP VIEW IF EXISTS calc_late CASCADE;
DROP VIEW IF EXISTS calc_early CASCADE;
DROP VIEW IF EXISTS real_final CASCADE;
DROP VIEW IF EXISTS dede CASCADE;


-- Define views for your intermediate steps here:

-- add rating to request table
create view request_with_rating as
select request.request_id, datetime, rating
from request left join driverrating on request.request_id = driverrating.request_id;

-- find all drivers who have worked 10 or more days
create view more_than_10_first as 
select driver_id, request_with_rating.request_id, date(request_with_rating.datetime) as date, rating
from request_with_rating, dropoff, dispatch, clockedin
where request_with_rating.request_id = dropoff.request_id
and dispatch.request_id = dropoff.request_id
and dispatch.shift_id = clockedin.shift_id
order by driver_id, date(request_with_rating.datetime);

-- filter to have only driver who gave rides 10 times or more, but also add in bool train
create view more_than_10_second as
select more_than_10_first.driver_id, trained
from more_than_10_first left join driver on driver.driver_id = more_than_10_first.driver_id
group by more_than_10_first.driver_id, trained
having count(distinct date) >= 10;

create view more_than_10_third as
select more_than_10_first.driver_id, more_than_10_first.request_id, date, rating, trained
from more_than_10_second, more_than_10_first
where more_than_10_second.driver_id = more_than_10_first.driver_id;

-- make intermediate table
create view inter as
select distinct driver_id as id, date as ddd
from more_than_10_third
order by id, ddd;

-- make stupid find 5th day
create view fifth as
select temp.id as id, temp.ddd as ddd
from (
    (select d5.id, d5.ddd
    from inter d1, inter d2, inter d3, inter d4, inter d5
    where d1.id = d2.id and d2.id = d3.id
    and d3.id = d4.id and d5.id = d4.id and d2.ddd > d1.ddd
    and d3.ddd > d2.ddd and d4.ddd > d3.ddd
    and d5.ddd > d4.ddd)
    except
    (select d6.id, d6.ddd
    from inter d1, inter d2, inter d3, inter d4, inter d5, inter d6
    where d1.id = d2.id and d2.id = d3.id
    and d3.id = d4.id and d5.id = d4.id and d5.id = d6.id
    and d2.ddd > d1.ddd and d3.ddd > d2.ddd and d4.ddd > d3.ddd
    and d5.ddd > d4.ddd and d6.ddd > d5.ddd)
) as temp;


create view more_than_10_final as
select driver_id, request_id, date, rating, trained, 
case when driver_id = id and date <= ddd then 'e'
when driver_id = id and date > ddd then 'l'
end as check_time
from more_than_10_third, fifth
where driver_id = id
order by driver_id, date;

create view calc_early as
select avg(rating) as early, trained
from more_than_10_final
where check_time = 'e'
group by trained;

create view calc_late as
select avg(rating) as late, trained
from more_than_10_final
where check_time = 'l'
group by trained;

create view real_final as
select 
case when more_than_10_final.trained then 'trained'
when not more_than_10_final.trained then 'untrained'
end as type, count(distinct driver_id) as number, early, late
from more_than_10_final, calc_early, calc_late
where more_than_10_final.trained = calc_early.trained and calc_early.trained = calc_late.trained
group by more_than_10_final.trained, early, late;

insert into temp values('trained', 0), ('untrained', 0);
insert into temp 
select * from real_final;



-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q4
select type, sum(number), avg(early), avg(late) 
from temp
group by type;
