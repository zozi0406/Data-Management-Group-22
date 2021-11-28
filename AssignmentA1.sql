
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
  -- In this case Text is chosen for simplicity. Date operations work on all of them. SQLite (2021): "https://www.sqlite.org/datatype3.html"
  Arrival_date TEXT NOT NULL,
  Departure_date TEXT NOT NULL,
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
  -- In this case Text is chosen for simplicity. Date operations work on all of them. SQLite (2021): "https://www.sqlite.org/datatype3.html"
  Arrival_date TEXT NOT NULL,
  Departure_date TEXT NOT NULL,
  Channel_id TEXT,
  Channel_fee REAL,
  FOREIGN KEY (Guest_id) REFERENCES Guest(Guest_id),
  FOREIGN KEY (Channel_id) REFERENCES Booking_channel(Channel_id)
  
);

CREATE TABLE Invoice (
  Invoice_id INTEGER PRIMARY KEY,
  Stay_id INTEGER NOT NULL,
  FOREIGN KEY (Stay_id) REFERENCES Stay(Stay_id)
);

CREATE TABLE Invoice_charges (
  Charge_item_id INTEGER PRIMARY KEY AUTOINCREMENT,
  Invoice_id INTEGER NOT NULL,
  Item_name TEXT,
  Ex_tax_amount REAL,
  Tax_amount REAL,
  FOREIGN KEY (Invoice_id) REFERENCES Invoice(Invoice_id)

);

CREATE TABLE Invoice_payments (
  Payment_item_id INTEGER PRIMARY KEY AUTOINCREMENT,
  Invoice_id INTEGER NOT NULL,
  Payment_type TEXT NOT NULL,
  Amount REAL NOT NULL,
  FOREIGN KEY (Invoice_id) REFERENCES Invoice(Invoice_id)
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
  -- In this case Text is chosen for simplicity. Date operations work on all of them. SQLite (2021): "https://www.sqlite.org/datatype3.html"
  Date TEXT NOT NULL,
  Allocation_type TEXT,
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

select G.Guest_id, S.Stay_id,P.Amt from Stay S join Invoice I on S.Stay_id = I.Stay_id 
join Invoice_payments IP on IP.Invoice_id= I.Invoice_id 
group by S.Stay_id;
--where S.Stay_id = 12345;


--The most valuable customers in (a) the last two months, (b) past year and (c) from thebeginning of the records.

--a

select G.First_name, G.Last_name, sum(IP.Amt) as Amount from Guest G join Stay S on G.Guest_id=S.Guest_id
join Invoice I I.Stay_id= S.Stay_id join Invoice_payments IP on IP.Invoice_id= I.Invoice_id 
Where S.Departure_date >= DateADD(M,-2,getdate())
order by Amount desc Limit 1;

--b
select G.First_name, G.Last_name, sum(IP.Amt) as Amount from Guest G join Stay S on G.Guest_id=S.Guest_id
join Invoice I I.Stay_id= S.Stay_id join Invoice_payments IP on IP.Invoice_id= I.Invoice_id 
Where S.Departure_date >= DateADD(M,-12,getdate())
order by Amount desc Limit 1;

--c
select G.First_name, G.Last_name, sum(IP.Amt) as Amount from Guest G join Stay S on G.Guest_id=S.Guest_id
join Invoice I I.Stay_id= S.Stay_id join Invoice_payments IP on IP.Invoice_id= I.Invoice_id 
order by Amount desc Limit 1;


-- Which are the top countries where our customers come from ?

select G.Country, Count(Country) as Frequency from Guest G join Stay S
on G.Guest_id=S.Guest_id
group by (S.Guest_id)
order by Frequency desc limit 5;


-- How much did the hotel pay in referral fees for each of the platforms that we have contracted with?

select C.Channel_id,C.Channel_name, sum(c.Channel_fee)
from S.stay join Channel_name C on S.Channel_id=C.Channel_id
group by S.Channel_id


--What is the utilization rate for each hotel (that is the average billable days of a hotel specified as the average utilization of room bookings for the last 12 months)

select H.Name , H.Hotel_id, count(distinct(RA.date))/365 as Frequency 
from  Room_allocation RA  join Hotel H on H.Hotel_id= Ra.Hotel_id
group by RA.Hotel_id having Ra.date >= DateADD(M,-12,getdate())

--Calculate the Customer Value in terms of total spent for each customer before the current booking.

select RA.Reservation_id, R.Guest_id, sum(IV.Amt) from Reservation R 
join Room_allocation RA on R.Reservation_id=Reservation_id 
join Stay S on  S.Guest_id=RA.Guest_id 
join Invoice on I I.Stay_id=S>Stay_id 
join Invoice_payments IP on IP.Invoice_id = I.Invoice_id
group by RA.Guest_id

