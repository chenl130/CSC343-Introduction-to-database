-- Rainmakers.  
  
-- You must not change the next 2 lines or the table definition.  
SET SEARCH_PATH TO uber, public;  
DROP TABLE IF EXISTS q10 CASCADE;  
  
CREATE TABLE q10(  
    driver_id INTEGER,  
    month CHAR(2),  
    mileage_2020 FLOAT,  
    billings_2020 FLOAT,  
    mileage_2021 FLOAT,  
    billings_2021 FLOAT,  
    mileage_increase FLOAT,  
    billings_increase FLOAT  
);  
  
-- Do this for each of the views that define your intermediate steps.    
-- (But give them better names!) The IF EXISTS avoids generating an error   
-- the first time this file is imported.  
DROP VIEW IF EXISTS CfDistance1 CASCADE;  
DROP VIEW IF EXISTS CfDistance CASCADE;  
DROP VIEW IF EXISTS Milandbill CASCADE;  
DROP VIEW IF EXISTS Months CASCADE;  
DROP VIEW IF EXISTS Years CASCADE;  
DROP VIEW IF EXISTS AllDriveYearMonth CASCADE;  
DROP VIEW IF EXISTS NoRequestDriver CASCADE;  
DROP VIEW IF EXISTS NoRequestDriverMb CASCADE;  
DROP VIEW IF EXISTS AllDriverMb CASCADE;  
DROP VIEW IF EXISTS Outp CASCADE;  
  
-- List each completed request's driver, year and month it happened as well as distance and bill  
CREATE VIEW CfDistance1 AS  
SELECT Request.request_id, ClockedIn.driver_id,   
CAST(DATE_PART('year', Request.datetime) AS CHAR(4))as year,  
to_char(DATE_PART('month', Request.datetime), '09') as month,  
source <@> destination AS distance  
FROM Request   
JOIN Dispatch ON Request.request_id = Dispatch.request_id  
JOIN Dropoff ON Request.request_id = Dropoff.request_id  
JOIN ClockedIn ON Dispatch.shift_id = ClockedIn.shift_id;  
  
  
CREATE VIEW CfDistance AS  
SELECT CfDistance1.*,   
CASE WHEN amount IS NULL THEN 0   
ELSE amount   
END AS bill  
FROM CfDistance1   
LEFT JOIN Billed ON CfDistance1.request_id = Billed.request_id;  
  
-- relation of a driver's mileage and billing per month in 2020 and 2021  
CREATE VIEW Milandbill AS  
SELECT driver_id, month, year,  
sum(distance) AS mileage,   
sum(bill) AS billing  
FROM CfDistance  
WHERE year = '2020' or year = '2021'  
GROUP BY driver_id, year, month;  
  
CREATE VIEW Months AS  
SELECT to_char(generate_series(1, 12), '09') AS mo;  
  
CREATE VIEW Years AS  
SELECT CAST(generate_series(2020, 2021) AS CHAR(4)) AS yr;  
  
CREATE VIEW AllDriveYearMonth AS  
SELECT driver_id, mo AS month, yr AS year  
FROM Driver, Months, Years;  
  
CREATE VIEW NoRequestDriver AS  
(SELECT driver_id, month, year FROM AllDriveYearMonth)  
EXCEPT   
(SELECT driver_id, month, year FROM Milandbill);  
  
CREATE VIEW NoRequestDriverMb AS  
SELECT driver_id, month, year,  
0 AS mileage,   
0 AS billing  
FROM NoRequestDriver;  
  
CREATE VIEW AllDriverMb AS  
(SELECT * FROM NoRequestDriverMb)  
UNION  
(SELECT * FROM Milandbill);  
  
CREATE VIEW Outp AS  
SELECT M1.driver_id, M1.month,  
M1.mileage AS mileage_2020,  
M1.billing AS billings_2020,  
M2.mileage AS mileage_2021,  
M2.billing AS billings_2022,  
M2.mileage - M1.mileage AS mileage_increase,  
M2.billing - M1.billing AS billing_increase  
FROM AllDriverMb M1, AllDriverMb M2  
WHERE M1.driver_id = M2.driver_id  
AND M1.month = M2.month   
AND M1.year < M2.year;  
  
-- Your query that answers the question goes below the "insert into" line:  
INSERT INTO q10  
SELECT driver_id,   
right(month, 2),  
mileage_2020,  
billings_2020,  
mileage_2021,  
billings_2022,  
mileage_increase,  
billing_increase FROM Outp; 