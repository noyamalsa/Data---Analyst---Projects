 

 -- פרויקט מתגלגל 2

 --Q1

SELECT P.ProductID,
       P.Name AS FirstName,
	   P.Color,
	   P.ListPrice,
	   P.Size
FROM Production.Product P LEFT JOIN Sales.SalesOrderDetail SOD
ON P.ProductID= SOD.ProductID
WHERE SOD.ProductID IS NULL

update Sales.Customer set PersonID= CustomerID
where CustomerID<=290
update Sales.Customer set PersonID= CustomerID+ 1700
where CustomerID>= 300 and CustomerID<=350 
update Sales.Customer set PersonID=CustomerID+1700
where CustomerID>=352 and CustomerID<=701


--Q2


SELECT C.CustomerID,
       COALESCE(P.LastName,'unknown') AS LastTName,
       COALESCE (P.FirstName,'unknown') AS FirsName
FROM Sales.Customer C LEFT JOIN Sales.SalesOrderHeader S
ON C.CustomerID= S.CustomerID LEFT JOIN Person.Person P
ON C.PersonID= P.BusinessEntityID
WHERE SalesOrderID IS NULL
ORDER BY C.CustomerID

--Q3

SELECT TOP 10
       C.CustomerID,
	   COALESCE(P.FirstName,'unknown')AS FirstName,
	   COALESCE(P.LastName,'unknown') AS LastName,
	   COUNT(SOH.SalesOrderID) AS TotalOrders
FROM Sales.Customer C LEFT JOIN Person.Person P
ON C.PersonID= P.BusinessEntityID LEFT JOIN Sales.SalesOrderHeader SOH
ON C.CustomerID= SOH.CustomerID
GROUP BY C.CustomerID,P.FirstName,P.LastName
ORDER BY TOTALORDERS DESC



--Q4

SELECT E.HireDate,
       E.JobTitle,
	   COALESCE (P.FirstName,'unknown') AS FirstName,
	   COALESCE(P.LastName,'unknown') AS LastName,
	   COUNT(*) OVER(PARTITION BY E.JOBTITLE) AS TotalEmployeesinJob
FROM HumanResources.Employee E LEFT JOIN Person.Person P
ON E.BusinessEntityID= P.BusinessEntityID
ORDER BY E.JobTitle, E.HireDate

--Q5


WITH LASTWOORDERS AS(
     SELECT   
         CustomerID,
		 SalesOrderID,
		 OrderDate,
		 ROW_NUMBER() OVER(PARTITION BY CUSTOMERID ORDER BY ORDERDATE DESC) AS ORDERANK
FROM Sales.SalesOrderHeader
)
SELECT C.CustomerID,
       COALESCE(P.FirstName, 'UNKNOWN') AS FirstName,
	   COALESCE(P.LastName, 'UNKNOWN') AS LastName,    
	   LTO1.SalesOrderID AS SalesOrderID,
	   LTO1.OrderDate AS LastOrderDate,
	   LTO2.OrderDate AS  PreviousOrderDate
FROM Sales.Customer C LEFT JOIN Person.Person P
ON C.PersonID=P.BusinessEntityID LEFT JOIN LASTWOORDERS LTO1
ON C.CustomerID=LTO1.CustomerID
AND LTO1.ORDERANK=1 LEFT JOIN LASTWOORDERS LTO2
ON C.CustomerID=LTO2.CustomerID
AND LTO2.ORDERANK= 2
WHERE LTO1.SalesOrderID IS NOT NULL
ORDER BY C.CustomerID;

--Q6

WITH OrderTotals AS (
    SELECT 
        YEAR(soh.OrderDate) AS OrderYear, 
        soh.SalesOrderID, 
        p.FirstName,
        p.LastName, 
        SUM(sod.UnitPrice * (1 - sod.UnitPriceDiscount) * sod.OrderQty) AS Total 
    FROM 
        Sales.SalesOrderHeader soh  LEFT JOIN Sales.SalesOrderDetail sod
        ON soh.SalesOrderID = sod.SalesOrderID LEFT JOIN Sales.Customer c
        ON soh.CustomerID = c.CustomerID  LEFT JOIN Person.Person p
        ON c.PersonID = p.BusinessEntityID 
    GROUP BY 
        YEAR(soh.OrderDate), soh.SalesOrderID, p.FirstName, p.LastName 
)

SELECT 
    ot.OrderYear,
    ot.SalesOrderID, 
    ot.FirstName, 
    ot.LastName, 
    ot.Total 
FROM 
    OrderTotals ot
JOIN 
    (
        SELECT 
            OrderYear, 
            MAX(Total) AS MaxTotal
        FROM 
            OrderTotals
        GROUP BY 
            OrderYear
    ) max_totals 
    ON ot.OrderYear = max_totals.OrderYear 
    AND ot.Total = max_totals.MaxTotal 
ORDER BY 
    ot.OrderYear, ot.Total DESC; 


--Q7
	 
SELECT * 
FROM (
    SELECT 
        YEAR(OrderDate) AS OrderYear,      
        MONTH(OrderDate) AS OrderMonth,    
        COUNT(SalesOrderID) AS OrderCount  
    FROM Sales.SalesOrderHeader
    GROUP BY YEAR(OrderDate), MONTH(OrderDate)   
) AS SourceTable  

PIVOT (
    SUM(OrderCount) 
    FOR OrderYear IN ([2011], [2012], [2013], [2014])   
) AS PivotTable  

ORDER BY OrderMonth;



	 --Q8

SELECT YEAR(SOH.OrderDate) AS OrderYear, 
       MONTH (SOH.OrderDate) AS  OrderMonth,
	   SUM(SOD.LineTotal) AS MonthTotal,
	   SUM(SUM(SOD.LINETOTAL)) OVER (PARTITION BY YEAR(SOH.ORDERDATE) ORDER BY MONTH (SOH.ORDERDATE)
	   ) AS Moneyy, 
	   CASE 
	      WHEN GROUPING(MONTH(SOH.ORDERDATE)) = 1 THEN  'Yearly Total'
		  ELSE ''
		  END AS Summaryrow 
FROM Sales.SalesOrderHeader SOH LEFT JOIN Sales.SalesOrderDetail SOD
ON SOH.SalesOrderID= SOD.SalesOrderID
GROUP BY 
   GROUPING SETS(
       (YEAR(SOH.OrderDate), MONTH(SOH.OrderDate)),
	   (YEAR(SOH.OrderDate))
	   )
	   ORDER BY 
	        YEAR(SOH.OrderDate),
			CASE
			   WHEN MONTH(SOH.OrderDate) IS NULL THEN 13 
			   ELSE MONTH (SOH.OrderDate)
			   END;

  --Q9

	WITH EmployeeRanked AS (
    SELECT 
        d.Name AS DepartmentName,
        e.BusinessEntityID AS EmployeeID,
        p.FirstName + ' ' + p.LastName AS FullName,
        e.HireDate,
        DATEDIFF(MONTH, e.HireDate, GETDATE()) AS TenureMonths,
        LAG(p.FirstName + ' ' + p.LastName) OVER (PARTITION BY d.DepartmentID ORDER BY e.HireDate DESC          
        ) AS PreviousEmployee,
        LAG(e.HireDate) OVER (PARTITION BY d.DepartmentID ORDER BY e.HireDate DESC
        ) AS PreviousHireDate
    FROM 
        HumanResources.Employee e LEFT JOIN  HumanResources.EmployeeDepartmentHistory edh
        ON e.BusinessEntityID = edh.BusinessEntityID LEFT JOIN  HumanResources.Department d
        ON edh.DepartmentID = d.DepartmentID LEFT JOIN Person.Person p
        ON e.BusinessEntityID = p.BusinessEntityID
    WHERE 
        edh.EndDate IS NULL 
)
SELECT 
    DepartmentName,
    EmployeeID,
    FullName,
    HireDate,
    TenureMonths,
    PreviousEmployee,
    PreviousHireDate,
    DATEDIFF(DAY, HireDate, PreviousHireDate) AS DaysSincePreviousEmployee
FROM 
    EmployeeRanked
ORDER BY 
    DepartmentName, HireDate DESC;


	--Q10 

	SELECT 
    e.HireDate,
    edh.DepartmentID,
    STUFF((
        SELECT ', ' + p2.FirstName + ' ' + p2.LastName
        FROM HumanResources.Employee e2 LEFT JOIN HumanResources.EmployeeDepartmentHistory edh2
        ON e2.BusinessEntityID = edh2.BusinessEntityID LEFT JOIN Person.Person p2
        ON e2.BusinessEntityID = p2.BusinessEntityID
        WHERE edh2.EndDate IS NULL
            AND e2.HireDate = e.HireDate
            AND edh2.DepartmentID = edh.DepartmentID
        FOR XML PATH('')
    ), 1, 2, '') AS Employees
FROM HumanResources.Employee e LEFT JOIN HumanResources.EmployeeDepartmentHistory edh
       ON e.BusinessEntityID = edh.BusinessEntityID
WHERE edh.EndDate IS NULL
GROUP BY e.HireDate, edh.DepartmentID
ORDER BY e.HireDate, edh.DepartmentID;











 


