--Netflix Project

DROP TABLE IF EXISTS netflix_titles;


--Create Table of Netflix Data
CREATE TABLE dbo.netflix_titles (
    show_id        VARCHAR(20),
    type           VARCHAR(50),
    title          VARCHAR(500),
    director       VARCHAR(500),
    cast           VARCHAR(MAX),
    country        VARCHAR(200),
    date_added     VARCHAR(100),
    release_year   INT,
    rating         VARCHAR(20),
    duration       VARCHAR(50),
    listed_in      VARCHAR(500),
    description    VARCHAR(MAX)
);

-- Large Data Set Imported Through BULK INSERT
BULK INSERT dbo.netflix_titles
FROM 'C:\Users\Public\netflix_titles.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

SELECT*FROM netflix_titles;

SELECT
    COUNT(*) as total_content
FROM netflix_titles;

SELECT
    DISTINCT type
FROM netflix_titles;

SELECT
    DISTINCT director
FROM netflix_titles;

-- 15 Business Problems & Solutions
/*
    1. Count the number of Movies vs TV Shows
    2. Find the most common rating for movies and TV shows
    3. List all movies released in a specific year (e.g., 2020)
    4. Find the top 5 countries with the most content on Netflix
    5. Identify the longest movie
    6. Find content added in the last 5 years
    7. Find all the movies/TV shows by director 'Rajiv Chilaka'!
    8. List all TV shows with more than 5 seasons
    9. Count the number of content items in each genre
    10.Find each year and the average numbers of content release in India on netflix. return top 5 year with highest avg 
       content release!
    11. List all movies that are documentaries
    12. Find all content without a director
    13. Find how many movies actor 'Salman Khan' appeared in last 10 years!
    14. Find the top 10 actors who have appeared in the highest number of movies produced in India.
    15.Categorize the content based on the presence of the keywords 'kill' and 'violence' in the description field. Label 
       content containing these keywords as 'Bad' and all other content as 'Good'. Count how many items fall into each 
       category.     */


-- Problem-1 : Count the number of Movies vs TV Shows
SELECT 
     type,
     COUNT(*) as total_content
FROM netflix_titles
GROUP BY type ;

-- Problem-2 : Find the most common rating for movies and TV shows
SELECT 
    type,
    rating
FROM (
    SELECT 
        type,
        rating,
        COUNT(*) AS total_count,
        RANK() OVER(PARTITION BY type ORDER BY COUNT(*) DESC) AS ranking
    FROM netflix_titles
    GROUP BY type, rating
) AS t1
WHERE ranking = 1;


-- Problem-3 : List all movies released in a specific year (e.g., 2020)
SELECT * FROM netflix_titles
WHERE 
      type = 'Movie'
      AND
      release_year = 2020;


-- Problem-4 : Find the top 5 countries with the most content on Netflix
SELECT TOP 5
    TRIM(value) AS country,
    COUNT(*) AS total_content
FROM netflix_titles
CROSS APPLY STRING_SPLIT(country, ',')
GROUP BY TRIM(value)
ORDER BY total_content DESC;


-- Problem-5 : Identify the longest movie
SELECT * FROM netflix_titles
WHERE 
    type = 'Movie'
    AND
    duration = (SELECT MAX(duration) FROM netflix_titles);


-- Problem-6 : Find content added in the last 5 years
SELECT * FROM netflix_titles
WHERE TRY_CONVERT(date, date_added, 106) >= DATEADD(YEAR, -5, GETDATE());


-- Problem-7 : Find all the movies/TV shows by director 'Rajiv Chilaka'!
SELECT * FROM netflix_titles
WHERE director LIKE '%Rajiv Chilaka%' ;


-- Problem-8 : List all TV shows with more than 5 seasons
SELECT *
FROM netflix_titles
WHERE type = 'TV Show'
  AND TRY_CONVERT(int,
        LEFT(duration, CHARINDEX(' ', duration + ' ') - 1)
      ) > 5;

-- Problem-9 : Count the number of content items in each genre(listed_in column)
SELECT 
    value AS genre,
    COUNT(*) AS total_content
FROM netflix_titles
CROSS APPLY STRING_SPLIT(listed_in, ',')
GROUP BY value
ORDER BY total_content DESC;


-- Problem-10 : Find each year and the average numbers of content release in India on netflix. return top 5 year with highest avg content release!
SELECT 
    release_year,
    COUNT(*) * 1.0 AS total_contents,
    AVG(COUNT(*)) OVER () AS avg_contents_overall
FROM netflix_titles
WHERE country LIKE '%India%'
GROUP BY release_year
ORDER BY total_contents DESC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;


-- Problem-11 : List all movies that are documentaries
SELECT * FROM netflix_titles
WHERE listed_in LIKE '%Documentaries%' ;


-- Problem-12 : Find all content without a director
SELECT * FROM netflix_titles
WHERE director IS NULL;


-- Problem-13 : Find how many movies actor 'Salman Khan' appeared in last 10 years!
SELECT *
FROM netflix_titles
WHERE cast LIKE '%Salman Khan%'
  AND release_year >= YEAR(GETDATE()) - 10;


-- Problem-14 : Find the top 10 actors who have appeared in the highest number of movies produced in India.
SELECT TOP 10  
    TRIM(value) AS actor,
    COUNT(*) AS total_movies
FROM netflix_titles
CROSS APPLY STRING_SPLIT(cast, ',')  -- split actors
WHERE country LIKE '%India%'          -- movies produced in India
GROUP BY TRIM(value)
ORDER BY total_movies DESC;


-- Problem-15 : Categorize the content based on the presence of the keywords 'kill' and 'violence' in the description field. 
 /*            Label content containing these keywords as 'Bad' and all other content as 'Good'. Count how many items fall
               into each category.    */
WITH new_table
AS
(
    SELECT 
		*,
        CASE 
        WHEN 
            description LIKE '%kill%' OR 
            description LIKE '%violence%' THEN 'Bad_content'
            ELSE 'Good_content'
        END category
    FROM netflix_titles
) 
SELECT 
    category,
    COUNT(*) AS total_content
FROM new_table
GROUP BY category;
