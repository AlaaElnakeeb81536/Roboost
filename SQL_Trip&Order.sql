select * from Trips_sample 
select * from Orders_sample 
select * from OrderLogs_sample
select *from FraudOrders_sample


----1. Which branch has the lowest % of auto-dispatched tasks?
select top 1 
HubID ,
COUNT(*) AS total_orders,
SUM(CASE WHEN IsAutoDispatched = 1 THEN 1 ELSE 0 END) AS auto_dispatched,
CAST(
    ROUND(COUNT(case when IsAutoDispatched = 1 THEN 1 END)*1.0 /count(*),2) 
	AS DECIMAL(5, 2) 
	)As autoDispatched_percent
from Orders_sample 
where HubID is not null
group by HubID
ORDER BY autoDispatched_percent ASC;

-------------------
---What is the average deliveryman on-duty hours per day?
with tripperiods as(
 select id as TripID, DeliverymanID, ShiftDate,StartTime,COALESCE(CloseTime, ArrivalTime) AS CloseTime
 from Trips_sample
 where DeliverymanID is not null 
 and StartTime is not null
 and(CloseTime is not null or ArrivalTime is not null)
 and ShiftDate is not null 
 and coalesce(CloseTime, ArrivalTime)>=StartTime
 ),
  Dailytrip AS(

 select DeliverymanID,CAST(StartTime AS DATE) AS TripDate,
        SUM(DATEDIFF(MINUTE, StartTime, CloseTime)) / 60.0 AS OnDutyHours
    FROM tripperiods
    GROUP BY DeliverymanID, CAST(StartTime AS DATE)
	)
	SELECT 
    AVG(OnDutyHours) AS AvgOnDutyHoursPerDay
FROM Dailytrip;

----
---3. What is the average monthly spend per customer?
with monthlyspent AS(
    SELECT 
        CustomerID,
        YEAR(CreatedDate) AS Year,
        MONTH(CreatedDate) AS Month,
        SUM(Amount) AS Monthlytotal
    FROM Orders_sample
    GROUP BY CustomerID, YEAR(CreatedDate), MONTH(CreatedDate)
	)


select  round(avg(Monthlytotal),2) AS AVGMonthPerCustomer from monthlyspent 

-----
--4-What is the average trip returning duration?
WITH lastdelivery AS (
    SELECT 
        TripID,
        MAX(DeliveryTime) AS LastDeliveryTime
    FROM Orders_sample
    WHERE DeliveryTime IS NOT NULL
    GROUP BY TripID
),
durationtime AS (
    SELECT  
        t.ID AS TripID,
        DATEDIFF(MINUTE, d.LastDeliveryTime, t.CloseTime) AS returningduration
    FROM Trips_sample t
    JOIN lastdelivery d ON t.ID = d.TripID
    WHERE 
        t.CloseTime IS NOT NULL
        AND d.LastDeliveryTime IS NOT NULL
        AND t.CloseTime > d.LastDeliveryTime
)
SELECT 
    ROUND(AVG(returningduration) / 60.0, 2) AS AvgReturningDuration_Hours
FROM durationtime;

----
--5- What is the average time taken to deliver the second order in trips that have two or more orders?
WITH rankeddeliveries AS (
    SELECT 
        o.TripID,
        o.DeliveryTime,
        t.StartTime,
        ROW_NUMBER() OVER (PARTITION BY o.TripID ORDER BY o.DeliveryTime) AS OrderRank
    FROM Orders_sample o
    JOIN Trips_sample t ON o.TripID = t.ID
    WHERE o.DeliveryTime IS NOT NULL AND t.StartTime IS NOT NULL
),
secondone AS (
    SELECT 
        TripID,
        DATEDIFF(MINUTE, StartTime, DeliveryTime) AS SecondOrderDeliveryTime
    FROM rankeddeliveries
    WHERE OrderRank = 2
)
SELECT 
    ROUND(AVG(SecondOrderDeliveryTime) / 60.0, 2) AS AvgHoursToDeliverSecondOrder
FROM secondone;



