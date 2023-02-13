-- Scratching backs?  
  
-- You must not change the next 2 lines or the table definition.  
SET SEARCH_PATH TO uber, public;  
DROP TABLE IF EXISTS q8 CASCADE;  
  
CREATE TABLE q8(  
    client_id INTEGER,  
    reciprocals INTEGER,  
    difference FLOAT  
);  
  
-- Do this for each of the views that define your intermediate steps.    
-- (But give them better names!) The IF EXISTS avoids generating an error   
-- the first time this file is imported.  
DROP VIEW IF EXISTS RequestRatedbyClient CASCADE;  
DROP VIEW IF EXISTS RequestRatedbyDriver CASCADE;  
DROP VIEW IF EXISTS Reciprocals CASCADE;  
DROP VIEW IF EXISTS AveragedReciprocals CASCADE;  
  
-- Define views for your intermediate steps here:  
  
-- request_id, client_id, rating (rating gave by driver)  
CREATE VIEW RequestRatedbyDriver AS  
SELECT ClientRating.request_id, Request.client_id, ClientRating.rating  
FROM ClientRating JOIN Request ON ClientRating.request_id = Request.request_id;  
  
-- request_id, driver_id, rating (rating gave by client )  
CREATE VIEW RequestRatedbyClient AS  
SELECT DriverRating.request_id, ClockedIn.driver_id, DriverRating.rating  
FROM DriverRating JOIN Dispatch ON DriverRating.request_id = Dispatch.request_id  
JOIN ClockedIn ON Dispatch.shift_id = ClockedIn.shift_id;  
  
CREATE VIEW Reciprocals AS   
SELECT RequestRatedbyDriver.request_id,   
RequestRatedbyDriver.client_id,  
RequestRatedbyDriver.rating AS rating_bydriver,   
RequestRatedbyClient.driver_id,   
RequestRatedbyClient.rating AS rating_byclient,  
RequestRatedbyClient.rating - RequestRatedbyDriver.rating AS rating_perreq  
FROM RequestRatedbyClient, RequestRatedbyDriver  
WHERE RequestRatedbyClient.request_id =  RequestRatedbyDriver.request_id;  
  
CREATE VIEW AveragedReciprocals AS  
SELECT client_id,   
COUNT(request_id) AS reciprocals,  
AVG(rating_perreq) AS difference   
FROM Reciprocals  
GROUP BY client_id;  
  
-- Your query that answers the question goes below the "insert into" line:  
INSERT INTO q8  
SELECT * FROM AveragedReciprocals; 