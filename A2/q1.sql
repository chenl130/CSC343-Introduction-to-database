-- Months.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q1 CASCADE;

CREATE TABLE q1(
    client_id INTEGER,
    email VARCHAR(30),
    months INTEGER
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;
DROP VIEW IF EXISTS users CASCADE;
DROP VIEW IF EXISTS user_and_month CASCADE;
DROP VIEW IF EXISTS inter CASCADE;
DROP VIEW IF EXISTS outp CASCADE;


-- Define views for your intermediate steps here:
create view users as
select client_id, email, 0 as mon from Client;


create view user_and_month as
select distinct client_id, to_char(request.datetime, 'YYYY:MM') mon
from Request, dropoff
where request.request_id = dropoff.request_id;

create view inter as 
select users.client_id, users.email, count(user_and_month.mon)
from users, user_and_month
where users.client_id = user_and_month.client_id
group by users.client_id, users.email;

create view outp as
(select * from users)
union
(select * from inter);

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q1
select client_id, email, sum(mon)
from outp
group by client_id, email;
