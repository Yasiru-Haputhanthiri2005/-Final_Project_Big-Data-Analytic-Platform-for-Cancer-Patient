CREATE DATABASE OralcancerDWH;

CREATE TABLE DimPatient (
    PatientKey INT IDENTITY PRIMARY KEY,
    PatientID INT,
    Age INT,
    Gender VARCHAR(10),
    Country VARCHAR(50)
);


CREATE TABLE DimRiskFactors (
    RiskKey INT IDENTITY PRIMARY KEY,
    TobaccoUse VARCHAR(5),
    AlcoholConsumption VARCHAR(5),
    HPVInfection VARCHAR(5),
    BetelQuidUse VARCHAR(5)
);

CREATE TABLE DimSymptoms (
    SymptomKey INT IDENTITY PRIMARY KEY,
    OralLesions VARCHAR(5),
    UnexplainedBleeding VARCHAR(5),
    DifficultySwallowing VARCHAR(5),
    WhiteRedPatches VARCHAR(5)
);


CREATE TABLE DimTreatment (
    TreatmentKey INT IDENTITY PRIMARY KEY,
    TreatmentType VARCHAR(50)
);



CREATE TABLE FactPatientHealth (
    FactID INT IDENTITY PRIMARY KEY,
    PatientKey INT,
    RiskKey INT,
    SymptomKey INT,
    TreatmentKey INT,
    TumorSize DECIMAL(5,2),
    CancerStage INT,
    SurvivalRate DECIMAL(5,2),
    EconomicBurden INT,
    
    FOREIGN KEY (PatientKey) REFERENCES DimPatient(PatientKey),
    FOREIGN KEY (RiskKey) REFERENCES DimRiskFactors(RiskKey),
    FOREIGN KEY (SymptomKey) REFERENCES DimSymptoms(SymptomKey),
    FOREIGN KEY (TreatmentKey) REFERENCES DimTreatment(TreatmentKey)
);




