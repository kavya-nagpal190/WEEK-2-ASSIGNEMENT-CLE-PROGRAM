-- Q2.3  Generate Remaining Dates of the Month with a Stored Procedure
DROP TABLE IF EXISTS datepro_data;
DROP TABLE IF EXISTS datepro;
GO

CREATE TABLE datepro (
    id         INT PRIMARY KEY,
    Dateint    INT,              -- YYYYMMDD
    Datentime  VARCHAR(40)       -- ISO text with time zone
);

CREATE TABLE datepro_data (
    Id         INT,
    Dateint    INT,
    Datentime  VARCHAR(20),
    Dates      DATE
);

INSERT INTO datepro (id, Dateint, Datentime)
VALUES (101, 20220510, '2022-05-10T09:30:00+05:30'),
       (102, 20220227, '2022-02-27T18:45:00+05:30'),
       (103, 20220925, '2022-09-25T12:16:00+05:30'),
       (104, 20221229, '2022-12-29T07:05:00+05:30'),
       (105, 20221228, '2022-12-28T11:29:00+05:30');
GO

CREATE OR ALTER PROCEDURE dbo.sp_dateproc
    @ids VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM datepro_data;          -- keep only the rows of this run

    ;WITH cal AS (
        -- Start with the selected date
        SELECT p.id,
               p.Dateint,
               CAST(LEFT(REPLACE(p.Datentime, 'T', ' '), 16) AS VARCHAR(20)) AS Datentime,  -- remove 'T' and time zone
               CONVERT(DATE, CAST(p.Dateint AS CHAR(8)), 112)                AS Dates
        FROM   datepro p
        WHERE  p.id IN (SELECT CAST(LTRIM(RTRIM(value)) AS INT)
                        FROM   STRING_SPLIT(@ids, ','))
        UNION ALL
        -- Add one day until the month ends
        SELECT id, Dateint, Datentime, DATEADD(DAY, 1, Dates)
        FROM   cal
        WHERE  Dates < EOMONTH(Dates)
    )
    INSERT INTO datepro_data (Id, Dateint, Datentime, Dates)
    SELECT id, Dateint, Datentime, Dates
    FROM   cal
    OPTION (MAXRECURSION 100);

    SELECT Id, Dateint, Datentime, Dates
    FROM   datepro_data
    ORDER BY Id, Dates;
END;
GO

EXEC dbo.sp_dateproc '101,102,104';
SELECT COUNT(*) AS total_rows FROM datepro_data;                         -- 27
SELECT Id, COUNT(*) AS rows_per_id FROM datepro_data GROUP BY Id ORDER BY Id;   -- 22 / 2 / 3
GO
