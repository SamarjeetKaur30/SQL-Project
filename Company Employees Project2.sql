CREATE DATABASE company;
USE company;

CREATE TABLE departments (
  dept_id INT PRIMARY KEY,
  dept_name VARCHAR(100),
  location VARCHAR(100)
);

CREATE TABLE employees (
  employee_id INT PRIMARY KEY,
  name VARCHAR(100),
  gender VARCHAR(20),
  age INT,
  dept_id INT,
  position VARCHAR(100),
  hire_date DATE,
  city VARCHAR(80),
  province VARCHAR(10),
  experience_years INT,
  FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE salaries (
  employee_id INT,
  base_salary DECIMAL(10,2),
  bonus_pct DECIMAL(5,2),
  PRIMARY KEY (employee_id),
  FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

CREATE TABLE projects (
  project_id INT PRIMARY KEY,
  project_name VARCHAR(120),
  dept_id INT,
  start_date DATE,
  end_date DATE,
  FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE performance_reviews (
  employee_id INT,
  review_year INT,
  rating DECIMAL(3,1),
  PRIMARY KEY (employee_id, review_year),
  FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

CREATE TABLE employee_projects (
  employee_id INT,
  project_id INT,
  role VARCHAR(60),
  allocation_pct INT,
  PRIMARY KEY (employee_id, project_id),
  FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
  FOREIGN KEY (project_id) REFERENCES projects(project_id)
);

SELECT * FROM departments;
SELECT * FROM employees;
SELECT * FROM salaries;
SELECT * FROM projects;
SELECT * FROM performance_reviews;
SELECT * FROM employee_projects;

SELECT dept.dept_name, COUNT(emp.name) AS total_employees,
ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM employees), 2) AS percent_share
FROM employees emp
JOIN departments dept ON dept.dept_id = emp.dept_id
GROUP BY dept.dept_name;

SELECT d.dept_name, e.name AS employee_name, e.position,
ROUND((base_salary + base_salary*bonus_pct/100), 2) AS total_compensation
FROM departments d 
JOIN employees e ON d.dept_id = e.dept_id
JOIN salaries s ON s.employee_id = e.employee_id
ORDER BY total_compensation DESC
LIMIT 10;

SELECT d.dept_name, 
ROUND(AVG(base_salary), 2) AS avg_base_salary, 
MIN(base_salary) AS min_base_salary, 
MAX(base_salary) AS max_base_salary, 
COUNT(e.name) AS total_emp,
RANK() OVER (ORDER BY d.dept_name DESC) AS rank_dept_name
FROM departments d 
JOIN employees e ON d.dept_id = e.dept_id
JOIN salaries s ON s.employee_id = e.employee_id
GROUP BY d.dept_name;


SELECT CASE WHEN TIMESTAMPDIFF(year, e.hire_date, curdate()) <= 1 THEN '0-1'
WHEN TIMESTAMPDIFF(year, e.hire_date, curdate()) <= 4 THEN '2-4'
WHEN TIMESTAMPDIFF(year, e.hire_date, curdate()) <= 9 THEN '5-9'
ELSE '10+'
END AS tenure_bucket,
COUNT(e.name) AS total_employees, 
ROUND(AVG(s.base_salary), 2) AS avg_salary
FROM employees e
JOIN salaries s ON s.employee_id = e.employee_id
GROUP BY tenure_bucket
ORDER BY FIELD(tenure_bucket, '0-1', '2-4', '5-9', '10+');


WITH monthly_hires AS (
SELECT d.dept_name, COUNT(e.name) AS total_emp, DATE_FORMAT(e.hire_date, '%y-%m') AS year_mon
FROM departments d 
JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_name, year_mon
)
SELECT dept_name, total_emp, year_mon, 
SUM(total_emp) OVER (PARTITION BY dept_name ORDER BY year_mon DESC) AS headcount
FROM monthly_hires;


SELECT d.dept_name, ROUND(AVG(base_salary), 2) AS avg_base_salary,
CASE WHEN e.position LIKE '%Manager%' THEN 'Managerial Role'
ELSE 'Individual Contributor'
END AS employee_role
FROM departments d 
JOIN employees e ON d.dept_id = e.dept_id
JOIN salaries s ON s.employee_id = e.employee_id
GROUP BY d.dept_name, employee_role;

SELECT d.dept_name, COUNT(project_name)
FROM departments d 
JOIN projects p ON d.dept_id = p.dept_id
GROUP BY d.dept_name;

SELECT d.dept_name, COUNT(project_name) AS total_projects, SUM(DATEDIFF(p.end_date, p.start_date)) AS total_days
FROM departments d 
JOIN projects p ON d.dept_id = p.dept_id
GROUP BY d.dept_name;

SELECT d.dept_name, p.project_name, p.start_date, p.end_date
FROM departments d 
JOIN projects p ON d.dept_id = p.dept_id
WHERE p.start_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 60 DAY);

WITH CTE AS (
SELECT d.dept_name, e.name, AVG(p_review.rating) AS rating
FROM performance_reviews p_review
JOIN employees e ON p_review.employee_id = e.employee_id
JOIN departments d ON d.dept_id = e.dept_id
GROUP BY d.dept_name, e.name
)
SELECT dept_name, name, ROUND((rating), 2) AS avg_rating,
CASE WHEN rating >= 4.0 THEN 'High'
WHEN rating BETWEEN 3.0 AND 3.9 THEN 'Medium'
ELSE 'Low'
END AS rating_class
FROM CTE
ORDER BY FIELD(rating_class, 'High', 'Medium', 'Low');

WITH comparison AS (
SELECT d.dept_name, e.name, 
MAX(CASE WHEN p_review.review_year = 2023 THEN p_review.rating END) AS rating2023,
MAX(CASE WHEN p_review.review_year = 2025 THEN p_review.rating END) AS rating2025
FROM performance_reviews p_review
JOIN employees e ON p_review.employee_id = e.employee_id
JOIN departments d ON d.dept_id = e.dept_id
GROUP BY d.dept_name, e.name
)
SELECT dept_name, name, rating2023, rating2025, ROUND(rating2025-rating2023, 2) delta
FROM comparison
WHERE (rating2025-rating2023) >= 0.5;


SELECT e.name,
SUM(ep.allocation_pct) AS total_allocated_pct,
CASE WHEN SUM(ep.allocation_pct) > 100 THEN 'Over-allocated' 
ELSE 'Fine' END AS allocation_class
FROM employees e
JOIN employee_projects ep ON e.employee_id = ep.employee_id
GROUP BY e.name
LIMIT 15;

SELECT p.project_id, p.project_name, d.dept_name AS home_dept,
COUNT(DISTINCT ep.employee_id) AS team_size
FROM projects p
JOIN departments d ON p.dept_id = d.dept_id
JOIN employee_projects ep ON ep.project_id = p.project_id
GROUP BY p.project_id, p.project_name, d.dept_name;

WITH emp_avg_rate AS
(SELECT e.employee_id, e.dept_id, AVG(p_review.rating) AS avg_rating
FROM performance_reviews p_review
JOIN employees e ON p_review.employee_id = e.employee_id
GROUP BY e.employee_id, e.dept_id)
SELECT d.dept_name, 
COUNT(CASE WHEN emp_avg_rate.avg_rating >= 4.2 THEN 1 END) AS High_Performers,
ROUND(AVG(s.base_salary + s.bonus_pct), 2) AS avg_total_compensation
FROM emp_avg_rate
JOIN employees e ON e.employee_id = emp_avg_rate.employee_id
JOIN salaries s ON s.employee_id = e.employee_id
JOIN departments d ON d.dept_id = e.dept_id
GROUP BY d.dept_name
ORDER BY High_Performers DESC, avg_total_compensation DESC;
