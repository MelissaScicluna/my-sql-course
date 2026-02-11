/*
* SQL Course - CASE Exercise - Start
*/

/* 
 * Create a new column HospitalLocation
 * Kings College is Urban,other hospitals are Rural 
 * Use the simple CASE form
*/

SELECT
ps.PatientId
,ps.Hospital
--,'???' AS HospitalLocation
case when ps.Hospital = 'Kings College' then 'Urban' else 'Rural' end as HospitalLocation -- searched case form
case ps."Hospital" when 'Kings College' then 'Urban' else 'Rural' end as HospitalLocation -- simple case form
FROM
dbo.PatientStay ps
ORDER BY
HospitalLocation;

/* 
 * Create a new column WardType
 * Any ward that contains 'Surgery' is 'Surgical',otherwise 'Non Surgical'
 * Use the searched CASE form
*/

SELECT
ps.PatientId
,ps.Hospital
,case when ps.ward like '%Surgery%' then 'Surgical' else 'Non Surgical' END AS WardType
FROM
dbo.PatientStay ps
ORDER BY
WardType;

/*
 * Create a new column PatientTariffGroup
 * A patient with a Tariff of 7 or more is in the 'High Tariff' group
 * A patient with a Tariff of 4 or more but below 7 is in the 'Medium Tariff' group
 * A patient with a Tariff below 4 is is in the 'Low Tariff' group
 * 
 * Optional advanced question: how many patients are in each PatientTariffGroup?
 */
        
SELECT
    ps.PatientId
    ,ps.AdmittedDate
    ,ps.Tariff
    ,CASE 
        WHEN ps.Tariff >=7 then 'High Tariff' 
        WHEN ps.Tariff >=4 then 'Medium Tariff'
        else 'Low Tariff'
        END AS PatientTariffGroup,
    COUNT(*) AS NumberOfPatients
FROM
    dbo.PatientStay ps
GROUP BY 
CASE 
    WHEN ps.Tariff >=7 then 'High Tariff' 
    WHEN ps.Tariff >=4 then 'Medium Tariff'
    else 'Low Tariff'
     end
    ,ps.PatientId
    ,ps.AdmittedDate
    ,ps.Tariff  
ORDER BY
NumberOfPatients DESC
,PatientTariffGroup
,ps.Tariff
,ps.PatientId;