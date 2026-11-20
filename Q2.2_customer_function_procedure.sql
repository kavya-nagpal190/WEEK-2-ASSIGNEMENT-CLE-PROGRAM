-- Q2.2  Customer Order Lookup with a Function and a Stored Procedure
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
GO

CREATE TABLE customers (
    customer_id    VARCHAR(5) PRIMARY KEY,
    customer_name  VARCHAR(40),
    city           VARCHAR(30),
    signup_date    DATE
);

CREATE TABLE orders (
    order_id     INT        PRIMARY KEY,
    customer_id  VARCHAR(5) REFERENCES customers(customer_id),
    order_date   DATE,
    status       VARCHAR(15)
);

CREATE TABLE order_items (
    order_id    INT        REFERENCES orders(order_id),
    product_id  VARCHAR(5),
    qty         INT,
    unit_price  INT,
    PRIMARY KEY (order_id, product_id)
);

INSERT INTO customers (customer_id, customer_name, city, signup_date)
VALUES ('C01', 'Rahul Mehta',    'Jaipur',  '2025-11-02'),
       ('C02', 'Priya Nair',     'Kochi',   '2025-12-15'),
       ('C03', 'Arjun Das',      'Kolkata', '2026-01-08'),
       ('C04', 'Fatima Sheikh',  'Mumbai',  '2026-01-20'),
       ('C05', 'Karan Malhotra', 'Delhi',   '2026-02-11'),
       ('C06', 'Sneha Kulkarni', 'Pune',    '2026-02-25');

INSERT INTO orders (order_id, customer_id, order_date, status)
VALUES (1001, 'C01', '2026-03-02', 'Delivered'),
       (1002, 'C02', '2026-03-03', 'Delivered'),
       (1003, 'C01', '2026-03-10', 'Delivered'),
       (1004, 'C03', '2026-03-12', 'Cancelled'),
       (1005, 'C04', '2026-03-15', 'Shipped'),
       (1006, 'C05', '2026-03-18', 'Delivered'),
       (1007, 'C01', '2026-04-01', 'Shipped'),
       (1008, 'C06', '2026-04-03', 'Pending');

INSERT INTO order_items (order_id, product_id, qty, unit_price)
VALUES (1001, 'P1',  2,  799),
       (1001, 'P3',  5,  120),
       (1002, 'P2',  1, 1999),
       (1003, 'P4',  2,  250),
       (1003, 'P6',  1,  499),
       (1004, 'P5',  1, 1499),
       (1005, 'P1',  1,  799),
       (1005, 'P2',  1, 1999),
       (1005, 'P3', 10,  120),
       (1006, 'P6',  3,  499),
       (1007, 'P5',  1, 1499),
       (1008, 'P4',  4,  250);
GO

-- Function to format the date
CREATE OR ALTER FUNCTION dbo.fn_format_us_date (@d DATETIME2)
RETURNS VARCHAR(10)
AS
BEGIN
    RETURN CONVERT(VARCHAR(10), @d, 101);
END;
GO

SELECT dbo.fn_format_us_date('2006-11-21 23:34:05.920') AS us_date;     -- 11/21/2006
GO

-- Procedure with two output parameters
CREATE OR ALTER PROCEDURE dbo.sp_customer_orders
    @customer_id  VARCHAR(5),
    @order_count  INT           OUTPUT,
    @total_value  DECIMAL(10,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @result TABLE (
        order_id       INT,
        order_date_us  VARCHAR(10),
        status         VARCHAR(15),
        order_value    INT
    );

    -- Get this customer's non-cancelled orders
    INSERT INTO @result (order_id, order_date_us, status, order_value)
    SELECT o.order_id,
           dbo.fn_format_us_date(o.order_date),
           o.status,
           ISNULL(SUM(oi.qty * oi.unit_price), 0)
    FROM   orders o
    LEFT JOIN order_items oi ON oi.order_id = o.order_id
    WHERE  o.customer_id = @customer_id
      AND  o.status <> 'Cancelled'
    GROUP BY o.order_id, o.order_date, o.status;

    SELECT order_id, order_date_us, status, order_value
    FROM   @result
    ORDER BY order_id;

    SELECT @order_count = COUNT(*),
           @total_value = ISNULL(SUM(order_value), 0)      -- 0 / 0 when no rows
    FROM   @result;
END;
GO

-- Test an existing customer
DECLARE @cnt INT, @val DECIMAL(10,2);
EXEC dbo.sp_customer_orders @customer_id = 'C01', @order_count = @cnt OUTPUT, @total_value = @val OUTPUT;
SELECT @cnt AS order_count, @val AS total_value;
GO

-- Test a customer that does not exist
DECLARE @cnt INT, @val DECIMAL(10,2);
EXEC dbo.sp_customer_orders @customer_id = 'C99', @order_count = @cnt OUTPUT, @total_value = @val OUTPUT;
SELECT @cnt AS order_count, @val AS total_value;
GO
