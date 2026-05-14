INSERT INTO DimPatient (PatientID, Age, Gender, Country)
SELECT PatientID, Age, Gender, Country
FROM SOURCE_OralPatient.dbo.Patient;


INSERT INTO DimRiskFactors
(
    TobaccoUse,
    AlcoholConsumption,
    HPVInfection,
    BetelQuidUse
)
SELECT DISTINCT
    TobaccoUse,
    AlcoholConsumption,
    HPVInfection,
    BetelQuidUse
FROM SOURCE_OralPatient.dbo.RiskFactors;


INSERT INTO DimSymptoms
(
    OralLesions,
    UnexplainedBleeding,
    DifficultySwallowing,
    WhiteRedPatches
)
SELECT DISTINCT
    OralLesions,
    UnexplainedBleeding,
    DifficultySwallowing,
    WhiteRedPatches
FROM SOURCE_OralPatient.dbo.Symptoms;


INSERT INTO DimTreatment
(
    TreatmentType
)
SELECT DISTINCT
    TreatmentType
FROM SOURCE_OralPatient.dbo.Treatment;



INSERT INTO FactPatientHealth
(
    PatientKey,
    RiskKey,
    SymptomKey,
    TreatmentKey,
    TumorSize,
    CancerStage,
    SurvivalRate,
    EconomicBurden
)
SELECT 
    dp.PatientKey,
    dr.RiskKey,
    ds.SymptomKey,
    dt.TreatmentKey,
    t.TumorSize,
    t.CancerStage,
    o.SurvivalRate,
    o.EconomicBurden
FROM SOURCE_OralPatient.dbo.Patient p

-- Patient Dimension
JOIN DimPatient dp 
    ON p.PatientID = dp.PatientID

-- Risk
JOIN SOURCE_OralPatient.dbo.RiskFactors r 
    ON p.PatientID = r.PatientID
JOIN DimRiskFactors dr 
    ON r.TobaccoUse = dr.TobaccoUse
    AND r.AlcoholConsumption = dr.AlcoholConsumption
    AND r.HPVInfection = dr.HPVInfection
    AND r.BetelQuidUse = dr.BetelQuidUse

-- Symptoms
JOIN SOURCE_OralPatient.dbo.Symptoms s 
    ON p.PatientID = s.PatientID
JOIN DimSymptoms ds 
    ON s.OralLesions = ds.OralLesions
    AND s.UnexplainedBleeding = ds.UnexplainedBleeding
    AND s.DifficultySwallowing = ds.DifficultySwallowing
    AND s.WhiteRedPatches = ds.WhiteRedPatches

-- Tumor
JOIN SOURCE_OralPatient.dbo.Tumor t 
    ON p.PatientID = t.PatientID

-- Treatment
JOIN SOURCE_OralPatient.dbo.Treatment tr 
    ON p.PatientID = tr.PatientID
JOIN DimTreatment dt 
    ON tr.TreatmentType = dt.TreatmentType

-- Outcome
JOIN SOURCE_OralPatient.dbo.Outcome o 
    ON p.PatientID = o.PatientID;


ALTER TABLE DimRiskFactors
ADD ChronicSunExposure VARCHAR(5),
    PoorOralHygiene VARCHAR(5),
    Diet VARCHAR(20),
    FamilyHistory VARCHAR(5),
    ImmuneSystem VARCHAR(5);


ALTER TABLE FactPatientHealth
ADD EarlyDiagnosis VARCHAR(5),
    OralCancerDiagnosis VARCHAR(5),
    CostUSD DECIMAL(10,2);


CREATE TABLE DimDiagnosis (
    DiagnosisKey INT IDENTITY PRIMARY KEY,
    EarlyDiagnosis VARCHAR(5),
    OralCancerDiagnosis VARCHAR(5)
);



ALTER TABLE FactPatientHealth
ADD DiagnosisKey INT;

ALTER TABLE FactPatientHealth
ADD CONSTRAINT FK_FactPatientHealth_DimDiagnosis
    FOREIGN KEY (DiagnosisKey) REFERENCES DimDiagnosis(DiagnosisKey);



-- 1. Patients
INSERT INTO DimPatient (PatientID, Age, Gender, Country)
SELECT PatientID, Age, Gender, Country
FROM SOURCE_OralPatient.dbo.Patient;

-- 2. Risk Factors
INSERT INTO DimRiskFactors (
    TobaccoUse, AlcoholConsumption, HPVInfection, BetelQuidUse,
    ChronicSunExposure, PoorOralHygiene, Diet, FamilyHistory, ImmuneSystem
)
SELECT DISTINCT
    TobaccoUse, AlcoholConsumption, HPVInfection, BetelQuidUse,
    ChronicSunExposure, PoorOralHygiene, Diet, FamilyHistory, ImmuneSystem
FROM SOURCE_OralPatient.dbo.RiskFactors;

-- 3. Symptoms
INSERT INTO DimSymptoms (
    OralLesions, UnexplainedBleeding, DifficultySwallowing, WhiteRedPatches
)
SELECT DISTINCT
    OralLesions, UnexplainedBleeding, DifficultySwallowing, WhiteRedPatches
FROM SOURCE_OralPatient.dbo.Symptoms;

-- 4. Treatment
INSERT INTO DimTreatment (TreatmentType)
SELECT DISTINCT TreatmentType
FROM SOURCE_OralPatient.dbo.Treatment;

-- 5. Diagnosis (new)
INSERT INTO DimDiagnosis (EarlyDiagnosis, OralCancerDiagnosis)
SELECT DISTINCT
    EarlyDiagnosis,
    Diagnosis
FROM SOURCE_OralPatient.dbo.Outcome;




INSERT INTO FactPatientHealth (
    PatientKey, RiskKey, SymptomKey, TreatmentKey, DiagnosisKey,
    TumorSize, CancerStage, SurvivalRate, EconomicBurden,
    EarlyDiagnosis, OralCancerDiagnosis, CostUSD
)
SELECT 
    dp.PatientKey,
    dr.RiskKey,
    ds.SymptomKey,
    dt.TreatmentKey,
    dd.DiagnosisKey,
    t.TumorSize,
    t.CancerStage,
    o.SurvivalRate,
    o.EconomicBurden,
    o.EarlyDiagnosis,
    o.Diagnosis,
    tr.CostUSD
FROM SOURCE_OralPatient.dbo.Patient p
JOIN DimPatient dp ON p.PatientID = dp.PatientID
JOIN SOURCE_OralPatient.dbo.RiskFactors r ON p.PatientID = r.PatientID
JOIN DimRiskFactors dr 
    ON r.TobaccoUse = dr.TobaccoUse
    AND r.AlcoholConsumption = dr.AlcoholConsumption
    AND r.HPVInfection = dr.HPVInfection
    AND r.BetelQuidUse = dr.BetelQuidUse
    AND r.ChronicSunExposure = dr.ChronicSunExposure
    AND r.PoorOralHygiene = dr.PoorOralHygiene
    AND r.Diet = dr.Diet
    AND r.FamilyHistory = dr.FamilyHistory
    AND r.ImmuneSystem = dr.ImmuneSystem
JOIN SOURCE_OralPatient.dbo.Symptoms s ON p.PatientID = s.PatientID
JOIN DimSymptoms ds 
    ON s.OralLesions = ds.OralLesions
    AND s.UnexplainedBleeding = ds.UnexplainedBleeding
    AND s.DifficultySwallowing = ds.DifficultySwallowing
    AND s.WhiteRedPatches = ds.WhiteRedPatches
JOIN SOURCE_OralPatient.dbo.Tumor t ON p.PatientID = t.PatientID
JOIN SOURCE_OralPatient.dbo.Treatment tr ON p.PatientID = tr.PatientID
JOIN DimTreatment dt ON tr.TreatmentType = dt.TreatmentType
JOIN SOURCE_OralPatient.dbo.Outcome o ON p.PatientID = o.PatientID
JOIN DimDiagnosis dd 
    ON o.EarlyDiagnosis = dd.EarlyDiagnosis
    AND o.Diagnosis = dd.OralCancerDiagnosis;





SELECT 'DimPatient' AS TableName, COUNT(*) AS Rows FROM DimPatient UNION ALL
SELECT 'DimRiskFactors', COUNT(*) FROM DimRiskFactors UNION ALL
SELECT 'DimSymptoms', COUNT(*) FROM DimSymptoms UNION ALL
SELECT 'DimTreatment', COUNT(*) FROM DimTreatment UNION ALL
SELECT 'DimDiagnosis', COUNT(*) FROM DimDiagnosis UNION ALL
SELECT 'FactPatientHealth', COUNT(*) FROM FactPatientHealth;



-- Cancer Stage 0 but tumor size > 2cm is suspicious
SELECT 
    dp.PatientID,
    dp.Age,
    dp.Country,
    f.TumorSize,
    f.CancerStage,
    'Stage 0 with Large Tumor' AS AnomalyType
FROM FactPatientHealth f
JOIN DimPatient dp ON f.PatientKey = dp.PatientKey
WHERE f.CancerStage = 0 
AND f.TumorSize > 2.0;




-- Stage 3/4 cancer but survival rate > 80% is unusual
SELECT 
    dp.PatientID,
    dp.Age,
    f.CancerStage,
    f.SurvivalRate,
    'High Survival at Late Stage' AS AnomalyType
FROM FactPatientHealth f
JOIN DimPatient dp ON f.PatientKey = dp.PatientKey
WHERE f.CancerStage >= 3 
AND f.SurvivalRate > 80;



-- Diagnosed with oral cancer but received no treatment
SELECT 
    dp.PatientID,
    dp.Country,
    f.OralCancerDiagnosis,
    dt.TreatmentType,
    'Cancer Diagnosed but No Treatment' AS AnomalyType
FROM FactPatientHealth f
JOIN DimPatient dp ON f.PatientKey = dp.PatientKey
JOIN DimTreatment dt ON f.TreatmentKey = dt.TreatmentKey
WHERE f.OralCancerDiagnosis = 'Yes'
AND dt.TreatmentType = 'No Treatment';



-- Had surgery/radiation but cost is 0
SELECT 
    dp.PatientID,
    dt.TreatmentType,
    f.CostUSD,
    'Treatment with Zero Cost' AS AnomalyType
FROM FactPatientHealth f
JOIN DimPatient dp ON f.PatientKey = dp.PatientKey
JOIN DimTreatment dt ON f.TreatmentKey = dt.TreatmentKey
WHERE f.CostUSD = 0 
AND dt.TreatmentType != 'No Treatment';




-- No risk factors at all but still diagnosed with cancer
SELECT 
    dp.PatientID,
    dp.Age,
    dp.Country,
    'Cancer with Zero Risk Factors' AS AnomalyType
FROM FactPatientHealth f
JOIN DimPatient dp ON f.PatientKey = dp.PatientKey
JOIN DimRiskFactors dr ON f.RiskKey = dr.RiskKey
WHERE f.OralCancerDiagnosis = 'Yes'
AND dr.TobaccoUse = 'No'
AND dr.AlcoholConsumption = 'No'
AND dr.HPVInfection = 'No'
AND dr.BetelQuidUse = 'No'
AND dr.ChronicSunExposure = 'No'
AND dr.PoorOralHygiene = 'No'
AND dr.FamilyHistory = 'No'
AND dr.ImmuneSystem = 'No';




CREATE VIEW AnomalyReport AS

SELECT dp.PatientID, dp.Age, dp.Country,
    f.TumorSize, f.CancerStage, f.SurvivalRate,
    'Stage 0 with Large Tumor' AS AnomalyType
FROM FactPatientHealth f
JOIN DimPatient dp ON f.PatientKey = dp.PatientKey
WHERE f.CancerStage = 0 AND f.TumorSize > 2.0

UNION ALL

SELECT dp.PatientID, dp.Age, dp.Country,
    f.TumorSize, f.CancerStage, f.SurvivalRate,
    'High Survival at Late Stage'
FROM FactPatientHealth f
JOIN DimPatient dp ON f.PatientKey = dp.PatientKey
WHERE f.CancerStage >= 3 AND f.SurvivalRate > 80

UNION ALL

SELECT dp.PatientID, dp.Age, dp.Country,
    f.TumorSize, f.CancerStage, f.SurvivalRate,
    'Cancer Diagnosed but No Treatment'
FROM FactPatientHealth f
JOIN DimPatient dp ON f.PatientKey = dp.PatientKey
JOIN DimTreatment dt ON f.TreatmentKey = dt.TreatmentKey
WHERE f.OralCancerDiagnosis = 'Yes' AND dt.TreatmentType = 'No Treatment'

UNION ALL

SELECT dp.PatientID, dp.Age, dp.Country,
    f.TumorSize, f.CancerStage, f.SurvivalRate,
    'Treatment with Zero Cost'
FROM FactPatientHealth f
JOIN DimPatient dp ON f.PatientKey = dp.PatientKey
JOIN DimTreatment dt ON f.TreatmentKey = dt.TreatmentKey
WHERE f.CostUSD = 0 AND dt.TreatmentType != 'No Treatment'

UNION ALL

SELECT dp.PatientID, dp.Age, dp.Country,
    f.TumorSize, f.CancerStage, f.SurvivalRate,
    'Cancer with Zero Risk Factors'
FROM FactPatientHealth f
JOIN DimPatient dp ON f.PatientKey = dp.PatientKey
JOIN DimRiskFactors dr ON f.RiskKey = dr.RiskKey
WHERE f.OralCancerDiagnosis = 'Yes'
AND dr.TobaccoUse = 'No' AND dr.AlcoholConsumption = 'No'
AND dr.HPVInfection = 'No' AND dr.BetelQuidUse = 'No'
AND dr.ChronicSunExposure = 'No' AND dr.PoorOralHygiene = 'No'
AND dr.FamilyHistory = 'No' AND dr.ImmuneSystem = 'No';



SELECT * FROM AnomalyReport ORDER BY AnomalyType;
SELECT AnomalyType, COUNT(*) AS TotalAnomalies 
FROM AnomalyReport 
GROUP BY AnomalyType;



--Check 1 — See actual values in FactPatientHealth
USE OralcancerDWH;
SELECT TOP 5 TumorSize, CancerStage, SurvivalRate, 
             OralCancerDiagnosis, EarlyDiagnosis, CostUSD
FROM FactPatientHealth;



--Check 2 — Check Treatment values
SELECT DISTINCT TreatmentType FROM DimTreatment;


--Check 3 — Check total rows loaded
SELECT COUNT(*) FROM FactPatientHealth;




--Check 4 — Manually test one anomaly rule
SELECT COUNT(*) FROM FactPatientHealth
WHERE CancerStage = 0 AND TumorSize > 2.0;