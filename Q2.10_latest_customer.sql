-- Q2.10  Keep the Latest Record per Customer
DROP TABLE IF EXISTS customer_updates;

CREATE TABLE customer_updates (
    load_id      INT PRIMARY KEY,
    customer_id  VARCHAR(5),
    email        VARCHAR(40),
    city         VARCHAR(30),
    updated_at   DATETIME2(0)
);

INSERT INTO customer_updates (load_id, customer_id, email, city, updated_at)
VALUES (1, 'C01', 'rahul@mail.com',   'Jaipur',  '2026-05-01 10:00:00'),
       (2, 'C02', 'priya@mail.com',   'Kochi',   '2026-05-01 10:05:00'),
       (3, 'C01', 'rahul.m@mail.com', 'Jaipur',  '2026-05-03 09:00:00'),
       (4, 'C03', 'arjun@mail.com',   'Kolkata', '2026-05-02 12:00:00'),
       (5, 'C02', 'priya@mail.com',   'Kochi',   '2026-05-01 10:05:00'),
       (6, 'C01', 'rahul.m@mail.com', 'Delhi',   '2026-05-03 09:00:00'),
       (7, 'C04', 'fatima@mail.com',  'Mumbai',  '2026-05-04 08:30:00'),
       (8, 'C03', 'arjun.d@mail.com', 'Kolkata', '2026-05-05 18:45:00');

-- Part A: customer_latest (latest updated_at; tie -> bigger load_id)
WITH ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY customer_id
                              ORDER BY updated_at DESC, load_id DESC) AS rn
    FROM customer_updates
)
SELECT customer_id, email, city, updated_at, load_id
FROM   ranked
WHERE  rn = 1
ORDER BY customer_id;

-- Part B: rows loaded / kept / removed
WITH ranked AS (
    SELECT ROW_NUMBER() OVER (PARTITION BY customer_id
                              ORDER BY updated_at DESC, load_id DESC) AS rn
    FROM customer_updates
)
SELECT
    COUNT(*)                                   AS rows_loaded,
    SUM(CASE WHEN rn = 1 THEN 1 ELSE 0 END)    AS rows_kept,
    SUM(CASE WHEN rn > 1 THEN 1 ELSE 0 END)    AS rows_removed
FROM ranked;
GO
