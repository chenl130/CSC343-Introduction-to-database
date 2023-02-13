SET search_path TO ticketchema;

DROP VIEW IF EXISTS num_ticket CASCADE;
DROP VIEW IF EXISTS q4 CASCADE;

-- Find number of tickets bought by each user
CREATE view num_ticket AS
SELECT Users.username, count(transaction_id) as num
FROM Users LEFT JOIN Transaction 
ON Users.username = Transaction.username
group by Users.username;

-- Find all users with the most tickets perchased
CREATE view q4 AS 
SELECT username
FROM num_ticket
WHERE num >= (SELECT max(num) from num_ticket);

select * from q4;
