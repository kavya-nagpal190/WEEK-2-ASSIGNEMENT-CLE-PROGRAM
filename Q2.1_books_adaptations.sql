-- Q2.1  Books That Were Beaten by Their Adaptation
DROP TABLE IF EXISTS book_review;
DROP TABLE IF EXISTS adaptation;
DROP TABLE IF EXISTS book;
DROP TABLE IF EXISTS author;

CREATE TABLE author (
    author_id    INT PRIMARY KEY,
    author_name  VARCHAR(40)
);

CREATE TABLE book (
    book_id       INT PRIMARY KEY,
    author_id     INT REFERENCES author(author_id),
    title         VARCHAR(60),
    publish_year  INT
);

CREATE TABLE adaptation (                 -- each book has at most one adaptation
    book_id       INT PRIMARY KEY REFERENCES book(book_id),
    type          VARCHAR(10),
    title         VARCHAR(60),
    release_year  INT,
    rating        DECIMAL(3,1)
);

CREATE TABLE book_review (
    review_id  INT PRIMARY KEY,
    book_id    INT REFERENCES book(book_id),
    rating     INT
);

INSERT INTO author (author_id, author_name)
VALUES (1, 'Anita Rao'), (2, 'Dev Malhotra'), (3, 'Kiran Sethi'), (4, 'Leela Thomas');

INSERT INTO book (book_id, author_id, title, publish_year)
VALUES (101, 1, 'The Monsoon Letters', 2015),
       (102, 1, 'City of Lanterns',    2018),
       (103, 2, 'Code of the Hills',   2012),
       (104, 3, 'The Last Tea Garden', 2019),
       (105, 4, 'Silent Harbour',      2016),
       (106, 2, 'Paper Kites',         2020);

INSERT INTO adaptation (book_id, type, title, release_year, rating)
VALUES (101, 'Movie',  'Monsoon Letters', 2017, 8.1),
       (102, 'Series', 'Lanterns',        2024, 7.9),
       (103, 'Movie',  'Hill Code',       2014, 7.0),
       (104, 'Series', 'Tea Garden',      2022, 8.6),
       (105, 'Movie',  'Harbour',         2018, 6.5),
       (106, 'Movie',  'Kites',           2021, 7.4);

INSERT INTO book_review (review_id, book_id, rating)
VALUES (1,101,7),(2,101,8),(3,102,6),(4,102,7),(5,103,8),(6,103,7),(7,103,9),
       (8,104,8),(9,104,8),(10,105,6),(11,105,7),(12,106,7),(13,106,7),(14,106,7);

SELECT
    b.title                AS book_title,
    ad.title               AS adaptation_title,
    ad.release_year        AS adaptation_year,
    b.publish_year         AS publication_year,
    au.author_name,
    br.book_rating,
    CAST(ad.rating AS DECIMAL(4,2)) AS adaptation_rating
FROM book b
JOIN author     au ON au.author_id = b.author_id
JOIN adaptation ad ON ad.book_id   = b.book_id
JOIN (SELECT book_id,
             CAST(AVG(CAST(rating AS DECIMAL(5,2))) AS DECIMAL(4,2)) AS book_rating
      FROM   book_review
      GROUP BY book_id) br ON br.book_id = b.book_id
WHERE br.book_rating < ad.rating                       -- book rated lower than adaptation
  AND ad.release_year - b.publish_year <= 4            -- adaptation within 4 years of the book
ORDER BY b.title;
GO
