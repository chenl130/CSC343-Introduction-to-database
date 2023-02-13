SET search_path TO ticketchema;

DROP VIEW IF EXISTS q2 CASCADE;

-- Find number of venues owned by each owner
CREATE view q2 AS 
SELECT Owner.name, Owner.phone, count(venue_id) as num
FROM Owner LEFT JOIN Venue on Venue.owner_id = Owner.owner_id
GROUP BY Owner.name, Owner.phone;

select * from q2;
