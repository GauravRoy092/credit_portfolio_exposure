/* ============================================================================
   PROJECT: Lending Club Risk Analysis & Portfolio Optimization
   AUTHOR: Gaurav Roy
   TOOL: PostgreSQL / SQLite (via DBeaver)
   DATASET: 2.26 Million Loan Records (2007-2018)
   
   DESCRIPTION: 
   This script analyzes historical peer-to-peer lending data to uncover 
   key drivers of credit risk, evaluate underwriting accuracy, and identify 
   opportunities for risk-based pricing optimization. 
   ============================================================================ */


/* ----------------------------------------------------------------------------
   1. LOAN DEFAULT & CREDIT RISK MODELING
   
   Business Problem: Does the internal credit grading system accurately predict 
                     the probability of loan charge-offs?
   Strategic Value:  Validates underwriting models. Highlights whether high-risk 
                     (Grade G) loans are failing at expected rates compared to 
                     low-risk (Grade A) loans.
   Technical Approach: Aggregates total volume and calculates the exact default 
                       percentage per grade using binary flag summation.
   ---------------------------------------------------------------------------- */
SELECT 
    grade,
    COUNT(id) AS total_loans,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) AS defaulted_loans,
    ROUND((SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0) / COUNT(id), 2) AS default_rate_percentage
FROM 
    sampley
GROUP BY 
    grade
ORDER BY 
    grade ASC;


/* ----------------------------------------------------------------------------
   2. INCOME ELASTICITY VS. LOAN PRINCIPAL
   
   Business Problem: What is the correlation between a borrower's verified 
                     annual income and their requested loan principal?
   Strategic Value:  Identifies portfolio concentration. If lower-income brackets 
                     are requesting disproportionately large loans, it signals 
                     a risk of over-leveraging.
   Technical Approach: Segments continuous income data into 5 distinct analytical 
                       tiers using CASE logic, then averages requested principal.
   ---------------------------------------------------------------------------- */
SELECT 
    CASE 
        WHEN annual_inc < 50000 THEN '1. Under 50k'
        WHEN annual_inc BETWEEN 50000 AND 99999 THEN '2. 50k - 100k'
        WHEN annual_inc BETWEEN 100000 AND 149999 THEN '3. 100k - 150k'
        WHEN annual_inc BETWEEN 150000 AND 199999 THEN '4. 150k - 200k'
        ELSE '5. 200k+' 
    END AS income_bracket,
    COUNT(id) AS total_borrowers,
    ROUND(AVG(loan_amnt), 0) AS average_loan_requested
FROM 
    sampley
WHERE 
    annual_inc IS NOT NULL
GROUP BY 
    1
ORDER BY 
    1 ASC;


/* ----------------------------------------------------------------------------
   3. HOUSING STATUS RISK PROFILE
   
   Business Problem: How does a borrower's homeownership status alter their 
                     credit risk profile and overall default probability?
   Strategic Value:  Allows the risk team to adjust borrower interest rates 
                     based on asset stability (e.g., penalizing renters if they 
                     show higher transient default rates).
   Technical Approach: Calculates default penetration grouped by housing status, 
                       ordered dynamically to push the riskiest demographic to the top.
   ---------------------------------------------------------------------------- */
SELECT 
    home_ownership,
    COUNT(id) AS total_borrowers,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) AS defaulted_loans,
    ROUND((SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0) / COUNT(id), 2) AS default_rate_percentage
FROM 
    sampley
WHERE 
    home_ownership IS NOT NULL
GROUP BY 
    1
ORDER BY 
    default_rate_percentage DESC;


/* ----------------------------------------------------------------------------
   4. HISTORICAL INTEREST RATE TRENDS
   
   Business Problem: What is the historical trend of weighted average interest 
                     rates across annual origination vintages?
   Strategic Value:  Demonstrates macro-level pricing strategy. Tracks if the 
                     company is taking on riskier borrowers over time (which 
                     necessitates charging higher average rates).
   Technical Approach: Extracts the 4-digit origination year using substring 
                       manipulation on raw text dates, aggregating average yield.
   ---------------------------------------------------------------------------- */
SELECT 
    SUBSTR(issue_d, -4) AS loan_year,
    COUNT(id) AS total_loans,
    ROUND(AVG(int_rate), 2) AS average_interest_rate
FROM 
    sampley
WHERE 
    issue_d IS NOT NULL
GROUP BY 
    1
ORDER BY 
    1 ASC;


/* ----------------------------------------------------------------------------
   5. RISK-ADJUSTED YIELD BY LOAN PURPOSE
   
   Business Problem: Which loan purpose categories exhibit the highest risk-adjusted 
                     yield and the lowest charge-off velocity?
   Strategic Value:  Informs marketing and capital allocation. If debt consolidation 
                     yields 15% interest with a 4% default rate, marketing spend 
                     should be diverted away from riskier categories (like small business).
   Technical Approach: Multi-variable aggregation comparing gross interest rate 
                       earned versus actual principal loss frequency.
   ---------------------------------------------------------------------------- */
SELECT 
    purpose,
    COUNT(id) AS total_loans,
    ROUND(AVG(int_rate), 2) AS average_interest_rate,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) AS defaulted_loans,
    ROUND((SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0) / COUNT(id), 2) AS default_rate_percentage
FROM 
    sampley
WHERE 
    purpose IS NOT NULL
GROUP BY 
    1
ORDER BY 
    default_rate_percentage ASC;