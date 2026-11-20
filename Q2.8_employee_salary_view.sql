-- Q2.8  Revised Salary and Comparison with the Previously Hired Employee
DROP VIEW  IF EXISTS dbo.VW_EMP_DEPT;
DROP TABLE IF EXISTS Employee;
DROP TABLE IF EXISTS Dept_loc;
GO

CREATE TABLE Dept_loc (
    deptid    INT PRIMARY KEY,
    deptname  VARCHAR(30),
    loc       VARCHAR(30)
);

CREATE TABLE Employee (
    Empid     INT PRIMARY KEY,
    Full_name VARCHAR(40),
    Salary    INT,
    Hiredate  DATE,
    deptid    INT NULL
);

INSERT INTO Dept_loc (deptid, deptname, loc)
VALUES (1, 'HR',               'Dallas'),
       (2, 'Sales',            'Chicago'),
       (3, 'Customer service', 'Chicago'),
       (4, 'IT',               'Boston'),
       (5, 'Research',         'Seattle'),
       (6, 'Legal',            'New York');

INSERT INTO Employee (Empid, Full_name, Salary, Hiredate, deptid)
VALUES (1012, 'Raji K Nair',       35500, '2018-04-09', 1),
       (1009, 'Jeena',             12000, '2018-11-17', 2),
       (1005, 'Nidhi R Shetty',    10000, '2019-01-16', 3),
       (1011, 'Jiya Shetty',       45500, '2019-03-27', 4),
       (1003, 'Arun Kumar Menon',  45500, '2019-08-02', 5),
       (1007, 'Farah Ali',         30000, '2020-02-10', NULL),
       (1001, 'Manoj P Iyer',      52000, '2020-07-15', 2);
GO

CREATE OR ALTER VIEW dbo.VW_EMP_DEPT
AS
SELECT
    e.Empid,
    -- Keep the first and last name
    CASE WHEN CHARINDEX(' ', n.nm) = 0 THEN n.nm
         ELSE LEFT(n.nm, CHARINDEX(' ', n.nm) - 1) + ' '
              + RIGHT(n.nm, CHARINDEX(' ', REVERSE(n.nm)) - 1)
    END                                                         AS Full_name,
    e.Salary,
    CAST(e.Salary *
         CASE d.loc
             WHEN 'Chicago'  THEN 1.05
             WHEN 'Boston'   THEN 1.03
             WHEN 'Dallas'   THEN 1.10
             WHEN 'New York' THEN 1.10
             ELSE 1.00
         END AS DECIMAL(10,2))                                  AS Inc_Sal,
    LAG(e.Salary) OVER (ORDER BY e.Hiredate, e.Empid)           AS Previous_emp_sal,
    e.Hiredate,
    ISNULL(d.deptname, 'NA')                                    AS deptname,
    ISNULL(d.loc,      'NA')                                    AS loc,
    CASE
        WHEN LAG(e.Salary) OVER (ORDER BY e.Hiredate, e.Empid) IS NULL
            THEN 'No previous employee'
        WHEN e.Salary > LAG(e.Salary) OVER (ORDER BY e.Hiredate, e.Empid)
            THEN 'Salary is greater than previously hired employee'
        WHEN e.Salary < LAG(e.Salary) OVER (ORDER BY e.Hiredate, e.Empid)
            THEN 'Salary is less than previously hired employee'
        ELSE 'Salary is same as previously hired employee'
    END                                                         AS message
FROM Employee e
LEFT JOIN Dept_loc d ON d.deptid = e.deptid
CROSS APPLY (SELECT LTRIM(RTRIM(e.Full_name)) AS nm) n;
GO

SELECT * FROM dbo.VW_EMP_DEPT ORDER BY Hiredate;
GO
