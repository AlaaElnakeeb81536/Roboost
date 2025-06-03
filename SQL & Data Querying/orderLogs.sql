
--What is the % of pause action out of total manual actions?"
with MannualAction As(
select OrderID, CreatedDate ,Action
from OrderLogs_sample
where Action in(11,12,18,23)
),
filtered as (
    select nd.OrderID,nd.CreatedDate from MannualAction nd
    left join (
        select OrderID, min(CreatedDate) as removalDate
        from MannualAction
        where Action=18
        group by OrderID
    ) st on st.OrderID = nd.OrderID
    where (nd.CreatedDate < st.removalDate or st.removalDate is null) and nd.Action=23
)
SELECT 
    ROUND(
        100.0 * (SELECT COUNT(*) FROM filtered) 
        / (SELECT COUNT(*) FROM MannualAction), 
        2
    ) AS PausePercentage;

	---------------------------------
with MannualAction As(
select OrderID, CreatedDate ,Action
from OrderLogs_sample
where Action in(11,12,18,23)
),
filtered AS ( 
select OrderID, CreatedDate As pauseDate
from MannualAction
where Action=23
),
nextaction as(
 select   mn.OrderID,mn.pauseDate,min(os.CreatedDate) as nextDate 
 from filtered mn
 left join OrderLogs_sample os
 ON mn.OrderID = os.OrderID
        AND os.CreatedDate > mn.pauseDate
        AND os.Action IN (24, 11, 12) 
    GROUP BY mn.OrderID, mn.pauseDate

 ),
 pauseDuration AS(SELECT 
        OrderID,
        PauseDate,
        nextDate,
        DATEDIFF(MINUTE, PauseDate, nextDate) AS PauseDurationMinutes
    FROM nextaction 
	)

SELECT 
    ROUND(AVG(CAST(PauseDurationMinutes AS FLOAT)), 2) AS avgPauseDurationMin
FROM pauseDuration;
