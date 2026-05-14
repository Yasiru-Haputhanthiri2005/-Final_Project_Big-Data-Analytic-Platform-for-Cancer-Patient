USE SOURCE_OralPatient;
GO


-- ETL TO PATIENT FROM asia_oral_cancer_data

INSERT INTO dbo.Patient (PatientID, Country, Age, Gender)
SELECT ID, Country, Age, Gender
FROM dbo.asia_oral_cancer_data;

--
INSERT INTO dbo.RiskFactors
(
    PatientID,
    TobaccoUse,
    AlcoholConsumption,
    HPVInfection,
    BetelQuidUse,
    ChronicSunExposure,
    PoorOralHygiene,
    Diet,
    FamilyHistory,
    ImmuneSystem
)
SELECT 
    ID AS PatientID,
    Tobacco_Use AS TobaccoUse,
    Alcohol_Consumption AS AlcoholConsumption,
    HPV_Infection AS HPVInfection,
    Betel_Quid_Use AS BetelQuidUse,
    Chronic_Sun_Exposure AS ChronicSunExposure,
    Poor_Oral_Hygiene AS PoorOralHygiene,
    Diet_Fruits_Vegetables_Intake AS Diet,
    Family_History_of_Cancer AS FamilyHistory,
    Compromised_Immune_System AS ImmuneSystem
FROM dbo.asia_oral_cancer_data;


INSERT INTO dbo.Symptoms
(
    PatientID,
    OralLesions,
    UnexplainedBleeding,
    DifficultySwallowing,
    WhiteRedPatches
)
SELECT 
    ID,
    Oral_Lesions,
    Unexplained_Bleeding,
    Difficulty_Swallowing,
    White_or_Red_Patches_in_Mouth
FROM dbo.asia_oral_cancer_data;



--

INSERT INTO dbo.Tumor
(
    PatientID,
    TumorSize,
    CancerStage
)
SELECT 
    ID,
    Tumor_Size_cm,
    Cancer_Stage
FROM dbo.asia_oral_cancer_data;



INSERT INTO dbo.Treatment
(
    PatientID,
    TreatmentType,
    CostUSD
)
SELECT 
    ID,
    Treatment_Type,
    Cost_of_Treatment_USD
FROM dbo.asia_oral_cancer_data;

