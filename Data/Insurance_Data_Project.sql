-- Importing data
\copy policy_master FROM 'C:/Users/danil/Insurance Dataset/Policy_Dataset_2020.csv' WITH CSV HEADER DELIMITER ',';
\copy claim_master FROM 'C:/Users/danil/Insurance Dataset/Claim_Dataset_2024.csv' WITH CSV HEADER DELIMITER ',';

-- Create policy unified table (including all years)
CREATE TABLE policy_master (
	Policy_ID INT PRIMARY KEY, 
	Issue_Date DATE, 
	Effective_Date DATE, 
	End_Effective_Date DATE,
	Reference_Date DATE, 
	Sales_Location VARCHAR(50),
	Line_Of_Business VARCHAR(50),
	Sales_Channel VARCHAR (20),
	Premium_Amount DECIMAL(15,2)
);

-- Create claims unified table
CREATE TABLE claim_master (
	Claim_ID VARCHAR(20) PRIMARY KEY,
	Policy_ID INT REFERENCES policy_master(Policy_ID),
	Occurrence_Date DATE, 
	Claim_Status VARCHAR(20),
	Claim_Amount DECIMAL(15, 2),
	Payment_Date DATE NULL,
	Expenses_Amount DECIMAL(15, 2)
		

-- Q1 -> Most issued policies across years by LoB (Line of Business) & Executive Summary Written Premium
SELECT
	EXTRACT(YEAR FROM issue_date) AS Policy_Year,
	Line_Of_Business,
	COUNT(*) AS Policy_Count
FROM policy_master
GROUP BY 1, 2
ORDER BY 1, 3 DESC;

WITH WrittenPremium AS (
	SELECT 
		EXTRACT(YEAR FROM issue_date) AS policy_year,
		line_of_business,
		sales_location,
		COUNT(*) AS policy_count,
		SUM(premium_amount) AS written_premium
	FROM policy_master
	WHERE issue_date BETWEEN '2020-01-01' AND '2024-12-31'
	GROUP BY 1, 2, 3
)
SELECT
	policy_year,
	line_of_business,
	sales_location,
	policy_count,
	written_premium,
	SUM(written_premium) OVER (
		PARTITION BY line_of_business, sales_location
		ORDER BY policy_year
		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
	) AS accumulated_written_premium
FROM WrittenPremium
ORDER BY 2, 3, 1;

-- Q2 -> Written premiums by Year, Region, Lob and Policies Count 
SELECT
	EXTRACT(YEAR FROM Reference_Date) AS Reference_Year,
	Line_of_Business,
	Sales_Location, 
	COUNT(*) AS Policy_Count,
	ROUND(SUM(Premium_Amount), 2) AS Net_Written_Premium
FROM policy_master
GROUP BY 1, 2, 3
ORDER BY 1, 4 DESC, 5 DESC;

-- Q3 -> Check for seasonality in issue policy volume by line_of_business
SELECT
	Line_Of_Business,
	TO_CHAR(Issue_Date, 'MM') AS Month_Number,
	TO_CHAR(Issue_Date, 'Month') AS Month_Name,
	COUNT(*) AS Policy_Count
FROM policy_master
GROUP BY 1, 2, 3
ORDER BY 1, 2;

-- Q4 -> Calculating Earned Premium across the months and years for each Policy
WITH policy_months AS (
	SELECT
		p.policy_id,
		p.premium_amount,
		p.effective_date,
		p.end_effective_date,
		p.line_of_business,
		p.sales_location,
		generate_series(
			date_trunc('month', effective_date),
			date_trunc('month', end_effective_date),
			interval '1 month'
		) AS month_start
	FROM policy_master p
),

earned_calc AS (
	SELECT
		policy_id,
		line_of_business,
		sales_location,
		month_start,
		effective_date,
		end_effective_date,

		-- Reference date
		(month_start + interval '1 month - 1 day')::DATE AS reference_date,

		-- Start and end of each month
		GREATEST(month_start, effective_date)::DATE AS active_start, 
		LEAST(month_start + interval '1 month - 1 day', end_effective_date)::date AS active_end,

		-- Total policy duration in days
		(end_effective_date - effective_date + 1)::FLOAT AS policy_duration_days,

		-- Active days in the given month
		((LEAST(month_start + interval '1 month - 1 day', end_effective_date)::DATE -
		 GREATEST(month_start, effective_date)::DATE) + 1)::FLOAT AS active_days_in_month,

		premium_amount
	FROM policy_months
),

earned_premium_monthly AS (
	SELECT
		policy_id,
		line_of_business,
		sales_location,
		reference_date,
		ROUND(((active_days_in_month / policy_duration_days) * premium_amount)::NUMERIC, 2) AS earned_premium
	FROM earned_calc
)

-- Final Earned Premium Output
SELECT * INTO earned_premium_output FROM earned_premium_monthly;

-- Q5 -> Executive Summary Earned Premium
WITH EarnedPremium AS (
	SELECT
		EXTRACT(YEAR FROM reference_date) AS reference_year,
		line_of_business,
		sales_location,
		SUM(earned_premium) AS total_earned_premium
	FROM 
		earned_premium_output
	GROUP BY 1, 2, 3
)
SELECT
	reference_year,
	line_of_business,
	sales_location,
	total_earned_premium,
	SUM(total_earned_premium) OVER (
		PARTITION BY line_of_business, sales_location
		ORDER BY reference_year
		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
	) AS accumulated_earned_premium
FROM 
	EarnedPremium
ORDER BY 2, 3, 1

-- Q6 -> Frequency and Severity distribution of claims across the years
SELECT
	TO_CHAR(occurrence_date, 'MM-YYYY') AS occurrence_month,
	p.line_of_business,
	p.sales_location,
	
	COUNT(*) AS claim_count, -- Claim frequency
	ROUND(AVG(c.claim_amount)::NUMERIC, 2) AS avg_claim_amount, -- Claim severity
	ROUND(SUM(c.claim_amount)::NUMERIC, 2) AS total_claim_amount,
	ROUND(MAX(c.claim_amount)::NUMERIC, 2) AS max_claim_amount

FROM claim_master c
INNER JOIN policy_master p ON c.policy_id = p.policy_id

GROUP BY occurrence_month, p.line_of_business, p.sales_location
ORDER BY occurrence_month, p.line_of_business, claim_count DESC;

-- Q7 -> Top 10 Largest Claims by Line of Business and Sales Location
WITH ranked_claims AS (
	SELECT
		c.claim_id,
		c.policy_id,
		p.line_of_business,
		p.sales_location,
		c.occurrence_date,
		c.claim_status,
		ROUND(c.claim_amount::NUMERIC, 2) AS claim_amount,
		ROW_NUMBER() OVER (PARTITION BY p.line_of_business ORDER BY c.claim_amount DESC) AS claim_rank
	FROM claim_master c
	INNER JOIN policy_master p ON c.policy_id = p.policy_id	
)

SELECT * FROM ranked_claims
WHERE claim_rank <= 10
ORDER BY line_of_business, claim_rank;

-- Q9 -> Claim Settlement Ratio by Year, Line of Business, and Location
WITH settlement_stats AS (
	SELECT
		TO_CHAR(c.occurrence_date, 'MM-YYYY') AS claim_month,
		p.line_of_business,
		p.sales_location,
		COUNT(*) AS total_claims,
		COUNT(*) FILTER (WHERE c.claim_status = 'Settled') AS settled_claims
	FROM claim_master c
	INNER JOIN policy_master p ON c.policy_id = p.policy_id
	GROUP BY claim_month, p.line_of_business, p.sales_location
)

SELECT 
	claim_month, 
	line_of_business,
	sales_location,
	total_claims,
	settled_claims,
	ROUND((settled_claims::NUMERIC / NULLIF(total_claims, 0)) * 100, 2) AS settlement_ratio_pct
FROM settlement_stats
ORDER BY claim_month, line_of_business, sales_location;

-- Q10 -> Executive Summary Claims & Average claim processing time (Settled Claims only)
WITH ClaimsSummary AS (
	SELECT
		EXTRACT(YEAR FROM c.occurrence_date) AS claim_year,
		p.line_of_business,
		p.sales_location,
		c.claim_status,
		SUM(c.claim_amount) AS total_claims,
		SUM(c.expenses_amount) AS total_expenses,
		CASE
			WHEN c.claim_status = 'Settled' THEN SUM(c.claim_amount)
			ELSE 0
		END AS claim_amount_paid,
		CASE
			WHEN c.claim_status = 'Pending' THEN SUM(c.claim_amount)
			ELSE 0
		END AS claim_amount_pending
	FROM claim_master c
		INNER JOIN policy_master p ON c.policy_id = p.policy_id
	WHERE c.occurrence_date BETWEEN '2020-01-01' AND '2025-12-31'
	GROUP BY 1, 2, 3, 4
)
SELECT
	claim_year,
	line_of_business,
	sales_location,
	claim_amount_paid,
	claim_amount_pending,
	total_claims,
	total_expenses,
	SUM(total_claims) OVER (
		PARTITION BY line_of_business, sales_location
		ORDER BY claim_year
		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
	) AS accumulated_claims
FROM
	ClaimsSummary
ORDER BY 
	2, 3, 1;


SELECT
	TO_CHAR(c.occurrence_date, 'MM-YYYY') AS claim_month,
	p.line_of_business,
	p.sales_location,
	COUNT(*) AS settled_claims,
	ROUND(AVG((c.payment_date - c.occurRence_date))::NUMERIC, 1) AS avg_processing_days
FROM claim_master c
INNER JOIN policy_master p ON c.policy_id = p.policy_id
WHERE c.claim_status = 'Settled' AND c.payment_date IS NOT NULL
GROUP BY claim_month, p.line_of_business, p.sales_location
ORDER BY claim_month, p.line_of_business, p.sales_location, avg_processing_days DESC;

-- Q11 -> Executive Summary Net Operating Income 
WITH EarnedPremium AS (
	SELECT
		EXTRACT(YEAR FROM reference_date) AS reference_year,
		line_of_business,
		sales_location,
		SUM(earned_premium) AS total_earned_premium
	FROM 
		earned_premium_output
	GROUP BY 1, 2, 3
),
ClaimsSummary AS (
	SELECT
		EXTRACT(YEAR FROM c.occurrence_date) AS reference_year,
		p.line_of_business,
		p.sales_location,
		SUM(c.claim_amount) AS total_claims,
		SUM(c.expenses_amount) AS total_expenses
	FROM claim_master c
	INNER JOIN policy_master p ON c.policy_id = p.policy_id
	GROUP BY 1, 2, 3
)
SELECT
	ep.reference_year,
	ep.line_of_business,
	ep.sales_location,
	ep.total_earned_premium,
	COALESCE(cs.total_claims, 0) AS total_claims,
	COALESCE(cs.total_expenses, 0) AS total_expenses,
	(ep.total_earned_premium - COALESCE(cs.total_claims, 0) - COALESCE(cs.total_expenses, 0)) AS net_operating_income
FROM
	EarnedPremium ep
	LEFT JOIN ClaimsSummary cs
		ON ep.reference_year = cs.reference_year
		AND ep.line_of_business = cs.line_of_business
		AND ep.sales_location = cs.sales_location
ORDER BY
	ep.line_of_business, ep.sales_location, ep.reference_year;


-- Q12 -> Digital Adoption Rate by Year, Line of Business, and Location
SELECT
	EXTRACT(YEAR FROM issue_date) AS policy_year,
	line_of_business,
	sales_location,
	COUNT(*) AS total_policies,
	COUNT(*) FILTER (WHERE sales_channel = 'Digital') AS digital_policies,
	ROUND((COUNT(*) FILTER (WHERE sales_channel = 'Digital')::NUMERIC / NULLIF(COUNT(*), 0)) * 100, 2) AS digital_adoption_pct
FROM policy_master
GROUP BY policy_year, line_of_business, sales_location
ORDER BY 2, 3, 1;

CREATE TABLE claim_master (
	Claim_ID VARCHAR(20) PRIMARY KEY,
	Policy_ID INT REFERENCES policy_master(Policy_ID),
	Occurrence_Date DATE, 
	Claim_Status VARCHAR(20),
	Claim_Amount DECIMAL(15, 2),
	Payment_Date DATE NULL,
	Expenses_Amount DECIMAL(15, 2)

-- Q13 -> Claims processing time analysis
WITH PaidClaims AS (
	SELECT
		c.claim_id,
		c.occurrence_date,
		EXTRACT(YEAR FROM c.occurrence_date) as claim_year,
		p.line_of_business,
		p.sales_location,
		c.claim_status,
		c.payment_date,
		CASE
			WHEN c.claim_status = 'Settled'
			THEN (c.payment_date - c.occurrence_date)
			ELSE 0
		END AS processing_time
	FROM claim_master c
	LEFT JOIN policy_master p
	ON c.policy_id = p.policy_id
	ORDER BY 1, 2
)
SELECT
	claim_year,
	line_of_business,
	sales_location,
	AVG(processing_time) AS avg_processing_time
FROM PaidClaims
GROUP BY 1, 2, 3
ORDER BY 2, 3, 1;

------------------------------------------------''--------------------------------------''--------------------------------------------------------

-- Creating Tables to work with Star Schema framework in Power BI

CREATE TABLE fact_profitability (
	policy_id INT, 
	reference_date DATE, 
	reference_year INT,
	reference_month INT,
	reference_quarter TEXT,
	written_premium NUMERIC(12, 2),
	earned_premium NUMERIC(12, 2),
	claim_amount NUMERIC(12, 2),
	expense_amount NUMERIC(12, 2)
);

CREATE TABLE dim_policy (
	policy_ID INT PRIMARY KEY,
	issue_date DATE,
	effective_date DATE, 
	end_effective_date DATE,
	line_of_business TEXT, 
	sales_location TEXT,
	sales_channel TEXT
);

CREATE TABLE dim_claim (
	claim_id TEXT PRIMARY KEY,
	policy_id INT,
	occurrence_date DATE,
	claim_status TEXT,
	claim_amount NUMERIC(12, 2),
	payment_date DATE,
	processing_time INT
);

CREATE TABLE monthly_claims_expenses AS 
SELECT
	policy_id,
	DATE_TRUNC('month', occurrence_date)::DATE AS reference_date,
	SUM(claim_amount) AS claim_amount,
	SUM(expenses_amount) AS expense_amount
FROM claim_master
GROUP BY policy_id, DATE_TRUNC('month', occurrence_date);

-- Populating fact_profitability table

INSERT INTO fact_profitability (
	policy_id,
	reference_date,
	reference_year,
	reference_month,
	reference_quarter,
	written_premium,
	earned_premium,
	claim_amount,
	expense_amount
)
SELECT
	ep.policy_id,
	ep.reference_date,
	EXTRACT(YEAR FROM ep.reference_date)::INT as reference_year,
	EXTRACT(MONTH FROM ep.reference_date)::INT as reference_month,
	'Q' || EXTRACT(QUARTER FROM ep.reference_date)::TEXT as reference_quarter,
	pm.premium_amount AS written_premium,
	ep.earned_premium, 
	COALESCE(mce.claim_amount, 0) AS claim_amount,
	COALESCE(mce.expense_amount, 0) As expense_amount	
FROM earned_premium_output ep
INNER JOIN policy_master pm ON ep.policy_id = pm.policy_id
LEFT JOIN monthly_claims_expenses mce
		ON ep.policy_id = mce.policy_id AND DATE_TRUNC('month', ep.reference_date) = mce.reference_date;

-- Populate dim_policy table 
INSERT INTO dim_policy (
	policy_id,
	issue_date,
	effective_date,
	end_effective_date,
	line_of_business,
	sales_location,
	sales_channel
)
SELECT DISTINCT
	policy_id,
	issue_date,
	effective_date,
	end_effective_date,
	line_of_business,
	sales_location,
	sales_channel
FROM policy_master;

-- Populate dim_claim 
INSERT INTO dim_claim (
	claim_id,
	policy_id,
	occurrence_date,
	claim_status,
	claim_amount,
	payment_date,
	processing_time
)
SELECT
	claim_id,
	policy_id,
	occurrence_date,
	claim_status,
	claim_amount,
	payment_date,
	CASE
		WHEN claim_status = 'Settled' AND payment_date IS NOT NULL
		THEN (payment_date - occurrence_date)
		ELSE NULL
	END AS processing_time
FROM claim_master;

