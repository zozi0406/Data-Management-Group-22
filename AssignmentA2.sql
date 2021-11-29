-- How many customers have stopped bringing their cars after the first encounter with the dealer ?

-- Assuming Customers have only one car
SELECT COUNT(*) AS Churns FROM (
  -- Subquery yields table with the number of times a customer brought their car to service and when the next service would be due, 
  -- which can be analysed further to reveal more about the likelihood of coming to service more times.
  SELECT C.VIN, COUNT(S.Service_id), C.Next_due_service_date AS Total_services FROM Car C
  INNER JOIN Service S ON C.VIN=S.VIN
  GROUP BY C.VIN
  )
-- Only consider those customers churns, whose due service dates have already passed.
WHERE date(Next_due_service_date)<date("now")
AND Total_services = 1;


-- What is the relationship between the price of the service and the age of the car in terms of 
--(a)actual car age (e.g., mileage) and b) time with the current owner?

-- One query combined to extract information for both questions:
-- (a) can be answered via Mileage_at_service_time and (b) can be answered with days_since_purchase
SELECT SUM(Costs.Item_cost), S.Mileage_at_service_time, (julianday(S.service_date)-julianday(C.Purchase_date)) AS days_since_purchase FROM Service S
INNER JOIN Car C ON C.VIN=S.VIN
INNER JOIN Cost_item Costs ON Costs.Service_id=S.Service_id
GROUP BY Service_id