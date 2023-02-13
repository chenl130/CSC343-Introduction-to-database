-- Ratings histogram.  
  
-- You must not change the next 2 lines or the table definition.  
SET SEARCH_PATH TO uber, public;  
DROP TABLE IF EXISTS q7 CASCADE;  
  
CREATE TABLE q7(  
    driver_id INTEGER,  
    r5 INTEGER,  
    r4 INTEGER,  
    r3 INTEGER,  
    r2 INTEGER,  
    r1 INTEGER  
);  
  
-- Do this for each of the views that define your intermediate steps.    
-- (But give them better names!) The IF EXISTS avoids generating an error   
-- the first time this file is imported.  
DROP VIEW IF EXISTS RequestRating CASCADE;  
DROP VIEW IF EXISTS HistRating CASCADE;  
DROP VIEW IF EXISTS FiveRate CASCADE;  
DROP VIEW IF EXISTS NoFiveRateDriver CASCADE;  
DROP VIEW IF EXISTS FullFiveRateRecord CASCADE;  
DROP VIEW IF EXISTS FourRate CASCADE;  
DROP VIEW IF EXISTS NoFourRateDriver CASCADE;  
DROP VIEW IF EXISTS FullFourRateRecord CASCADE;  
DROP VIEW IF EXISTS ThreeRate CASCADE;  
DROP VIEW IF EXISTS NoThreeRateDriver CASCADE;  
DROP VIEW IF EXISTS FullThreeRateRecord CASCADE;  
DROP VIEW IF EXISTS TwoRate CASCADE;  
DROP VIEW IF EXISTS NoTwoRateDriver CASCADE;  
DROP VIEW IF EXISTS FullTwoRateRecord CASCADE;  
DROP VIEW IF EXISTS OneRate CASCADE;  
DROP VIEW IF EXISTS NoOneRateDriver CASCADE;  
DROP VIEW IF EXISTS FullOneRateRecord CASCADE;  
DROP VIEW IF EXISTS AllRate CASCADE;  
  
-- Define views for your intermediate steps here:  
  
--request, driver_id, rating they received  
CREATE VIEW RequestRating AS  
SELECT DriverRating.request_id, ClockedIn.driver_id, DriverRating.rating  
FROM DriverRating JOIN Dispatch ON DriverRating.request_id = Dispatch.request_id  
JOIN ClockedIn ON Dispatch.shift_id = ClockedIn.shift_id;  
  
-- driver id, rating, number of this rating   
CREATE VIEW HistRating AS  
SELECT driver_id, rating, COUNT(request_id) num  
FROM RequestRating  
GROUP BY driver_id, rating;  
  
--rating 5 summary:   
CREATE VIEW FiveRate AS  
SELECT driver_id, num AS r5  
FROM HistRating   
WHERE rating = 5;  
  
CREATE VIEW NoFiveRateDriver AS  
(SELECT driver_id, 0 AS r5 FROM Driver)  
EXCEPT   
(SELECT driver_id, 0 AS r5 FROM FiveRate);  
  
CREATE VIEW FullFiveRateRecord AS   
(SELECT * FROM FiveRate)  
UNION  
(SELECT * FROM NoFiveRateDriver);  
  
CREATE VIEW FourRate AS  
SELECT driver_id, num AS r4  
FROM HistRating   
WHERE rating = 4;  
  
CREATE VIEW NoFourRateDriver AS  
(SELECT driver_id, 0 AS r4 FROM Driver)  
EXCEPT   
(SELECT driver_id, 0 AS r4 FROM FourRate);  
  
CREATE VIEW FullFourRateRecord AS   
(SELECT * FROM FourRate)  
UNION  
(SELECT * FROM NoFourRateDriver);  
  
CREATE VIEW ThreeRate AS  
SELECT driver_id, num AS r3  
FROM HistRating   
WHERE rating = 3;  
  
CREATE VIEW NoThreeRateDriver AS  
(SELECT driver_id, 0 AS r3 FROM Driver)  
EXCEPT   
(SELECT driver_id, 0 AS r3 FROM ThreeRate);  
  
CREATE VIEW FullThreeRateRecord AS   
(SELECT * FROM ThreeRate)  
UNION  
(SELECT * FROM NoThreeRateDriver);  
  
CREATE VIEW TwoRate AS  
SELECT driver_id, num AS r2  
FROM HistRating   
WHERE rating = 2;  
  
CREATE VIEW NoTwoRateDriver AS  
(SELECT driver_id, 0 AS r2 FROM Driver)  
EXCEPT   
(SELECT driver_id, 0 AS r2 FROM TwoRate);  
  
CREATE VIEW FullTwoRateRecord AS   
(SELECT * FROM TwoRate)  
UNION  
(SELECT * FROM NoTwoRateDriver);  
  
CREATE VIEW OneRate AS  
SELECT driver_id, num AS r1  
FROM HistRating   
WHERE rating = 1;  
  
CREATE VIEW NoOneRateDriver AS  
(SELECT driver_id, 0 AS r1 FROM Driver)  
EXCEPT   
(SELECT driver_id, 0 AS r1 FROM OneRate);  
  
CREATE VIEW FullOneRateRecord AS   
(SELECT * FROM OneRate)  
UNION  
(SELECT * FROM NoOneRateDriver);  
  
CREATE VIEW AllRate AS  
SELECT FullFiveRateRecord. driver_id,  
r5, r4, r3, r2, r1  
FROM   
FullFiveRateRecord, FullFourRateRecord, FullThreeRateRecord, FullTwoRateRecord, FullOneRateRecord  
WHERE FullFiveRateRecord.driver_id = FullFourRateRecord.driver_id  
AND FullFiveRateRecord.driver_id = FullThreeRateRecord.driver_id  
AND FullFiveRateRecord.driver_id = FullTwoRateRecord.driver_id  
AND FullFiveRateRecord.driver_id = FullOneRateRecord.driver_id;  
  
-- Your query that answers the question goes below the "insert into" line:  
INSERT INTO q7  
SELECT * FROM AllRate; 
