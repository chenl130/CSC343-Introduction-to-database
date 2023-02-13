-- Could Not: the restriction where every venue must have 
-- at least 10 seats cannot be enforced without using a 
-- cross-table check such as an assertion or a trigger. 

-- Did Not: None

-- Extra constraints: None

-- Assumption: Every venue has at least 10 seats. Each 
-- seat in any concert at any venue is sold to at most 1 user. 


drop schema if exists ticketchema cascade;
create schema ticketchema;
set search_path to ticketchema;

-- Look up table containg all the owners and their information.
CREATE TABLE Owner (
  owner_id integer PRIMARY KEY NOT NULL,
  name varchar(100) NOT NULL,
  phone varchar(10) NOT NULL UNIQUE
);

-- All venues with all their basic information
-- every venue has at least 10 seats cannot be enforced without 
-- the use of triggers/assertions. We need cross table constraints, 
-- checking table Seats, and performating a subquery which 
-- requires assertions. 
CREATE TABLE Venue (
  venue_id integer PRIMARY KEY NOT NULL,
  name varchar(25) NOT NULL,
  city varchar(25) NOT NULL,
  address varchar(100) NOT NULL,
  owner_id integer NOT NULL REFERENCES Owner
);

-- A list of all the concerts
CREATE TABLE Concert (
    concert_id integer PRIMARY KEY NOT NULL,
    name varchar(100) NOT NULL,
    venue_id integer NOT NULL REFERENCES Venue,
    datetime timestamp NOT NULL,
    UNIQUE(venue_id, datetime)
);

-- All users for this app. Decided to use a separate 
-- table because it will be easier for additional
-- information to be created and inserted. 
CREATE TABLE Users (
    username varchar(50) PRIMARY KEY
);

-- ID for all sections in all venues
CREATE TABLE Section (
    section_id integer NOT NULL PRIMARY KEY,
    venue_id integer NOT NULL REFERENCES Venue,
    section varchar(10) NOT NULL,
    UNIQUE (venue_id, section)
);

-- All seats in a venue
CREATE TABLE Seat (
    section_id integer NOT NULL REFERENCES Section,
    seat varchar(20) NOT NULL,
    accessibility boolean NOT NULL,
    PRIMARY KEY (section_id, seat)
);

-- Prices for all tickets
CREATE TABLE TicketPrice (
    concert_id integer NOT NULL REFERENCES Concert,
    section_id integer NOT NULL REFERENCES Section,
    price real NOT NULL,
    PRIMARY KEY (concert_id, section_id)
);

-- All transaction history, every single entry is for only one seat sold
CREATE TABLE Transaction (
    transaction_id integer PRIMARY KEY NOT NULL,
    username varchar(50) NOT NULL REFERENCES Users,
    concert_id integer NOT NULL REFERENCES Concert,
    section_id integer NOT NULL REFERENCES Section,
    seat varchar(20) NOT NULL, 
    datetime timestamp NOT NULL,
    FOREIGN KEY (section_id, seat) REFERENCES Seat (section_id, seat),
    FOREIGN KEY (concert_id, section_id) 
    REFERENCES TicketPrice (concert_id, section_id)
);