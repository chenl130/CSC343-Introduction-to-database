set search_path to ticketchema;

INSERT INTO Owner(owner_id, name, phone) VALUES
    (1, 'The Corporation of Massey Hall and Roy Thomson Hall', '6144444789'),
    (2, 'Maple Leaf Sports & Entertainment', '1234567890');

INSERT INTO Venue(venue_id, name, city, address, owner_id) VALUES
    (1, 'Massey Hall', 'Toronto', '178 Victoria Street', 1),
    (2, 'Roy Thomson Hall', 'Toronto', '60 Simcoe St', 1),
    (3, 'ScotiaBank Arena', 'Toronto', '40 Bay St', 2);

INSERT INTO Concert(concert_id, venue_id, name, datetime) VALUES
    (1, 1, 'Ron Sexsmith', '2022-12-03 19:30'),
    (2, 1, 'Women''s Blues Review', '2022-11-25 20:00'),
    (3, 3, 'Mariah Carey - Merry Christmas to all', '2022-12-09 20:00'),
    (4, 3, 'Mariah Carey - Merry Christmas to all', '2022-12-11 20:00'),
    (5, 2, 'TSO - Elf in Concert', '2022-12-09 19:30'),
    (6, 2, 'TSO - Elf in Concert', '2022-12-10 14:30'),
    (7, 2, 'TSO - Elf in Concert', '2022-12-10 19:30');

INSERT INTO Users(username) VALUES 
    ('ahightower'),
    ('d_targaryen'),
    ('cristonc');

INSERT INTO Section(section_id, venue_id, section) VALUES 
    (100, 1, 'floor'),
    (101, 1, 'balcony'),
    (102, 2, 'main hall'),
    (103, 3, '100'),
    (104, 3, '200'),
    (105, 3, '300');

INSERT INTO Seat(section_id, seat, accessibility) VALUES
    (100, 'A1', 't'),
    (100, 'A2', 't'),
    (100, 'A3', 't'),
    (100, 'A4', 'f'),
    (100, 'A5', 'f'),
    (100, 'A6', 'f'),
    (100, 'A7', 'f'),
    (100, 'A8', 't'),
    (100, 'A9', 't'),
    (100, 'A10', 't'),
    (100, 'B1', 'f'),
    (100, 'B2', 'f'),
    (100, 'B3', 'f'),
    (100, 'B4', 'f'),
    (100, 'B5', 'f'),
    (100, 'B6', 'f'),
    (100, 'B7', 'f'),
    (100, 'B8', 'f'),
    (100, 'B9', 'f'),
    (100, 'B10', 'f'), 
    (101, 'C1', 'f'), 
    (101, 'C2', 'f'), 
    (101, 'C3', 'f'), 
    (101, 'C4', 'f'), 
    (101, 'C5', 'f'), 
    (102, 'AA1', 'f'),
    (102, 'AA2', 'f'),
    (102, 'AA3', 'f'),
    (102, 'BB1', 'f'),
    (102, 'BB2', 'f'),
    (102, 'BB3', 'f'),
    (102, 'BB4', 'f'),
    (102, 'BB5', 'f'),
    (102, 'BB6', 'f'),
    (102, 'BB7', 'f'),
    (102, 'BB8', 'f'),
    (102, 'CC1', 'f'),
    (102, 'CC2', 'f'),
    (102, 'CC3', 'f'),
    (102, 'CC4', 'f'),
    (102, 'CC5', 'f'),
    (102, 'CC6', 'f'),
    (102, 'CC7', 'f'),
    (102, 'CC8', 'f'),
    (102, 'CC9', 'f'),
    (102, 'CC10', 'f'),
    (103, 'row 1, seat 1', 't'),
    (103, 'row 1, seat 2', 't'),
    (103, 'row 1, seat 3', 't'),
    (103, 'row 1, seat 4', 't'),
    (103, 'row 1, seat 5', 't'),
    (103, 'row 2, seat 1', 't'),
    (103, 'row 2, seat 2', 't'),
    (103, 'row 2, seat 3', 't'),
    (103, 'row 2, seat 4', 't'),
    (103, 'row 2, seat 5', 't'),
    (104, 'row 1, seat 1', 'f'),
    (104, 'row 1, seat 2', 'f'),
    (104, 'row 1, seat 3', 'f'),
    (104, 'row 1, seat 4', 'f'),
    (104, 'row 1, seat 5', 'f'),
    (104, 'row 2, seat 1', 'f'),
    (104, 'row 2, seat 2', 'f'),
    (104, 'row 2, seat 3', 'f'),
    (104, 'row 2, seat 4', 'f'),
    (104, 'row 2, seat 5', 'f'),
    (105, 'row 1, seat 1', 'f'),
    (105, 'row 1, seat 2', 'f'),
    (105, 'row 1, seat 3', 'f'),
    (105, 'row 1, seat 4', 'f'),
    (105, 'row 1, seat 5', 'f'),
    (105, 'row 2, seat 1', 'f'),
    (105, 'row 2, seat 2', 'f'),
    (105, 'row 2, seat 3', 'f'),
    (105, 'row 2, seat 4', 'f'),
    (105, 'row 2, seat 5', 'f');


INSERT INTO TicketPrice(concert_id, section_id, price) VALUES
    (1, 100, 130),
    (1, 101, 99),
    (2, 100, 150),
    (2, 101, 125),
    (3, 103, 986),
    (3, 104, 244),
    (3, 105, 176),
    (4, 103, 936),
    (4, 104, 194),
    (4, 105, 126),
    (5, 102, 159),
    (6, 102, 159),
    (7, 102, 159);


INSERT INTO Transaction(transaction_id, username, concert_id, section_id, seat, datetime) VALUES
    (10, 'ahightower', 2, 100, 'A5', '2020-11-11 11:11'),
    (11, 'ahightower', 2, 101, 'C2', '2020-11-11 11:11'),
    (12, 'd_targaryen', 1, 100, 'B3', '2020-11-11 11:11'),
    (13, 'd_targaryen', 7, 102, 'BB7', '2020-11-11 11:11'),
    (14, 'cristonc', 3, 103, 'row 1, seat 3', '2020-11-11 11:11'),
    (15, 'cristonc', 4, 104, 'row 2, seat 3', '2020-11-11 11:11'),
    (16, 'cristonc', 4, 104, 'row 2, seat 4', '2020-11-11 11:11');

