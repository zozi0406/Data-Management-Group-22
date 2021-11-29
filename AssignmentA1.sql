
-- DDL using SQLite 3 syntax based on https://www.sqlite.org/

CREATE TABLE Guest (
  Guest_id INTEGER PRIMARY KEY AUTOINCREMENT,
  Post_code TEXT NOT NULL,
  State TEXT NOT NULL,
  City TEXT NOT NULL,
  Country TEXT Not NULL,
  Street_name TEXT NOT NULL,
  Street_number TEXT NOT NULL,
  Phone_num_work TEXT,
  Phone_num_cell TEXT,
  Phone_num_home TEXT,
  Email_address TEXT,
  First_name TEXT NOT NULL,
  Middle_name TEXT,
  Last_name TEXT NOT NULL,
  UNIQUE (Post_code, City, State, Street_name, Street_number, Country)
);

CREATE TABLE Reservation (
  Reservation_id INTEGER PRIMARY KEY AUTOINCREMENT,
  Guest_id INTEGER NOT NULL,
   -- Smoking_allowed could be boolean, but it would be converted to numeric in SQLite
  Smoking_preferred INTEGER,
  Nr_beds_preferred INTEGER,
  High_or_low_floor_preferred TEXT,
  -- SQLite does not have a Date data type, it can be stored as either Text, Real or Integer
  -- In this case Integer is chosen for simplicity. Date operations work on all of them. SQLite (2021): "https://www.sqlite.org/datatype3.html"
  Arrival_date INTEGER NOT NULL,
  Departure_date INTEGER NOT NULL,
  Credit_card_num INTEGER NOT NULL,
  Credit_card_expiry_year INTEGER NOT NULL,
  credit_card_expiry_month INTEGER NOT NULL,
  Channel_id INTEGER,
  Channel_fee REAL,
  FOREIGN KEY (Guest_id) REFERENCES Guest(Guest_id),
  FOREIGN key (Channel_id) REFERENCES Booking_channel(Channel_id)
);


CREATE TABLE Additional_services (
  Add_serv_id PRIMARY KEY AUTOINCREMENT,
  Reservation_id INTEGER,
  Service_name TEXT NOT NULL,
  FOREIGN KEY (Reservation_id) REFERENCES Reservation(Reservation_id)
);

CREATE TABLE Stay (
  Stay_id PRIMARY KEY AUTOINCREMENT,
  Guest_id INTEGER NOT NULL,
  -- SQLite does not have a Date data type, it can be stored as either Text, Real or Integer
  -- In this case Integer is chosen for simplicity. Date operations work on all of them. SQLite (2021): "https://www.sqlite.org/datatype3.html"
  Arrival_date INTEGER NOT NULL,
  Departure_date INTEGER NOT NULL,
  Channel_id TEXT,
  Channel_fee REAL,
  -- Assuming official invoice number cannot contain letters of the alphabet, only numbers.
  Invoice_number INTEGER,
  FOREIGN KEY (Guest_id) REFERENCES Guest(Guest_id),
  FOREIGN KEY (Channel_id) REFERENCES Booking_channel(Channel_id)
  
);

CREATE TABLE Invoice_charges (
  Charge_item_id INTEGER PRIMARY KEY AUTOINCREMENT,
  Stay_id INTEGER NOT NULL,
  Item_name TEXT,
  Ex_tax_amount REAL,
  Tax_amount REAL,
  FOREIGN KEY (Stay_id) REFERENCES Stay(Stay_id)

);

CREATE TABLE Invoice_payments (
  Payment_item_id INTEGER PRIMARY KEY AUTOINCREMENT,
  Stay_id INTEGER NOT NULL,
  Payment_type TEXT NOT NULL,
  Amount REAL NOT NULL,
  FOREIGN KEY (Stay_id) REFERENCES Stay(Stay_id)
);

CREATE TABLE Booking_channel (
  Channel_id PRIMARY KEY AUTOINCREMENT,
  Channel_name TEXT
);

CREATE TABLE Hotel (
  Hotel_id INTEGER PRIMARY KEY AUTOINCREMENT,
  Name TEXT NOT NULL,
  Home_page TEXT NOT NULL,
  Post_code TEXT NOT NULL,
  State TEXT NOT NULL,
  City TEXT NOT NULL,
  Street_name TEXT NOT NULL,
  Street_number TEXT NOT NULL,
  Primary_phone_number TEXT NOT NULL
);

CREATE TABLE Additional_facilities (
  Add_facility_id INTEGER PRIMARY KEY AUTOINCREMENT,
  Add_facility_name TEXT NOT NULL,
  Add_facility_cost float NOT NULL,
  Hotel_id INTEGER,
  FOREIGN KEY (Hotel_id) REFERENCES Hotel(Hotel_id)
);

CREATE TABLE Room (
  Hotel_id INTEGER NOT NULL,
  Room_name_or_number TEXT NOT NULL,
  floor INTEGER NOT NULL,
  Nr_beds INTEGER NOT NULL,
  -- Smoking_allowed could be boolean, but it would be converted to numeric in SQLite
  Smoking_allowed INTEGER NOT NULL,
  PRIMARY KEY (Hotel_id, Room_name_or_number),
  FOREIGN KEY (Hotel_id) REFERENCES Hotel(Hotel_id)
);

CREATE TABLE Room_allocation (
  Hotel_id INTEGER NOT NULL,
  Room_name_or_number INTEGER NOT NULL,
  -- SQLite does not have a Date data type, it can be stored as either Text, Real or Integer
  -- In this case Integer is chosen for simplicity. Date operations work on all of them. SQLite (2021): "https://www.sqlite.org/datatype3.html"
  Date INTEGER NOT NULL,
  Channel_id INTEGER DEFAULT NULL,
  Reservation_id INTEGER DEFAULT NULL,
  Stay_id INTEGER DEFAULT NULL,
  PRIMARY KEY (Hotel_id, Room_name_or_number, Date),
  FOREIGN KEY (Channel_id) REFERENCES Booking_channel(Channel_id),
  FOREIGN KEY (Reservation_id) REFERENCES Reservation(Reservation_id),
  FOREIGN KEY (Stay_id) REFERENCES Stay(Stay_id),
  FOREIGN KEY (Hotel_id, Room_name_or_number) REFERENCES Room(Hotel_id,Room_name_or_number)
  -- Ensure a room is only allocated to one purpose
  CONSTRAINT Only_one_key CHECK ((Channel_id NOT NULL OR Reservation_id NOT NULL OR Stay_id NOT NULL)
                            AND NOT (Channel_id NOT NULL AND Reservation_id NOT NULL)
                            AND NOT (Reservation_id NOT NULL AND Stay_id NOT NULL)
                            AND NOT (Channel_id NOT NULL AND Stay_id NOT NULL))
);

-- Queries
-- 1. The total spent for the customer for a particular stay (checkout invoice).

-- Assuming total spent includes taxes paid.
SELECT S.Guest_id, S.Stay_id, SUM(IP.Amount) FROM Stay S 
INNER JOIN Invoice_payments IP ON IP.Stay_id = S.Stay_id
-- To specify a particular stay:
WHERE S.Stay_id = 12345;


-- 2. The most valuable customers in (a) the last two months, (b) past year and (c) from the beginning of the records.

-- a

-- Assuming last two months means to count all stays that started in the last two months.
-- Assuming value means total spent including taxes paid
SELECT G.Guest_id, SUM(IP.Amount) AS Total_spent FROM Stay S 
INNER JOIN Guest G ON G.Guest_id = S.Guest_id
INNER JOIN Invoice_payments IP ON IP.Stay_id = S.Stay_id
-- Based on https://www.sqlite.org/lang_datefunc.html
WHERE date(S.Arrival_date) >= date('now',"-2 months")
GROUP BY G.Guest_id
ORDER BY Total_spent DESC LIMIT 10;

-- b

SELECT G.Guest_id, SUM(IP.Amount) AS Total_spent FROM Stay S 
INNER JOIN Guest G ON G.Guest_id = S.Guest_id
INNER JOIN Invoice_payments IP ON IP.Stay_id = S.Stay_id 
-- Based on https://www.sqlite.org/lang_datefunc.html, Assuming by past year, the last 365 days are meant.
-- If all stays since the start of the year are meant, "-1 year" would be replaced by "start of year".
WHERE date(S.Arrival_date) >= date('now',"-1 year")
GROUP BY G.Guest_id
ORDER BY Total_spent DESC LIMIT 10;

-- c

SELECT G.Guest_id, SUM(IP.Amount) AS Total_spent FROM Stay S 
INNER JOIN Guest G ON G.Guest_id = S.Guest_id
INNER JOIN Invoice_payments IP ON IP.Stay_id = S.Stay_id
GROUP BY G.Guest_id
ORDER BY Total_spent DESC LIMIT 10;


-- 3. Which are the top countries where our customers come from ?

SELECT Country, COUNT(Guest_id) AS Frequency FROM Guest 
GROUP BY Country
ORDER BY Frequency DESC LIMIT 10;


-- 4. How much did the hotel pay in referral fees for each of the platforms that we have contracted with?

-- Assuming arrival date on the last day of the month means channel fees are charged for that month still.
SELECT C.Channel_id, C.Channel_name, SUM(S.Channel_fee) AS Total_fees FROM Booking_channel C
INNER JOIN Stay S on S.Channel_id=C.Channel_id
-- Only include stays that finished on or before the end of the last month
WHERE date(S.Arrival_date) <= date("now","start of month","-1 day")
GROUP BY C.Channel_name;


-- 5. What is the utilization rate for each hotel (that is the average billable days of a hotel specified as the average utilization of room bookings for the last 12 months)

SELECT Name, Hotel_id, AVG(Utilisation) FROM
    (
    SELECT H.Name, H.Hotel_id, R.Room_name_or_number, COUNT(RA.date)/365.0 AS Utilisation FROM Room_allocation RA  
    -- Only joining to retrieve hotel name:
    INNER JOIN Room R on RA.(Hotel_id, Room_name_or_number) = R.(Hotel_id, Room_name_or_number)
    INNER JOIN Hotel H on R.Hotel_id = H.Hotel_id
    WHERE date(RA.Date) >= date("now","-1 year")
    -- To ensure that only stays count as utilised days:
    AND Stay_id NOT NULL
    GROUP BY R.Hotel_id, R.Room_name_or_number
    )
GROUP BY Hotel_id;


-- 6. Calculate the Customer Value in terms of total spent for each customer before the current booking.

-- Assuming total spent includes taxes paid
-- Stay only includes previous stays, so no need to filter anything.
SELECT S.Guest_id, SUM(IP.Amount) AS Total_spent FROM Stay S
INNER JOIN Invoice_payments IP ON IP.Stay_id = S.Stay_id 
GROUP BY S.Guest_id
-- Only include Guest_ids that also have reservations.
HAVING S.Guest_id IN (SELECT DISTINCT Guest_id FROM Reservation);
-- Guest_id could be specified if looking for specific
-- HAVING S.Guest_id = 12345


