/*
SELECT * FROM CBSA LIMIT 10;
SELECT * FROM DRUG LIMIT 10;
SELECT * FROM FIPS_COUNTY LIMIT 10;
SELECT * FROM OVERDOSE_DEATHS LIMIT 10;
SELECT * FROM POPULATION LIMIT 10;
SELECT * FROM PRESCRIBER LIMIT 10;
SELECT * FROM PRESCRIPTION LIMIT 10;
SELECT * FROM ZIP_FIPS LIMIT 10;
*/

-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
WITH X AS (
SELECT
	NPI,
	PRESCRIBER_NAME,
	TOTAL_CLAIMS,
	RANK () OVER (ORDER BY TOTAL_CLAIMS DESC) RANKING
FROM(SELECT
	NPPES_PROVIDER_LAST_ORG_NAME||', '||NPPES_PROVIDER_FIRST_NAME PRESCRIBER_NAME,
	P.NPI,
	SUM(COALESCE(PR.TOTAL_CLAIM_COUNT,0)) TOTAL_CLAIMS
FROM
	PRESCRIBER P 
	INNER JOIN PRESCRIPTION PR ON P.NPI = PR.NPI
GROUP BY 
	P.NPI,
	PRESCRIBER_NAME)
) SELECT 
	NPI,
	PRESCRIBER_NAME,
	TOTAL_CLAIMS
FROM 
	X 
WHERE 
	RANKING = 1

--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

WITH X AS (
SELECT
	PRESCRIBER_NAME,
	SPECIALTY_DESCRIPTION,
	TOTAL_CLAIMS,
	RANK () OVER (ORDER BY TOTAL_CLAIMS DESC) RANKING
FROM(SELECT
	NPPES_PROVIDER_LAST_ORG_NAME||', '||NPPES_PROVIDER_FIRST_NAME PRESCRIBER_NAME,
	UPPER(P.SPECIALTY_DESCRIPTION) SPECIALTY_DESCRIPTION,
	P.NPI,
	SUM(COALESCE(PR.TOTAL_CLAIM_COUNT,0)) TOTAL_CLAIMS
FROM
	PRESCRIBER P 
	INNER JOIN PRESCRIPTION PR ON P.NPI = PR.NPI
GROUP BY 
	P.NPI,
	UPPER(P.SPECIALTY_DESCRIPTION),
	PRESCRIBER_NAME)
) SELECT
	PRESCRIBER_NAME,
	SPECIALTY_DESCRIPTION,
	TOTAL_CLAIMS
 FROM X WHERE RANKING = 1

-- PENDLEY, BRUCE, FAMILY PRACTICE, 990707
-- 2. 
--     a. Which specialty had the most total number of claims (totaled over all drugs)?
/*
SELECT * FROM CBSA LIMIT 10;
SELECT * FROM FIPS_COUNTY LIMIT 10;
SELECT * FROM OVERDOSE_DEATHS LIMIT 10;
SELECT * FROM POPULATION LIMIT 10;
SELECT * FROM PRESCRIBER LIMIT 10;
SELECT * FROM PRESCRIPTION LIMIT 10;
SELECT * FROM DRUG LIMIT 10;
SELECT * FROM ZIP_FIPS LIMIT 10;
*/

WITH X AS (
SELECT
	SPECIALTY_DESCRIPTION,
	TOTAL_CLAIMS,
	RANK () OVER (ORDER BY TOTAL_CLAIMS DESC) RANKING
FROM(SELECT
	UPPER(P.SPECIALTY_DESCRIPTION) SPECIALTY_DESCRIPTION,
	SUM(COALESCE(PR.TOTAL_CLAIM_COUNT,0)) TOTAL_CLAIMS
FROM
	PRESCRIBER P 
	INNER JOIN PRESCRIPTION PR ON P.NPI = PR.NPI
	UPPER(P.SPECIALTY_DESCRIPTION)
	)
) SELECT
	SPECIALTY_DESCRIPTION,
	TOTAL_CLAIMS
 FROM X WHERE RANKING = 1

--     b. Which specialty had the most total number of claims for opioids?

WITH X AS (
SELECT
	SPECIALTY_DESCRIPTION,
	TOTAL_CLAIMS ,
	RANK () OVER (ORDER BY TOTAL_CLAIMS DESC) RANKING
FROM(SELECT
	UPPER(P.SPECIALTY_DESCRIPTION) SPECIALTY_DESCRIPTION,
	SUM(COALESCE(PR.TOTAL_CLAIM_COUNT,0)) TOTAL_CLAIMS
FROM
	PRESCRIBER P 
	INNER JOIN PRESCRIPTION PR ON P.NPI = PR.NPI
	INNER JOIN DRUG D ON UPPER(TRIM(PR.DRUG_NAME)) = UPPER(TRIM(D.DRUG_NAME))
WHERE
	D.OPIOID_DRUG_FLAG ='Y'
GROUP BY 
	UPPER(P.SPECIALTY_DESCRIPTION))
) SELECT
	SPECIALTY_DESCRIPTION,
	TOTAL_CLAIMS
FROM X WHERE RANKING = 1
-- NURSE PRACTITIONER, 900845


--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

WITH X AS (
SELECT
	SPECIALTY_DESCRIPTION,
	TOTAL_CLAIMS 
FROM(SELECT
	UPPER(P.SPECIALTY_DESCRIPTION) SPECIALTY_DESCRIPTION,
	SUM(COALESCE(PR.TOTAL_CLAIM_COUNT,0)) TOTAL_CLAIMS
FROM
	PRESCRIBER P 
	LEFT OUTER JOIN PRESCRIPTION PR ON P.NPI = PR.NPI	 
GROUP BY 
  UPPER(P.SPECIALTY_DESCRIPTION))
) 
SELECT
	SPECIALTY_DESCRIPTION,
	TOTAL_CLAIMS
FROM X WHERE TOTAL_CLAIMS = 0
ORDER BY 1

--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
WITH X AS (
SELECT
	SPECIALTY_DESCRIPTION,
	TOTAL_OPIOIOD_CLAIMS,
	TOTAL_CLAIMS,
	PERCENTAGE_OPIOID_CLAIMS
	---RANK () OVER (ORDER BY TOTAL_CLAIMS DESC) RANKING
FROM(SELECT
	UPPER(P.SPECIALTY_DESCRIPTION) SPECIALTY_DESCRIPTION,
	SUM(CASE WHEN D.OPIOID_DRUG_FLAG ='Y' THEN COALESCE(PR.TOTAL_CLAIM_COUNT,0)
	ELSE 0 END) TOTAL_OPIOIOD_CLAIMS,
	SUM(COALESCE(PR.TOTAL_CLAIM_COUNT,0)) TOTAL_CLAIMS,
	ROUND(CASE WHEN 
	SUM(CASE WHEN D.OPIOID_DRUG_FLAG ='Y' THEN COALESCE(PR.TOTAL_CLAIM_COUNT,0)
	ELSE 0 END) = 0 THEN 0
	ELSE SUM(CASE WHEN D.OPIOID_DRUG_FLAG ='Y' THEN COALESCE(PR.TOTAL_CLAIM_COUNT,0)
	ELSE 0 END)/SUM(COALESCE(PR.TOTAL_CLAIM_COUNT,0)) END *100,2) PERCENTAGE_OPIOID_CLAIMS
FROM
	PRESCRIBER P 
	INNER JOIN PRESCRIPTION PR ON P.NPI = PR.NPI
	INNER JOIN DRUG D ON UPPER(TRIM(PR.DRUG_NAME)) = UPPER(TRIM(D.DRUG_NAME))
GROUP BY 
	UPPER(P.SPECIALTY_DESCRIPTION))
) SELECT
	SPECIALTY_DESCRIPTION,
	TOTAL_OPIOIOD_CLAIMS,
	TOTAL_CLAIMS,
	PERCENTAGE_OPIOID_CLAIMS
FROM X WHERE TOTAL_OPIOIOD_CLAIMS > 0
ORDER BY 4 DESC,1

-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?

--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

-- 4. 
--     a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
    
--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.