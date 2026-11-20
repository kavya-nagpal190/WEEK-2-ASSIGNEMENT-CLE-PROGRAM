-- Q2.7  Book and Author View with Comma-Separated Names
DROP VIEW  IF EXISTS dbo.vw_book_author;
DROP TABLE IF EXISTS BookAuthors;
DROP TABLE IF EXISTS Books;
DROP TABLE IF EXISTS Authors;
GO

CREATE TABLE Books   (BookID   INT PRIMARY KEY, Title      VARCHAR(40));
CREATE TABLE Authors (AuthorID INT PRIMARY KEY, AuthorName VARCHAR(40));
CREATE TABLE BookAuthors (
    BookID    INT REFERENCES Books(BookID),
    AuthorID  INT REFERENCES Authors(AuthorID),
    PRIMARY KEY (BookID, AuthorID)
);

INSERT INTO Books (BookID, Title)
VALUES (1,'Desert Winds'),(2,'River Songs'),(3,'The Glass Fort'),
       (4,'Night Train'),(5,'Salt and Stone'),(6,'Paper Moons');

INSERT INTO Authors (AuthorID, AuthorName)
VALUES (1,'Meera Kaul'),(2,'Rohan Sen'),(3,'Tanvi Bose'),(4,'Ishita Roy');

INSERT INTO BookAuthors (BookID, AuthorID)
VALUES (1,1),(2,2),(3,1),(3,3),(4,4),(5,2),(6,2),(6,1);
GO

-- Keep author names and counts in the same order
CREATE OR ALTER VIEW dbo.vw_book_author
AS
SELECT
    b.Title                                                            AS Booktitle,
    STRING_AGG(a.AuthorName, ',')
        WITHIN GROUP (ORDER BY a.AuthorName)                           AS Authorname,
    STRING_AGG(CAST(ac.book_cnt AS VARCHAR(10)), ',')
        WITHIN GROUP (ORDER BY a.AuthorName)                           AS Book_count
FROM Books b
JOIN BookAuthors ba ON ba.BookID   = b.BookID
JOIN Authors     a  ON a.AuthorID  = ba.AuthorID
JOIN (SELECT AuthorID, COUNT(*) AS book_cnt
      FROM   BookAuthors
      GROUP BY AuthorID) ac ON ac.AuthorID = a.AuthorID
GROUP BY b.BookID, b.Title;
GO

-- Apply ordering when reading from the view
SELECT v.Booktitle, v.Authorname, v.Book_count
FROM   dbo.vw_book_author v
JOIN   Books b ON b.Title = v.Booktitle
ORDER BY b.BookID;
GO
