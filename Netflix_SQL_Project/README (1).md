# Netflix Movies and TV Shows Data Analysis using SQL Server

![Netflix Logo](https://github.com/namritasingh1218/netflix_sql_project/blob/main/logo.png)

## Overview
This project involves a comprehensive analysis of Netflix's movies and TV shows data using SQL Server. The goal is to extract valuable insights and answer various business questions based on the dataset. The following README provides a detailed account of the project's objectives, business problems, solutions, findings, and conclusions.


## Objectives

- Analyze the distribution of content types (movies vs TV shows).
- Identify the most common ratings for movies and TV shows.
- List and analyze content based on release years, countries, and durations.
- Explore and categorize content based on specific criteria and keywords.

## Dataset

The data for this project is sourced from the Kaggle dataset:

- **Dataset Link:** [Movies Dataset](https://www.kaggle.com/datasets/shivamb/netflix-shows?resource=download)

## Schema

```sql
DROP TABLE IF EXISTS netflix_titles;
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

```
```sql
BULK INSERT dbo.netflix_titles
FROM 'C:\Users\Public\netflix_titles.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

```

## Business Problems and Solutions

### 1. Count the Number of Movies vs TV Shows

```sql
SELECT 
     type,
     COUNT(*) as total_content
FROM netflix_titles
GROUP BY type ;
```

**Objective:** Determine the distribution of content types on Netflix.

### 2. Find the Most Common Rating for Movies and TV Shows

```sql
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
```

**Objective:** Identify the most frequently occurring rating for each type of content.

### 3. List All Movies Released in a Specific Year (e.g., 2020)

```sql
SELECT * FROM netflix_titles
WHERE 
      type = 'Movie'
      AND
      release_year = 2020;
```

**Objective:** Retrieve all movies released in a specific year.

### 4. Find the Top 5 Countries with the Most Content on Netflix

```sql
SELECT TOP 5
    TRIM(value) AS country,
    COUNT(*) AS total_content
FROM netflix_titles
CROSS APPLY STRING_SPLIT(country, ',')
GROUP BY TRIM(value)
ORDER BY total_content DESC;
```

**Objective:** Identify the top 5 countries with the highest number of content items.

### 5. Identify the Longest Movie

```sql
SELECT * FROM netflix_titles
WHERE 
    type = 'Movie'
    AND
    duration = (SELECT MAX(duration) FROM netflix_titles);
```

**Objective:** Find the movie with the longest duration.

### 6. Find Content Added in the Last 5 Years

```sql
SELECT * FROM netflix_titles
WHERE TRY_CONVERT(date, date_added, 106) >= DATEADD(YEAR, -5, GETDATE());
```

**Objective:** Retrieve content added to Netflix in the last 5 years.

### 7. Find All Movies/TV Shows by Director 'Rajiv Chilaka'

```sql
SELECT * FROM netflix_titles
WHERE director LIKE '%Rajiv Chilaka%' ;
```

**Objective:** List all content directed by 'Rajiv Chilaka'.

### 8. List All TV Shows with More Than 5 Seasons

```sql
SELECT *
FROM netflix_titles
WHERE type = 'TV Show'
  AND TRY_CONVERT(int,
        LEFT(duration, CHARINDEX(' ', duration + ' ') - 1)
      ) > 5;
```

**Objective:** Identify TV shows with more than 5 seasons.

### 9. Count the Number of Content Items in Each Genre

```sql
SELECT 
    value AS genre,
    COUNT(*) AS total_content
FROM netflix_titles
CROSS APPLY STRING_SPLIT(listed_in, ',')
GROUP BY value
ORDER BY total_content DESC;
```

**Objective:** Count the number of content items in each genre.

### 10.Find each year and the average numbers of content release in India on netflix. 
return top 5 year with highest avg content release!

```sql
SELECT 
    release_year,
    COUNT(*) * 1.0 AS total_contents,
    AVG(COUNT(*)) OVER () AS avg_contents_overall
FROM netflix_titles
WHERE country LIKE '%India%'
GROUP BY release_year
ORDER BY total_contents DESC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;
```

**Objective:** Calculate and rank years by the average number of content releases by India.

### 11. List All Movies that are Documentaries

```sql
SELECT * FROM netflix_titles
WHERE listed_in LIKE '%Documentaries%' ;
```

**Objective:** Retrieve all movies classified as documentaries.

### 12. Find All Content Without a Director

```sql
SELECT * FROM netflix_titles
WHERE director IS NULL;
```

**Objective:** List content that does not have a director.

### 13. Find How Many Movies Actor 'Salman Khan' Appeared in the Last 10 Years

```sql
SELECT *
FROM netflix_titles
WHERE cast LIKE '%Salman Khan%'
  AND release_year >= YEAR(GETDATE()) - 10;
```

**Objective:** Count the number of movies featuring 'Salman Khan' in the last 10 years.

### 14. Find the Top 10 Actors Who Have Appeared in the Highest Number of Movies Produced in India

```sql
SELECT TOP 10  
    TRIM(value) AS actor,
    COUNT(*) AS total_movies
FROM netflix_titles
CROSS APPLY STRING_SPLIT(cast, ',')  
WHERE country LIKE '%India%'         
GROUP BY TRIM(value)
ORDER BY total_movies DESC;
```

**Objective:** Identify the top 10 actors with the most appearances in Indian-produced movies.

### 15. Categorize Content Based on the Presence of 'Kill' and 'Violence' Keywords

```sql
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
```

**Objective:** Categorize content as 'Bad' if it contains 'kill' or 'violence' and 'Good' otherwise. Count the number of items in each category.

## Findings and Conclusion

- **Content Distribution:** The dataset contains a diverse range of movies and TV shows with varying ratings and genres.
- **Common Ratings:** Insights into the most common ratings provide an understanding of the content's target audience.
- **Geographical Insights:** The top countries and the average content releases by India highlight regional content distribution.
- **Content Categorization:** Categorizing content based on specific keywords helps in understanding the nature of content available on Netflix.

This analysis provides a comprehensive view of Netflix's content and can help inform content strategy and decision-making.

