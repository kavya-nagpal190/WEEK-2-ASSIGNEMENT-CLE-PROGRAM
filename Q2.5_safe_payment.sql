-- Customer, order and item data
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
GO

/* =====================================================================
   Q2.5  Safe Payment Posting with Error Handling
   (uses orders and order_items from Q2.2)
   ===================================================================== */
DROP TABLE IF EXISTS error_log;
DROP TABLE IF EXISTS payments;
GO

CREATE TABLE payments (                 -- no FK: the gateway does not check the order
    payment_id    VARCHAR(10) PRIMARY KEY,
    order_id      INT,
    payment_date  DATE,
    amount        INT,
    method        VARCHAR(20)
);

CREATE TABLE error_log (
    log_id        INT IDENTITY(1,1) PRIMARY KEY,
    error_time    DATETIME2 DEFAULT SYSDATETIME(),
    proc_name     VARCHAR(100),
    error_number  INT,
    error_message NVARCHAR(4000),
    input_values  NVARCHAR(500)
);

INSERT INTO payments (payment_id, order_id, payment_date, amount, method)
VALUES ('PM01', 1001, '2026-03-02', 2198, 'UPI'),
       ('PM02', 1002, '2026-03-03', 1000, 'Card'),
       ('PM03', 1002, '2026-03-05',  999, 'Card'),
       ('PM04', 1003, '2026-03-10',  500, 'UPI'),
       ('PM05', 1005, '2026-03-15', 3998, 'NetBanking'),
       ('PM06', 1006, '2026-03-18', 1497, 'UPI'),
       ('PM07', 1009, '2026-04-02',  750, 'UPI'),
       ('PM08', 1004, '2026-03-12', 1499, 'Card');
GO

CREATE OR ALTER PROCEDURE dbo.sp_record_payment
    @payment_id  VARCHAR(10),
    @order_id    INT,
    @amount      INT,
    @method      VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @status VARCHAR(15), @order_value INT, @already_paid INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Rule 1: order must exist
        SELECT @status = status FROM orders WHERE order_id = @order_id;
        IF @status IS NULL
            THROW 50001, 'Order not found', 1;

        -- Rule 2: order must not be cancelled
        IF @status = 'Cancelled'
            THROW 50002, 'Order is cancelled', 1;

        -- Rule 3: amount must be positive
        IF @amount <= 0
            THROW 50003, 'Amount must be greater than zero', 1;

        -- Rule 4: total paid must not exceed order value
        SELECT @order_value = ISNULL(SUM(qty * unit_price), 0)
        FROM   order_items WHERE order_id = @order_id;

        SELECT @already_paid = ISNULL(SUM(amount), 0)
        FROM   payments WHERE order_id = @order_id;

        IF @already_paid + @amount > @order_value
            THROW 50004, 'Payment exceeds order value', 1;

        INSERT INTO payments (payment_id, order_id, payment_date, amount, method)
        VALUES (@payment_id, @order_id, CAST(GETDATE() AS DATE), @amount, @method);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;       -- undo the change first

        INSERT INTO error_log (proc_name, error_number, error_message, input_values)
        VALUES (OBJECT_NAME(@@PROCID),
                ERROR_NUMBER(),
                ERROR_MESSAGE(),
                CONCAT(@payment_id, ',', @order_id, ',', @amount, ',', @method));
    END CATCH;
END;
GO

-- Test calls
EXEC dbo.sp_record_payment @payment_id = 'PM09', @order_id = 1007, @amount = 1499, @method = 'Card';   -- OK
EXEC dbo.sp_record_payment @payment_id = 'PM10', @order_id = 1010, @amount =  500, @method = 'UPI';    -- 50001
EXEC dbo.sp_record_payment @payment_id = 'PM11', @order_id = 1004, @amount =  100, @method = 'UPI';    -- 50002
EXEC dbo.sp_record_payment @payment_id = 'PM12', @order_id = 1003, @amount =    0, @method = 'UPI';    -- 50003
EXEC dbo.sp_record_payment @payment_id = 'PM13', @order_id = 1003, @amount =  600, @method = 'UPI';    -- 50004
EXEC dbo.sp_record_payment @payment_id = 'PM14', @order_id = 1003, @amount =  499, @method = 'UPI';    -- OK

-- Payments added
SELECT payment_id, order_id, amount, method
FROM   payments
WHERE  payment_id IN ('PM09','PM10','PM11','PM12','PM13','PM14')
ORDER BY payment_id;

-- Error log
SELECT log_id, proc_name, error_number, error_message, input_values
FROM   error_log
ORDER BY log_id;
GO
