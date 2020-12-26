-- 1. Identify patients who were diagnosed with RRD (Rhegmatogenous retinal detachment) between Jan 1, 2013 and Dec 31, 2018.
-- RRD diagnoses can be identified by these ICD DX codes:
-- ICD-9 = 361.00, 361.01, 361.02, 361.03, 361.04, 361.05, 361.06, 361.07
-- ICD-10 = H33.001, H33.002, H33.003, H33.009, H33.011, H33.012, H33.013, H33.019, H33.021, H33.022, H33.023, H33.029, H33.031, H33.032, H33.033, H33.039, H33.041, H33.042, H33.043, H33.049, H33.051, H33.052, H33.053, H33.059, H33.8.
-- Use regular expressions or 'ilike' and respective syntax coding in the where clause when querying for the ICD DX codes and use dx date for the date restriction.

drop table if exists q1;

create temporary table q1 as

select distinct (a.patient_guid), 
(a.problem_onset_date),
(a.documentation_date)

from madrid2.patient_problem as a 

where (a.problem_code ilike '361.00%' 
or a.problem_code ilike '361.01%' 
or a.problem_code ilike '361.02%' 
or a.problem_code ilike '361.03%'
or a.problem_code ilike '361.04%' 
or a.problem_code ilike '361.05%' 
or a.problem_code ilike '361.06%'
or a.problem_code ilike '361.07%'
or a.problem_code ilike 'H33.001%'
or a.problem_code ilike 'H33.002%'
or a.problem_code ilike 'H33.003%'
or a.problem_code ilike 'H33.009%'
or a.problem_code ilike 'H33.011%'
or a.problem_code ilike 'H33.012%'
or a.problem_code ilike 'H33.013%'
or a.problem_code ilike 'H33.019%'
or a.problem_code ilike 'H33.021%'
or a.problem_code ilike 'H33.022%'
or a.problem_code ilike 'H33.023%' 
or a.problem_code ilike 'H33.029%'
or a.problem_code ilike 'H33.031%'
or a.problem_code ilike 'H33.032%'
or a.problem_code ilike 'H33.033%'
or a.problem_code ilike 'H33.039%'
or a.problem_code ilike 'H33.041%'
or a.problem_code ilike 'H33.042%'
or a.problem_code ilike 'H33.043%'
or a.problem_code ilike 'H33.049%' 
or a.problem_code ilike 'H33.051%' 
or a.problem_code ilike 'H33.052%'
or a.problem_code ilike 'H33.053%'
or a.problem_code ilike 'H33.059%'
or a.problem_code ilike 'H33.8%')
and (
    SELECT min(extract(year from a.problem_onset_date)),
     min(extract(year from a.documentation_date))
     from madrid2.patient_problem
     where a.problem_onset_date between '2013' and '2018'
     and a.documentation_date between '2013' and '2018'
);
/*use documentation_date for date restriction */

select * from q1 limit 10; /*checks q1 created properly*/

select count distinct (patient_guid) from q1; /* 285922 patients diagnosed with RRD  */


--Q2  Determine the number of patients from #1. above who had an RRD surgical procedure between Jan 1, 2013  and December 31, 2018. RRD surgical procedures can be identified by CPT proc codes 67101, 67105, 67107, 67108, 67112, 67113, 67145, 67141.
-- Use 'ilike' where clause when querying for the CPT codes.

DROP TABLE IF EXISTS q2;

CREATE TEMPORARY TABLE q2 AS
SELECT
                (distinct b.patient_guid),
                (distinct b.procedure_date)
FROM
                madrid2.patient_procedure AS b
                INNER JOIN q1 ON q1.patient_guid = b.patient_guid
WHERE (
                b.procedure_code ILIKE '67101%'
                OR b.procedure_code ILIKE '67105%'
                OR b.procedure_code ILIKE '67107%'
                OR b.procedure_code ILIKE '67108%'
                OR b.procedure_code ILIKE '67112%'
                OR b.procedure_code ILIKE '67113%'
                OR b.procedure_code ILIKE '67145%'
                OR b.procedure_code ILIKE '67141%')
AND b.procedure_date BETWEEN '2013-01-01'
AND '2018-12-31';            /*use effective_date for date restriction */

select count(DISTINCT patient_guid) from q2; /* 88639 patients undergone RRD surgical procedure between 2013-1-1 and 2018-12-31 */

                
--Q3. Obtain the counts by age, gender, and race, and insurance (take the mode as patients have multiple) of the individuals identified above (from #2).
-- Report age from the first date of procedure (proc_date) per patient.  Then, stratify the
-- counts by year of procedure.


drop table if exists q3;

CREATE TEMPORARY TABLE q3 AS
SELECT
                q2.patient_guid,
                min(
                                EXTRACT(year FROM q2.procedure_date)) AS minprocyear,
                a.race,
                a.ethnicity,
                a.gender,
                a.year_of_birth,
                min(
                                EXTRACT(year FROM q2.procedure_date)) - a.year_of_birth AS age2,
                b.insurance_plan
FROM
                q2
                LEFT JOIN madrid2.patient_demographic AS a ON q2.patient_guid = a.patient_guid
                LEFT JOIN madrid2.patient_insurance AS b ON a.patient_guid = b.patient_guid
GROUP BY
                q2.patient_guid,
                a.race,
                a.ethnicity,
                a.gender,
                a.year_of_birth,
                b.insurance_plan; /*age2 is patients age at date of procedure*/
                
                
SELECT
                *
FROM
                q3
ORDER BY
                patient_guid
LIMIT 50; /* checking that q3 temp table was created properly*/



drop table if exists q3_step2;

create TEMPORARY table q3_step2 as
select a.*,
               case when age2 >=0 and age2 < 18 then 'under 18'
                                when age2 >=18 and age2 < 25 then 'between 18 and 25'
                                when age2 >=25 and age2 < 34 then 'between 25 and 34'
                                when age2 >=34 and age2 < 44 then 'between 34 and 44'
                                when age2 >=44 and age2 < 54 then 'between 44 and 54'
                                when age2 >=54 and age2 < 65 then 'between 54 and 65'
                                when age2 >=65 and age2 < 115  then '65 and above'
                                else 'unknown' end as agecat
                                from q3 a;
                                
SELECT
                *
FROM
                q3_step2
LIMIT 100; 
/* checking that q3_step2 temp table was created properly */


/* count by race */
SELECT case when ethnicity = 'Hispanic or Latino' then 'Hispanic'
when ethnicity = 'Hispanic or Latino' and race = 'Unknown' then 'Hispanic' 
end as race
from (select patient_guid,
case when race = 'Declined to answer' then 'Unknown'
when race = 'Caucasian' then 'White'
when race = '2 or more races' then 'Multi'
else race end as race)
GROUP BY
                race;

/* count by gender */
SELECT
                gender,
                count(DISTINCT patient_guid)
FROM
                q3_step2
GROUP BY
                gender;

/* count by age */
/* table showing yob and procedure date*/
SELECT
                agecat,
                count(DISTINCT patient_guid)
FROM
                q3_step2
GROUP BY
                agecat
ORDER BY
                agecat;


-- 4. Create a sample of patients in a table from the patients from #1 above who ALSO had an RRD surgical procedure AFTER the date of their diagnosis of RRD.



drop table if exists q4;

create temporary table q4 as
select q1.patient_guid, min(q1.documentation_date) as diagnosis_date, max(q2.effective_date) as procedure_date from q1 
left join q2 
on q1.patient_guid = q2.patient_guid
group by q1.patient_guid;

SELECT * from q4 limit 10;

select count(DISTINCT patient_guid) from q4 where q4.procedure_date > q4.diagnosis_date;
