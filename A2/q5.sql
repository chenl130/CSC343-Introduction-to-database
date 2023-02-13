-- Bigger and smaller spenders.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q5 CASCADE;

CREATE TABLE q5(
    client_id INTEGER,
    month VARCHAR(7),
    total FLOAT,
    comparison VARCHAR(30)
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS all_months CASCADE;
DROP VIEW IF EXISTS client_billed CASCADE;
DROP VIEW IF EXISTS client_billed_with_avg CASCADE;
DROP VIEW IF EXISTS only_id CASCADE;
DROP VIEW IF EXISTS empty_table CASCADE;
DROP VIEW IF EXISTS final_table CASCADE;
DROP VIEW IF EXISTS lastlast CASCADE;


-- Define views for your intermediate steps here:
create view all_months as 
select 
case
when extract(month from datetime) < 10 then extract(year from datetime) || ' 0' || extract(month from datetime)
when extract(month from datetime) >= 10 then extract(year from datetime) || ' ' || extract(month from datetime)
end as month, avg(amount)
from billed, request
where billed.request_id = request.request_id
group by month;


create view client_billed as
select client_id, sum(amount) as total, 
case
when extract(month from datetime) < 10 then extract(year from datetime) || ' 0' || extract(month from datetime)
when extract(month from datetime) >= 10 then extract(year from datetime) || ' ' || extract(month from datetime)
end as client_month
from billed, request
where billed.request_id = request.request_id
group by client_id, client_month;


create view client_billed_with_avg as
select client_id, client_month as month, total, avg
from client_billed, all_months
where client_month = month;

create view only_id as
select distinct client_id
from client;


create view empty_table as
select client_id, month, 0 as total, avg
from only_id, all_months;


create view final_table as
(select * from empty_table)
union
(select * from client_billed_with_avg);

create view lastlast as
select client_id, month, sum(total) as total, avg
from final_table
group by client_id, month, avg;


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q5
select client_id, month, total, 
case when total < avg then 'below'
when total >= avg then 'at or above'
end as comparison
from lastlast;
