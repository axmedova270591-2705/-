CREATE DATABASE Customers_trasaction;
UPDATE customers SET Gender = NULL WHERE Gender ='';
UPDATE customers SET Age = NULL WHERE Age ='';
ALTER TABLE customers MODIFY AGE INT NULL; 

SELECT * FROM customers;

CREATE TABLE Transactions
(date_new DATE,
Id_check INT,
ID_client INT,
Count_products DECIMAL(10,3),
Sum_payment DECIMAL(10,2)
);

LOAD DATA INFILE "C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\TRANSACTIONS1.csv"
INTO TABLE transactions
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SHOW VARIABLES LIKE 'SECURE_FILE_PRIV';
SELECT * FROM transactions;

#Задание 1
WITH monthly_transactions AS (
    SELECT 
        ID_client,
        DATE_FORMAT(date_new, '%Y-%m') AS transaction_month,
        COUNT(ID_check) AS operations_count,
        AVG(Sum_payment) AS avg_check,
        SUM(Sum_payment) AS total_sum
    FROM Transactions
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY ID_client, DATE_FORMAT(date_new, '%Y-%m')
),
clients_with_full_history AS (
    SELECT ID_client
    FROM monthly_transactions
    GROUP BY ID_client
    HAVING COUNT(DISTINCT transaction_month) = 12  
)
SELECT 
    ch.ID_client,
    AVG(mt.avg_check) AS avg_check_over_period,  
    SUM(mt.total_sum) / 12 AS avg_monthly_payment, 
    SUM(mt.operations_count) AS total_operations 
FROM clients_with_full_history ch
JOIN monthly_transactions mt ON ch.ID_client = mt.ID_client
GROUP BY ch.ID_client;

SELECT * FROM transactions;

#Задание 2
WITH monthly_stats AS (
    SELECT 
        DATE_FORMAT(t.date_new, '%Y-%m') AS month,    
        COUNT(DISTINCT t.ID_client) AS clients_count,
        COUNT(t.Id_check) AS operations_count,        
        SUM(t.Sum_payment) AS total_sum,             
        AVG(t.Sum_payment) AS avg_check         
    FROM Transactions t
    WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY DATE_FORMAT(t.date_new, '%Y-%m')
),
annual_totals AS (
    SELECT 
        SUM(operations_count) AS total_operations_year,   
        SUM(total_sum) AS total_sum_year                 
    FROM monthly_stats
),
gender_distribution AS (
    SELECT
        DATE_FORMAT(t.date_new, '%Y-%m') AS month,
        SUM(CASE WHEN c.Gender = 'M' THEN t.Sum_payment ELSE 0 END) AS male_spent,
        SUM(CASE WHEN c.Gender = 'F' THEN t.Sum_payment ELSE 0 END) AS female_spent,
        SUM(CASE WHEN c.Gender IS NULL THEN t.Sum_payment ELSE 0 END) AS na_spent,
        COUNT(DISTINCT CASE WHEN c.Gender = 'M' THEN t.ID_client ELSE NULL END) AS male_count,
        COUNT(DISTINCT CASE WHEN c.Gender = 'F' THEN t.ID_client ELSE NULL END) AS female_count,
        COUNT(DISTINCT CASE WHEN c.Gender IS NULL THEN t.ID_client ELSE NULL END) AS na_count
    FROM Transactions t
    JOIN Customers c ON t.ID_client = c.ID_client
    WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY DATE_FORMAT(t.date_new, '%Y-%m')
)
SELECT 
    ms.month,
    ms.avg_check AS average_check_per_month,                
    ms.operations_count AS avg_operations_per_month,         
    ms.clients_count AS avg_clients_per_month,               
    ms.operations_count / at.total_operations_year AS operation_share_per_month, 
    ms.total_sum / at.total_sum_year AS sum_share_per_month, 
    gd.male_spent / ms.total_sum * 100 AS male_share,       
    gd.female_spent / ms.total_sum * 100 AS female_share,  
    gd.na_spent / ms.total_sum * 100 AS na_share,            
    gd.male_count / ms.clients_count * 100 AS male_count_share, 
    gd.female_count / ms.clients_count * 100 AS female_count_share, 
    gd.na_count / ms.clients_count * 100 AS na_count_share  
FROM 
    monthly_stats ms
    CROSS JOIN annual_totals at
    JOIN gender_distribution gd ON ms.month = gd.month
ORDER BY ms.month;

#Задание 3
WITH age_groups AS (
    SELECT ID_client,
           CASE 
               WHEN AGE BETWEEN 0 AND 9 THEN '0-9'
               WHEN AGE BETWEEN 10 AND 19 THEN '10-19'
               WHEN AGE BETWEEN 20 AND 29 THEN '20-29'
               WHEN AGE BETWEEN 30 AND 39 THEN '30-39'
               WHEN AGE BETWEEN 40 AND 49 THEN '40-49'
               WHEN AGE BETWEEN 50 AND 59 THEN '50-59'
               WHEN AGE BETWEEN 60 AND 69 THEN '60-69'
               WHEN AGE BETWEEN 70 AND 79 THEN '70-79'
               ELSE 'Unknown'
           END AS age_group
    FROM Customers
)
SELECT age_group, 
       COUNT(t.ID_check) AS operations_count, 
       SUM(t.Sum_payment) AS total_sum,
       AVG(Sum_payment) AS avg_payment_per_quarter,
       (COUNT(ID_check) * 100) / (SELECT COUNT(ID_check) FROM Transactions WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01') AS percentage
FROM Transactions t
JOIN age_groups a ON t.ID_client = a.ID_client
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY age_group;

#Задание 4
WITH age_groups AS (
    SELECT 
        CASE 
            WHEN AGE IS NULL THEN 'Unknown'
            WHEN AGE BETWEEN 0 AND 9 THEN '0-9'
            WHEN AGE BETWEEN 10 AND 19 THEN '10-19'
            WHEN AGE BETWEEN 20 AND 29 THEN '20-29'
            WHEN AGE BETWEEN 30 AND 39 THEN '30-39'
            WHEN AGE BETWEEN 40 AND 49 THEN '40-49'
            WHEN AGE BETWEEN 50 AND 59 THEN '50-59'
            WHEN AGE BETWEEN 60 AND 69 THEN '60-69'
            WHEN AGE BETWEEN 70 AND 79 THEN '70-79'
            ELSE '80+'
        END AS age_group,
        c.ID_client,
        t.date_new,
        t.Sum_payment,
        t.Id_check
    FROM Customers c
    JOIN Transactions t ON c.ID_client = t.ID_client
    WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
),
quarterly_stats AS (
    SELECT 
        age_group,
        QUARTER(t.date_new) AS quarter,
        COUNT(DISTINCT t.Id_check) AS operations_count, 
        SUM(t.Sum_payment) AS total_sum,                
        COUNT(DISTINCT t.ID_client) AS clients_count,   
        AVG(t.Sum_payment) AS avg_sum_per_operation     
    FROM age_groups t
    GROUP BY age_group, QUARTER(t.date_new) 
),
annual_stats AS (
    SELECT 
        age_group,
        COUNT(DISTINCT t.Id_check) AS total_operations_year, 
        SUM(t.Sum_payment) AS total_sum_year,                
        COUNT(DISTINCT t.ID_client) AS total_clients_year    
    FROM age_groups t
    GROUP BY age_group
)
SELECT 
    qs.age_group,
    qs.quarter,
    SUM(qs.operations_count) AS quarterly_operations,            
    SUM(qs.total_sum) AS quarterly_sum,                          
    AVG(qs.avg_sum_per_operation) AS avg_sum_per_operation,    
    SUM(qs.clients_count) AS clients_per_quarter,                
    SUM(qs.operations_count) / ast.total_operations_year * 100 AS operation_share_quarter,
    SUM(qs.total_sum) / ast.total_sum_year * 100 AS sum_share_quarter                    
FROM quarterly_stats qs
JOIN annual_stats ast ON qs.age_group = ast.age_group
GROUP BY qs.age_group, qs.quarter -- Добавляем группировку в итоговом запросе
ORDER BY qs.age_group, qs.quarter;