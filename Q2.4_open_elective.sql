-- Q2.4  Open Elective Subject Allotment
DROP TABLE IF EXISTS UnallotedStudents;
DROP TABLE IF EXISTS Allotments;
DROP TABLE IF EXISTS StudentPreference;
DROP TABLE IF EXISTS SubjectDetails;
DROP TABLE IF EXISTS StudentDetails;
GO

CREATE TABLE StudentDetails (
    StudentId    INT PRIMARY KEY,
    StudentName  VARCHAR(40),
    GPA          DECIMAL(4,2),
    Branch       VARCHAR(10),
    Section      CHAR(1)
);

CREATE TABLE SubjectDetails (
    SubjectId       VARCHAR(10) PRIMARY KEY,
    SubjectName     VARCHAR(60),
    MaxSeats        INT,
    RemainingSeats  INT
);

CREATE TABLE StudentPreference (
    StudentId   INT         REFERENCES StudentDetails(StudentId),
    SubjectId   VARCHAR(10) REFERENCES SubjectDetails(SubjectId),
    Preference  INT,
    PRIMARY KEY (StudentId, SubjectId),          -- same subject cannot be chosen twice
    UNIQUE (StudentId, Preference)               -- one subject per preference number
);

CREATE TABLE Allotments       (SubjectId VARCHAR(10), StudentId INT);
CREATE TABLE UnallotedStudents(StudentId INT);

INSERT INTO StudentDetails (StudentId, StudentName, GPA, Branch, Section)
VALUES (159103036, 'Mohit Agarwal',    8.90, 'CCE', 'A'),
       (159103037, 'Rohit Agarwal',    5.20, 'CCE', 'A'),
       (159103038, 'Shohit Garg',      7.10, 'CCE', 'B'),
       (159103039, 'Mrinal Malhotra',  7.90, 'CCE', 'A'),
       (159103040, 'Mehreet Singh',    5.60, 'CCE', 'A'),
       (159103041, 'Arjun Tehlan',     9.20, 'CCE', 'B');

INSERT INTO SubjectDetails (SubjectId, SubjectName, MaxSeats, RemainingSeats)
VALUES ('PO1491', 'Basics of Political Science',   60, 2),
       ('PO1492', 'Basics of Accounting',         120, 1),
       ('PO1493', 'Basics of Financial Markets',   90, 1),
       ('PO1494', 'Eco philosophy',                60, 1),
       ('PO1495', 'Automotive Trends',             60, 0);

INSERT INTO StudentPreference (StudentId, SubjectId, Preference)
VALUES (159103036,'PO1491',1),(159103036,'PO1492',2),(159103036,'PO1493',3),(159103036,'PO1494',4),(159103036,'PO1495',5),
       (159103037,'PO1494',1),(159103037,'PO1495',2),(159103037,'PO1492',3),(159103037,'PO1491',4),(159103037,'PO1493',5),
       (159103038,'PO1492',1),(159103038,'PO1491',2),(159103038,'PO1494',3),(159103038,'PO1495',4),(159103038,'PO1493',5),
       (159103039,'PO1491',1),(159103039,'PO1492',2),(159103039,'PO1495',3),(159103039,'PO1493',4),(159103039,'PO1494',5),
       (159103040,'PO1492',1),(159103040,'PO1494',2),(159103040,'PO1491',3),(159103040,'PO1493',4),(159103040,'PO1495',5),
       (159103041,'PO1491',1),(159103041,'PO1493',2),(159103041,'PO1492',3),(159103041,'PO1494',4),(159103041,'PO1495',5);
GO

-- Process students from highest GPA to lowest
CREATE OR ALTER PROCEDURE dbo.sp_allot_subjects
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @StudentId INT, @SubjectId VARCHAR(10);

    BEGIN TRANSACTION;

    DECLARE student_cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT StudentId
        FROM   StudentDetails
        ORDER BY GPA DESC, StudentId;

    OPEN student_cur;
    FETCH NEXT FROM student_cur INTO @StudentId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @SubjectId = NULL;

        -- Pick the first preference with an available seat
        SELECT TOP 1 @SubjectId = sp.SubjectId
        FROM   StudentPreference sp
        JOIN   SubjectDetails    sd ON sd.SubjectId = sp.SubjectId
        WHERE  sp.StudentId = @StudentId
          AND  sd.RemainingSeats > 0
        ORDER BY sp.Preference;

        IF @SubjectId IS NOT NULL
        BEGIN
            INSERT INTO Allotments (SubjectId, StudentId) VALUES (@SubjectId, @StudentId);

            UPDATE SubjectDetails
            SET    RemainingSeats = RemainingSeats - 1
            WHERE  SubjectId = @SubjectId;
        END
        ELSE
            INSERT INTO UnallotedStudents (StudentId) VALUES (@StudentId);

        FETCH NEXT FROM student_cur INTO @StudentId;
    END;

    CLOSE student_cur;
    DEALLOCATE student_cur;

    COMMIT TRANSACTION;
END;
GO

EXEC dbo.sp_allot_subjects;

SELECT SubjectId, StudentId FROM Allotments;                 -- in allotment order
SELECT StudentId            FROM UnallotedStudents;
SELECT * FROM SubjectDetails ORDER BY SubjectId;             -- all RemainingSeats = 0
GO
