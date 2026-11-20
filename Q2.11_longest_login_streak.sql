-- Q2.11  Longest Login Streak per User  (gaps and islands)
DROP TABLE IF EXISTS logins;

CREATE TABLE logins (
    user_id     VARCHAR(5),
    login_date  DATE,
    PRIMARY KEY (user_id, login_date)
);

INSERT INTO logins (user_id, login_date)
VALUES ('U1','2026-03-01'),('U1','2026-03-02'),('U1','2026-03-03'),
       ('U1','2026-03-05'),('U1','2026-03-06'),('U1','2026-03-07'),
       ('U2','2026-03-01'),('U2','2026-03-03'),('U2','2026-03-04'),
       ('U2','2026-03-05'),('U2','2026-03-06'),('U2','2026-03-10'),
       ('U3','2026-03-02'),
       ('U4','2026-03-01'),('U4','2026-03-02'),('U4','2026-03-04'),
       ('U4','2026-03-05'),('U4','2026-03-08'),('U4','2026-03-09');

-- Group consecutive login dates into streaks
WITH numbered AS (
    SELECT user_id, login_date,
           DATEADD(DAY, -CAST(ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY login_date) AS INT),
                   login_date) AS grp
    FROM logins
),
streaks AS (
    SELECT user_id,
           MIN(login_date) AS streak_start,
           MAX(login_date) AS streak_end,
           COUNT(*)        AS streak_days
    FROM   numbered
    GROUP BY user_id, grp
),
ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY user_id
                              ORDER BY streak_days DESC, streak_end DESC) AS rn   -- tie -> latest streak
    FROM streaks
)
SELECT user_id, streak_start, streak_end, streak_days
FROM   ranked
WHERE  rn = 1
ORDER BY user_id;
GO
