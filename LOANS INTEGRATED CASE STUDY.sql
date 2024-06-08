use Loans


-- TASK 1 ( BEGIN ) -- 


-- Write a query to print all the databases available in the SQL Server.--

SELECT * FROM MASTER.DBO.SYSDATABASES

-- Write a query to print the names of the tables from the Loans database. --

select [name]  from sys.tables

-- Write a query to print 5 records in each table-

select top 5 *
from Banker_Data as  b join Loan_Records_Data as lr 
							on b.banker_id=lr.banker_id
			   join Customer_Data as  c 
							on c.customer_id=lr.customer_id
			   join Home_Loan_Data as  h
							on h.loan_id=lr.loan_id

-- TASK 1 ( END ) --


--TASK 2 ( BEGIN ) --

--Q. Find the names of the top 3 cities (based on descending alphabetical order) and corresponding loan percent (in ascending order) 
--with the lowest average loan percent.--


SELECT TOP 3 city FROM Home_Loan_Data 
GROUP BY CITY
ORDER BY city DESC,AVG(LOAN_PERCENT) ASC

--Q. Find the average loan term for loans not for semi-detached and townhome property types, and are in the following list of cities: 
--Sparks, Biloxi, Waco, Las Vegas, and Lansing--


SELECT AVG(LOAN_TERM) AS AVG_TERM FROM Home_Loan_Data
WHERE property_type NOT IN  ('semi-detached','townhome') AND city IN ('Sparks', 'Biloxi', 'Waco', 'Las Vegas','Lansing') 

--Q. Find the city name and the corresponding average property value (using appropriate alias) for cities where the average property value 
--is greater than $3,000,000.--

SELECT city,AVG(property_value) as AVG_PROPERTY_VALUE FROM Home_Loan_Data
group by city
having AVG(property_value) > 3000000


--Q. Find the number of home loans issued in San Francisco.--

SELECT count(*) AS COUNT_OF_HOME_LOANS FROM Home_Loan_Data
where city = 'San Francisco'


--Q. Find the ID, first name, and last name of the top 2 bankers (and corresponding transaction count) involved in the highest number of distinct
--loan records.  (2 Marks)

SELECT BE.banker_id,BE.first_name,BE.last_name,COUNT(LOAN_ID) AS COUNTS FROM Banker_Data AS BE
INNER JOIN Loan_Records_Data AS LR
ON BE.banker_id = LR.banker_id
GROUP BY BE.banker_id,BE.first_name,BE.last_name
ORDER BY COUNTS DESC 
OFFSET 0 ROW FETCH NEXT 2 ROWS ONLY 


--Q. Find the average age of male bankers (years, rounded to 1 decimal place) based on the date they joined WBG .

SELECT format(round(AVG(AGE),1),'0.0') AS AVERAGE_AGE FROM (
SELECT DATEDIFF(MONTH,dob,date_joined)*0.08333 AS AGE FROM bank_employees
WHERE gender = 'male' ) AS X 

--Q. Find the total number of different cities for which home loans have been issued.

SELECT COUNT(DISTINCT CITY) AS NUMBER_OF_CITIES FROM Home_Loan_Data

--Q. Find the customer ID, first name, last name, and email of customers whose email address contains the term 'amazon'.--

SELECT customer_id, first_name, last_name, email
FROM customers_details
WHERE email like '%amazon%'


--Q. Find the maximum property value (using appropriate alias) of each property type, ordered by the maximum property value in descending order.

SELECT property_type,MAX(property_value) AS MAX_VALUE  FROM Home_Loan_Data
GROUP BY property_type
ORDER BY MAX_VALUE DESC

--Q. Find the average age (at the point of loan transaction, in years and nearest integer) of female customers who took a non-joint loan for townhomes.


select avg(age) as averag_age from ( 
SELECT datediff(YEAR,dob,max(transaction_date)) as age FROM Home_Loan_Data AS HLD
INNER JOIN Loan_Records AS LR
ON HLD.loan_id = LR.loan_id
INNER JOIN customers_details AS C
ON LR.customer_id = C.customer_id
WHERE gender = 'female' AND joint_loan = 'No' AND property_type = 'Townhome'
group by dob
) as x


-- TASK 2 (END) --

--TASK 3 (BEGIN) --



--Q. Create a stored procedure called `recent_joiners` that returns the ID, concatenated full name, date of birth, and join date of bankers 
--who joined within the recent 2 years (as of 1 Sep 2022) 

CREATE PROCEDURE recent_joiners 
AS 
BEGIN  
      SELECT banker_id,concat(first_name,' ',last_name) as full_name,dob,date_joined FROM bank_employees 
	  where date_joined between dateadd(YEAR,-2,'2022-09-01') AND '2022-09-01'

END
 

 EXEC recent_joiners


--Q. Find the ID, first name and last name of customers with properties of value between $1.5 and $1.9 million, along 
--with a new column 'tenure' that categorizes how long the customer has been with WBG. 

--The 'tenure' column is based on the following logic:
--Long: Joined before 1 Jan 2015
--Mid: Joined on or after 1 Jan 2015, but before 1 Jan 2019
--Short: Joined on or after 1 Jan 2019


SELECT CD.customer_id,CD.first_name,CD.last_name,
CASE WHEN	CD.customer_since < '2015-01-01'
     THEN    'Long'
	 WHEN   CD.customer_since < '2019-01-01' AND  CD.customer_since > '2015-01-01'
	 THEN   'Mid'
	 ELSE    'Short'
	 END AS Tenure
FROM customers_details AS CD
INNER JOIN Loan_Records AS LR
ON CD.customer_id = LR.customer_id 
INNER JOIN Home_Loan_Data AS HLD
ON HLD.loan_id = LR.loan_id
WHERE property_value BETWEEN 1500000 AND 1900000 


--Create a stored procedure called `city_and_above_loan_amt` that takes in two parameters (city_name, loan_amt_cutoff) 
--that returns the full details of customers with loans for properties in the input city and with loan amount greater 
--than or equal to the input loan amount cutoff.  
--Call the stored procedure `city_and_above_loan_amt` you created above, based on the city San Francisco and loan amount cutoff of $1.5 million

create Procedure city_and_above_loan_amt
@city_name varchar(20),@loan_amt_cutoff money
AS

select c.* from 
			(Select *, (property_value*loan_percent)/100 as loan_amt 
				from Home_Loan_Data	) as t 
				join Loan_Records lr on lr.loan_id=t.loan_id
				join customers_details c on c.customer_id=lr.customer_id
where city=@city_name and loan_amt>= @loan_amt_cutoff

exec city_and_above_loan_amt @city_name='san francisco',@loan_amt_cutoff=1500000


--Q. Find the top 3 transaction dates (and corresponding loan amount sum) for which the sum of loan amount issued on that date is the highest.

SELECT transaction_date,sum(loan_amt) as sum_loan_amt FROM (
SELECT transaction_date,(property_value*loan_percent)/100 as loan_amt 
				 FROM Home_Loan_Data AS HLD
INNER JOIN Loan_Records_Data AS LR
ON HLD.loan_id = LR.loan_id) AS F
GROUP BY transaction_date
ORDER BY sum_loan_amt DESC
OFFSET 0 ROWS FETCH NEXT 3 ROWS ONLY


--Q. Find the number of Chinese customers with joint loans with property values less than $2.1 million, and served by female bankers.


SELECT COUNT(*)AS COUNT_OF_CHINESE_CUSTOMER FROM customers_details AS CD
INNER JOIN Loan_Records AS LD
ON CD.customer_id = LD.customer_id
INNER JOIN Home_Loan_Data AS HLD 
ON HLD.loan_id = LD.loan_id 
INNER JOIN bank_employees AS BE
ON BE.banker_id = LD.banker_id
WHERE nationality = 'China' AND property_value < 2100000 AND be.gender = 'Female' AND joint_loan = 'Yes'
 

--Q. Find the number of bankers involved in loans where the loan amount is greater than the average loan amount.  

SELECT COUNT(DISTINCT banker_id)AS COUNT_OF_BANKERS FROM ( 
SELECT BE.banker_id,(property_value*loan_percent)/100 as loan_amt  FROM bank_employees AS BE
INNER JOIN Loan_Records AS LR 
ON BE.banker_id = LR.banker_id
INNER JOIN Home_Loan_Data AS HLD 
ON HLD.loan_id = LR.loan_id
) AS H
WHERE loan_amt > (SELECT AVG((property_value*loan_percent)/100) FROM Home_Loan_Data) 

--Q. Create a view called `dallas_townhomes_gte_1m` which returns all the details of loans involving properties of townhome type, 
--located in Dallas, and have loan amount of >$1 million.

CREATE VIEW [dallas_townhomes_gte_1m] AS

SELECT * FROM ( 
SELECT *,(property_value*loan_percent)/100 as loan_amt FROM Home_Loan_Data
WHERE property_type = 'Townhome' AND city = 'Dallas' 
) AS S
WHERE loan_amt > 1000000


--EXECUTE
SELECT * FROM [dallas_townhomes_gte_1m]

--Q. Find the ID and full name (first name concatenated with last name) of customers who were served by bankers aged below 30 (as of 1 Aug 2022).

SELECT customer_id,full_name FROM (
SELECT CD.customer_id,CONCAT(CD.first_name,' ',CD.last_name) AS full_name,
DATEDIFF(YEAR,BE.dob,'2022-08-01') AS BANKERS_AGE FROM Customer_Data AS CD
INNER JOIN Loan_Records_Data AS LR 
ON CD.customer_id = LR.customer_id
INNER JOIN Banker_Data AS BE
ON BE.banker_id =LR.banker_id
)AS G
WHERE BANKERS_AGE < 30


--Q. Find the sum of the loan amounts ((i.e., property value x loan percent / 100) for each banker ID, excluding properties based in the 
--cities of Dallas and Waco. The sum values should be rounded to nearest integer.

SELECT banker_id,SUM(loan_amt) AS TOTAL_AMOUNTS  FROM (
SELECT BE.banker_id,(property_value*loan_percent)/100 as loan_amt FROM Home_Loan_Data AS HLD
INNER JOIN Loan_Records AS  LR 
ON HLD.loan_id = LR.loan_id
INNER JOIN bank_employees AS BE
ON BE.banker_id = LR.banker_id
WHERE city NOT IN ('Dallas','Waco')
) AS H
GROUP BY banker_id

--TASK 3 (END) --









