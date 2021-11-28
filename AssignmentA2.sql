--How many customers have stopped bringing their cars after the first encounter with the dealer ?

select sum(Customer_ID), count(Service_ID) as Frequency from Dealer where Frequency=1
group by Customer_ID

-- What is the relationship between the price of the service and the age of the car in terms of 
--(a)actual car age (e.g., mileage) and
select sum(D.Service_Cost), datediff(YY,C.Date_of_Manufacture,getdate()) as Actual_AGE_in_Years from Dealer D join Car C
on D.VIN=C.VIN group by VIN
order by Actual_AGE_in_Years desc

--b) time with the current owner?
select sum(D.Service_Cost), datediff(YY,C.Date_of_Purchase,getdate()) as Purchase_AGE_in_Years from Dealer D join Car C
on D.VIN=C.VIN group by VIN
order by Purchase_AGE_in_Years desc