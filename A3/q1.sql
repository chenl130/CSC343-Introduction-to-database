SET search_path TO ticketchema;

DROP VIEW IF EXISTS transaction_intermediate CASCADE;
DROP VIEW IF EXISTS all_tickets_sold CASCADE;
DROP VIEW IF EXISTS total_seat CASCADE;
DROP VIEW IF EXISTS final_all_tickets_sold CASCADE;
DROP VIEW IF EXISTS q1 CASCADE;

-- Intermediate transaction table that contains concert information and ticket price
CREATE view transaction_intermediate AS
SELECT Concert.concert_id, name, Concert.datetime, venue_id, Transaction.section_id, seat, price
FROM Transaction, Concert, TicketPrice
WHERE Transaction.concert_id = Concert.concert_id
AND Concert.concert_id = TicketPrice.concert_id
AND Transaction.section_id = TicketPrice.section_id;

-- Intermediate view indicating number of tickets sold and total value
CREATE view all_tickets_sold AS
SELECT concert_id, name, datetime, venue_id, count(*) AS sold, sum(price) as value
FROM transaction_intermediate
GROUP BY concert_id, name, datetime, venue_id;

-- number of tickets sold and total value, including ones that have no tickets sold. 
CREATE view final_all_tickets_sold AS
SELECT Concert.concert_id, Concert.name, Concert.datetime, Concert.venue_id, coalesce(sold, 0) AS sold, coalesce(value, 0) AS value
FROM Concert LEFT JOIN all_tickets_sold
ON all_tickets_sold.concert_id = Concert.concert_id
AND all_tickets_sold.name = Concert.name
AND all_tickets_sold.datetime = Concert.datetime
AND all_tickets_sold.venue_id = Concert.venue_id
ORDER BY Concert.concert_id;

-- Intermediate table reporting total number of seats in each venue
CREATE view total_seat AS
SELECT Section.venue_id, count(*) AS total
FROM Section, Seat
Where Section.section_id =  Seat.section_id
GROUP BY Section.venue_id;

-- final results of reporting everything
CREATE view q1 AS
SELECT name, datetime, value, sold::float/total*100 AS percentage
FROM total_seat, final_all_tickets_sold
where total_seat.venue_id = final_all_tickets_sold.venue_id;


select * from q1;
