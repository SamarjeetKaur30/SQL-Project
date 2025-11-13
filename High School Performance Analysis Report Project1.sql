CREATE DATABASE HIGH_SCHOOL_PERFORMANCE;
USE HIGH_SCHOOL_PERFORMANCE;

CREATE TABLE students (
student_id INT PRIMARY KEY,
name VARCHAR(50),
gender VARCHAR(10),
age INT,
state VARCHAR(20),
primary_guardian VARCHAR(20),
math INT,
reading INT,
writing INT,
science INT,
social_science INT,
total_marks INT,
percentage DECIMAL(5, 2),
performance VARCHAR(10),
attendance_rate DECIMAL(5, 2),
suspensions INT
);

SELECT *
FROM students;

SELECT name, total_marks, percentage
FROM students
ORDER BY percentage DESC;

SELECT student_id, name, total_marks
FROM students
ORDER BY total_marks DESC
LIMIT 5;

SELECT gender, AVG(total_marks) AS avg_marks
FROM students
GROUP BY gender
ORDER BY avg_marks DESC;

SELECT state, AVG(percentage) AS avg_percentage
FROM students
GROUP BY state
ORDER BY avg_percentage DESC;

SELECT 'Math' AS Subject, AVG(math) AS avg_marks
FROM students
UNION ALL
SELECT 'Reading', AVG(reading) AS avg_reading 
FROM students
UNION ALL
SELECT 'Writing', AVG(writing) AS avg_writing
FROM students
UNION ALL 
SELECT 'Science', AVG(science) AS avg_science
FROM students
UNION ALL  
SELECT 'Social Science', AVG(social_science) AS avg_social_science
FROM students
ORDER BY avg_marks DESC
LIMIT 1;

SELECT name, attendance_rate, percentage
FROM students
ORDER BY attendance_rate DESC ;

SELECT name, performance, suspensions
FROM students
WHERE performance = 'Low' AND suspensions >= 1; 

WITH ranking AS (
SELECT name, percentage, RANK() OVER (ORDER BY percentage DESC) AS rank_no
FROM students
)
SELECT *
FROM ranking
WHERE rank_no <= 10;

SELECT primary_guardian, ROUND(AVG(percentage),2) AS avg_percentage
FROM students
GROUP BY primary_guardian;

SELECT name, total_marks
FROM students
WHERE total_marks > (
                     Select AVG(total_marks)
                     FROM students)
ORDER BY total_marks DESC;

SELECT performance, COUNT(name), ROUND(AVG(percentage), 2) AS avg_percentage
FROM students
GROUP BY performance;

