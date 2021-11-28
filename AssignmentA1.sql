CREATE TABLE "Guest" (
  "Guest_id" int PRIMARY KEY,
  "Post_code" varchar NOT NULL,
  "State" varchar NOT NULL,
  "City" varchar NOT NULL,
  "Country" varchar Not NULL,
  "Street_name" varchar NOT NULL,
  "Street_number" varchar NOT NULL,
  "Phone_num_work" varchar,
  "Phone_num_cell" varchar,
  "Phone_num_home" varchar,
  "Email_address" varchar,
  "First_name" varchar NOT NULL,
  "Middle_name" varchar,
  "Last_name" varchar NOT NULL,
  UNIQUE ("Post_code", "City", "State", "Street_name", "Street_number")
);

CREATE TABLE "Reservation" (
  "Reservation_id" SERIAL PRIMARY KEY,
  "Guest_id" int NOT NULL,
  "Smoking_preferred" boolean,
  "Nr_beds_preferred" int,
  "High_or_low_floor_preferred" varchar,
  "Arrival_date" date NOT NULL,
  "Departure_date" date NOT NULL,
  "Credit_card_num" int NOT NULL,
  "Credit_card_expiry_year" int NOT NULL,
  "credit_card_expiry_month" int NOT NULL,
  "Channel_id" int,
  "Channel_fee" double,
  CONSTRAINT Guest_id FOREIGN KEY (Guest_id) REFERENCES Guest(Guest_id),
  CONSTRAINT Channel_id FOREIGN key (Channel_id) REFERENCES Booking_channel(Channel_id)
)


CREATE TABLE "Additional_services" (
  "Add_serv_id" SERIAL PRIMARY KEY,
  "Reservation_id" int,
  "Service_name" varchar NOT NULL,
  CONSTRAINT  Reservation_id FOREIGN KEY (Reservation_id) REFERENCES Reservation(Reservation_id)
);

CREATE TABLE "Stay" (
  "Stay_id" SERIAL PRIMARY KEY,
  "Guest_id" int NOT NULL,
  "Arrival_date" date NOT NULL,
  "Departure_date" date NOT NULL,
  "Channel_id" varchar,
  "Channel_fee" double,
  CONSTRAINT  Guest_id FOREIGN KEY (Guest_id) REFERENCES Guest(Guest_id),
  CONSTRAINT  Channel_id FOREIGN KEY (Channel_id) REFERENCES Booking_channel(Channel_id)
  
);

CREATE TABLE "Invoice" (
  "Invoice_id" int PRIMARY KEY,
  "Stay_id" int NOT NULL,
  CONSTRAINT  Stay_id FOREIGN KEY (Stay_id) REFERENCES Stay(Stay_id)
);

CREATE TABLE "Invoice_charges" (
  "Item_id" SERIAL PRIMARY KEY,
  "Invoice_id" int NOT NULL,
  "Item_name" varchar,
  "Ex_tax_amt" double,
  "Tax_amt" double,
  CONSTRAINT  Invoice_id FOREIGN KEY (Invoice_id) REFERENCES Invoice(Invoice_id)

);

CREATE TABLE "Invoice_payments" (
  "Item_id" SERIAL PRIMARY KEY,
  "Invoice_id" int NOT NULL,
  "Payment_type" varchar,
  "Amt" double Not null,
  CONSTRAINT  Invoice_id FOREIGN KEY (Invoice_id) REFERENCES Invoice(Invoice_id)
);

CREATE TABLE "Booking_channel" (
  "Channel_id" SERIAL PRIMARY KEY,
  "Channel_name" varchar
);

CREATE TABLE "Hotel" (
  "Hotel_id" SERIAL PRIMARY KEY,
  "Name" varchar NOT NULL,
  "Home_page" varchar NOT NULL,
  "Post_code" varchar NOT NULL,
  "State" varchar NOT NULL,
  "City" varchar NOT NULL,
  "Street_name" varchar NOT NULL,
  "Street_number" varchar NOT NULL,
  "Primary_phone_number" varchar NOT NULL
);

CREATE TABLE "Additional_facilities" (
  "Add_facility_id" SERIAL PRIMARY KEY,
  "Add_facility_name" varchar NOT NULL,
  "Add_facility_cost" float not Null,
  "Hotel_id" int,
  CONSTRAINT  Hotel_id FOREIGN KEY (Hotel_id) REFERENCES Hotel(Hotel_id)
);

CREATE TABLE "Room" (
  "Hotel_id" int NOT NULL,
  "Room_name_or_number" varchar NOT NULL,
  "floor" int NOT NULL,
  "Nr_beds" int NOT NULL,
  "Smoking_allowed" boolean NOT NULL,
  PRIMARY KEY ("Hotel_id", "Room_name_or_number"),
  CONSTRAINT  Hotel_id FOREIGN KEY (Hotel_id) REFERENCES Hotel(Hotel_id)
);

CREATE TABLE "Room_allocation" (
  "Hotel_id" int NOT NULL,
  "Room_name_or_number" int NOT NULL,
  "Date" date NOT NULL,
  "Allocation_type" varchar,
  "Channel_id" int DEFAULT null,
  "Reservation_id" int DEFAULT null,
  "Stay_id" int DEFAULT null,
  PRIMARY KEY ("Hotel_id", "Room_name_or_number", "Date"),
  CONSTRAINT  Channel_id FOREIGN KEY (Channel_id) REFERENCES Booking_channel(Channel_id),
  CONSTRAINT  Reservation_id FOREIGN KEY (Reservation_id) REFERENCES Reservation(Reservation_id),
  CONSTRAINT  Stay_id FOREIGN KEY (Stay_id) REFERENCES Stay(Stay_id),
  CONSTRAINT Hotel_id FOREIGN KEY (Hotel_id) REFERENCES Room(Hotel_id),
 CONSTRAINT Room_name_or_number FOREIGN KEY (Room_name_or_number) REFERENCES Room(Room_name_or_number)
);

-- Queries
-- 1. The total spent for the customer for a particular stay (checkout invoice).

select G.Guest_id, S.Stay_id,P.Amt from Stay S join Invoice I on S.Stay_id = I.Stay_id 
join Invoice_payments IP on IP.Invoice_id= I.Invoice_id 
group by S.Stay_id;
--where S.Stay_id = "12345";


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

