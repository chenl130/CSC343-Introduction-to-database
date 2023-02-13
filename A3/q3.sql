SET search_path TO ticketchema;

DROP VIEW IF EXISTS total CASCADE;
DROP VIEW IF EXISTS accessible CASCADE;
DROP VIEW IF EXISTS q3 CASCADE;

-- Find the total number of seats
CREATE view total AS
SELECT venue_id, count(*) as total
FROM Seat, Section WHERE Seat.section_id = Section.section_id
GROUP BY venue_id;

-- Find the total number of accessible seats
CREATE view accessible AS
SELECT venue_id, count(*) as accessible
FROM Seat, Section 
WHERE Seat.section_id = Section.section_id
AND accessibility = 't'
GROUP BY venue_id;

-- Find percentage of seats that are accessible in each venue
CREATE view q3 AS 
SELECT Venue.name, Venue.city, Venue.address, coalesce(accessible, 0)::float/total*100 AS percentage
FROM total LEFT JOIN accessible ON total.venue_id = accessible.venue_id
LEFT JOIN Venue ON total.venue_id = Venue.venue_id;

select * from q3;
