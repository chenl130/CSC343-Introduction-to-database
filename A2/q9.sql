-- Consistent raters.  
  
-- You must not change the next 2 lines or the table definition.  
SET SEARCH_PATH TO uber, public;  
DROP TABLE IF EXISTS q9 CASCADE;  
  
CREATE TABLE q9(  
    client_id INTEGER,  
    email VARCHAR(30)  
);  
  
-- Do this for each of the views that define your intermediate steps.    
-- (But give them better names!) The IF EXISTS avoids generating an error   
-- the first time this file is imported.  
DROP VIEW IF EXISTS RatedClient CASCADE;  
DROP VIEW IF EXISTS RatedClientDriver CASCADE;  
DROP VIEW IF EXISTS ClientDriverEachRide CASCADE;  
DROP VIEW IF EXISTS NotAllRated CASCADE;  
DROP VIEW IF EXISTS AllRatedClient CASCADE;  
DROP VIEW IF EXISTS Outp CASCADE;  
  
  
-- Define views for your intermediate steps here:  
  
-- list of requests that are rated by clients  
CREATE VIEW RatedClient AS   
SELECT Request.request_id, Request.client_id  
FROM Request JOIN DriverRating ON  
Request.request_id = DriverRating.request_id;  
  
-- list including drivers' info of these rides that are rated by clients  
CREATE VIEW RatedClientDriver AS   
SELECT RatedClient.request_id, RatedClient.client_id, ClockedIn.driver_id  
FROM RatedClient JOIN Dispatch ON   
RatedClient.request_id = Dispatch.request_id  
JOIN ClockedIn ON  
Dispatch.shift_id = ClockedIn.shift_id;  
-- request, client, driver  
  
  
-- list of all rides' clients and driver info  
CREATE VIEW ClientDriverEachRide AS  
SELECT Request.request_id, Request.client_id, ClockedIn.driver_id  
FROM Request JOIN Dispatch ON   
Request.request_id = Dispatch.request_id  
JOIN ClockedIn ON  
Dispatch.shift_id = ClockedIn.shift_id;  
-- request, client, driver  
  
-- list of clients and drivers that they take the ride but didn't give rate  
CREATE VIEW NotAllRated AS  
(SELECT client_id, driver_id FROM ClientDriverEachRide)  
EXCEPT   
(SELECT client_id, driver_id FROM RatedClientDriver);  
  
-- client gave every driver a rate:  
CREATE VIEW AllRatedClient AS  
(SELECT client_id FROM Request)  
EXCEPT   
(SELECT client_id FROM NotAllRated);  
  
CREATE VIEW Outp AS  
SELECT AllRatedClient.client_id, Client.email  
FROM AllRatedClient JOIN Client  
ON AllRatedClient.client_id = Client.client_id;  
  
  
-- Your query that answers the question goes below the "insert into" line:  
INSERT INTO q9  
SELECT client_id, email FROM Outp; 