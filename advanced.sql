-- 1) country / manufacturer totals for unpaid invoices
SELECT
    c.Country,
    m.Manufacturer,
    SUM(i.Amount) AS total_revenue
FROM ValetingSQL.Invoice   i
JOIN ValetingSQL.Customer  c  ON i.CustomerID     = c.ID
JOIN ValetingSQL.Product   p  ON i.ProductID      = p.ID
JOIN ValetingSQL.Manufacturer m ON p.ManufacturerID = m.ID
WHERE i.Paid = 0                                 -- unpaid
GROUP BY c.Country, m.Manufacturer
HAVING SUM(i.Amount) > 75;                        -- > £75 per country/manufacturer

-- 2) customers with more than one invoice using a sub‑query
SELECT *
FROM tblCustomers
WHERE CustomerID IN (
    SELECT CustomerID
    FROM tblInvoices
    GROUP BY CustomerID
    HAVING COUNT(*) >= 2
);

-- 3) same logic using the user's table names and correcting typos
SELECT
    c.Country,
    v.Manufacturer,
    SUM(i.Amount) AS TotalOutstanding
FROM tblInvoices i
INNER JOIN tblCustomers c ON i.customerID = c.customerID
INNER JOIN tblcards v ON i.vehicleNo = v.VehicleNo
WHERE i.Paid = 'False'   -- or WHERE i.Paid = 0 depending on data type
GROUP BY c.Country, v.Manufacturer
HAVING SUM(i.Amount) > 75;

-----computer sales database that shows the sales revenue for each salesperson by each sale method (transaction total is qty Sold * Price). Next use this as a CTE and then use it to show again the sales for each assistant by sale type and then display alongside each row the total sales for the whole query

select p.[product Group], 
p.Product,
s. [Qty Sold],
SUM(s.[Qty Sold]) OVER() as TotalSold
from tblproducts p 
Inner join tblSales s on p.[Prod Code] = s.[product] 
Group by p.[Product Group], p.Product, s.[Qty Sold];

-- sales revenue by salesperson and sale method (using provided tables)
WITH SalesByPersonMethod AS (
    SELECT
        s.SalespersonID,
        m.MethodName AS SaleMethod,
        sd.[Qty Sold] * p.Price AS TransactionTotal
    FROM tblSaleDetails sd
    JOIN tblProducts p ON sd.ProductID = p.ProductID
    JOIN tblSales s ON sd.SaleID = s.SaleID
    JOIN tblSaleMethods m ON s.SaleMethodID = m.SaleMethodID
)
SELECT
    SalespersonID,
    SaleMethod,
    SUM(TransactionTotal) AS Revenue
FROM SalesByPersonMethod
GROUP BY SalespersonID, SaleMethod;

-- use the above CTE to report by assistant with overall total
WITH SalesByPersonMethod AS (
    SELECT
        s.AssistantID,
        m.MethodName AS SaleMethod,
        sd.[Qty Sold] * p.Price AS TransactionTotal
    FROM tblSaleDetails sd
    INNER JOIN tblProducts p ON sd.ProductID = p.ProductID
    INNER JOIN tblSales s ON sd.SaleID = s.SaleID
    INNER JOIN tblSaleMethods m ON s.SaleMethodID = m.SaleMethodID
)
SELECT
    a.AssistantName,
    sbm.SaleMethod,
    SUM(sbm.TransactionTotal) AS Revenue,
    (SELECT SUM(TransactionTotal) FROM SalesByPersonMethod) AS TotalAllSales
FROM SalesByPersonMethod sbm
JOIN tblAssistants a ON sbm.AssistantID = a.AssistantID
GROUP BY a.AssistantName, sbm.SaleMethod;

-- example using OVER() with PARTITION BY (Valeting database)
-- show each salesperson's total sales alongside the total for the sale method
WITH SalesAgg AS (
    SELECT
        sa.SalespersonID,
        m.[Sale Type],
        SUM(sd.Quantity * p.Price) AS Sales
    FROM tblSales sa
    INNER JOIN tblSaleDetails sd  ON sa.SaleNo   = sd.SaleRef
    INNER JOIN tblProducts     p  ON sd.ProdCode  = p.ProdCode
    INNER JOIN tblSaleMethods  m  ON sa.[SaleMethod] = m.[Type Code]
    GROUP BY sa.SalespersonID, m.[Sale Type]
)
SELECT
    SalespersonID,
    [Sale Type],
    Sales,
    SUM(Sales) OVER(PARTITION BY [Sale Type])    AS TotalByMethod,
    SUM(Sales) OVER(PARTITION BY SalespersonID)  AS TotalBySalesperson
FROM SalesAgg;

-- query for Valeting database matching sample output from screenshot
SELECT
    i.InvDate,
    i.Manufacturer,
    i.WorkDone,
    i.Amount,
    i.Quantity,
    AVG(i.Amount / NULLIF(i.Quantity,0)) OVER(PARTITION BY i.WorkDone) AS [Wash type Avg],
    SUM(i.Amount * i.Quantity)                    OVER(PARTITION BY i.Manufacturer) AS [Total for Make]
FROM ValetingSQL.Invoice i;

select pr.[prod group], 
    pr.product, 
    sum(sd.Quantity) as TotalQty,
    rank() over (order by sum(sd.Quantity)) as Ranking,
    rank() over (partition by pr.[prod group] order by sum(sd.Quantity)) as RankInPG,
    row_number() over (order by sum(sd.Quantity)) as RNrank,
   -- dense_rank() over (order by sum(sd.Quantity)) as DRRank
from tblProducts pr
inner join tblSaleDetails sd on pr.ProdCode = sd.ProdCode
group by  pr.product, pr.[prod group]
--order by 1,2
;

-- exercise 3: Row_Number, Rank, Dense_Rank with Valeting data
-- 1 & 2) revenue by country/manufacturer plus three rankings within each country
SELECT
    c.Country,
    m.Manufacturer,
    SUM(i.Amount) AS TotalRevenue,
    ROW_NUMBER() OVER (PARTITION BY c.Country ORDER BY SUM(i.Amount))  AS RN_InCountry,
    RANK()      OVER (PARTITION BY c.Country ORDER BY SUM(i.Amount))  AS Rk_InCountry,
    DENSE_RANK()OVER (PARTITION BY c.Country ORDER BY SUM(i.Amount))  AS DRk_InCountry
FROM ValetingSQL.Invoice   i
JOIN ValetingSQL.Customer  c  ON i.CustomerID     = c.ID
JOIN ValetingSQL.Product   p  ON i.ProductID      = p.ID
JOIN ValetingSQL.Manufacturer m ON p.ManufacturerID = m.ID
WHERE i.Paid = 0
GROUP BY c.Country, m.Manufacturer
ORDER BY c.Country, TotalRevenue;

-- 3) the three functions return identical results as long as there are no ties
--    differences appear when two or more manufacturers in the same country
--    have exactly the same TotalRevenue.  ROW_NUMBER will arbitrarily
--    assign distinct numbers, RANK will repeat the same number and leave a gap
--    afterwards, DENSE_RANK will repeat without gaps.

-- 4) remove PARTITION BY to rank across the entire result set
SELECT
    c.Country,
    m.Manufacturer,
    SUM(i.Amount) AS TotalRevenue,
    ROW_NUMBER() OVER (ORDER BY SUM(i.Amount))  AS RN_Global,
    RANK()      OVER (ORDER BY SUM(i.Amount))  AS Rk_Global,
    DENSE_RANK()OVER (ORDER BY SUM(i.Amount))  AS DRk_Global
FROM ValetingSQL.Invoice   i
JOIN ValetingSQL.Customer  c  ON i.CustomerID     = c.ID
JOIN ValetingSQL.Product   p  ON i.ProductID      = p.ID
JOIN ValetingSQL.Manufacturer m ON p.ManufacturerID = m.ID
WHERE i.Paid = 0
GROUP BY c.Country, m.Manufacturer
ORDER BY TotalRevenue;

with mynumbers as ( 
    select top 250 
    row_number() over (order by (select null)) as n
    from tblInvoices
)
    select N + 1 as MyNo
    from mynumbers; 

    declare @datefrom date = (select Min(invDate) from tblInvoices);
    declare @dateto date = (select Max(invDate) from tblInvoices);

    with tally as (
        select top (datediff(day, @datefrom, @dateto))
        row_number() over (order by (select null)) as n
        from sys.sys.all_objects)
    select dateadd(day, n, @datefrom) as CalandarDate
    from tally
    
-- 1) simple tally 1..500 using ROW_NUMBER
WITH Tally500 AS (
    SELECT TOP (500)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.objects a
    CROSS JOIN sys.objects b
)
SELECT n AS Number
FROM Tally500;

-- 2) date tally covering all invoice dates from Valeting database
DECLARE @MinInvDate DATE = (SELECT MIN(InvDate) FROM ValetingSQL.Invoice);
DECLARE @MaxInvDate DATE = (SELECT MAX(InvDate) FROM ValetingSQL.Invoice);

WITH DateTally AS (
    SELECT TOP (DATEDIFF(day,@MinInvDate,@MaxInvDate) + 1)
           DATEADD(day, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1, @MinInvDate) AS d
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
)
SELECT d AS CalendarDate
FROM DateTally;

-- 3) February daily sales (include days with zero revenue)
WITH DateTally AS (
    SELECT TOP (DATEDIFF(day,@MinInvDate,@MaxInvDate) + 1)
           DATEADD(day, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1, @MinInvDate) AS d
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
)
SELECT
    dt.d AS [Date],
    ISNULL(SUM(i.Amount),0) AS DailySales
FROM DateTally dt
LEFT JOIN ValetingSQL.Invoice i
    ON i.InvDate = dt.d
WHERE dt.d BETWEEN '2026-02-01' AND '2026-02-28'
GROUP BY dt.d
ORDER BY dt.d;
