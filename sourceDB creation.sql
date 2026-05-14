CREATE DATABASE SOURCE_OralPatient;

--create TABLE PATIENT

CREATE TABLE Patient (
    PatientID INT PRIMARY KEY,
    Country VARCHAR(50),
    Age INT,
    Gender VARCHAR(10)
);

--CREATE RISKFACTORS

CREATE TABLE RiskFactors (
    RiskID INT IDENTITY(1,1) PRIMARY KEY,
    PatientID INT,
    TobaccoUse VARCHAR(5),
    AlcoholConsumption VARCHAR(5),
    HPVInfection VARCHAR(5),
    BetelQuidUse VARCHAR(5),
    ChronicSunExposure VARCHAR(5),
    PoorOralHygiene VARCHAR(5),
    Diet VARCHAR(20),
    FamilyHistory VARCHAR(5),
    ImmuneSystem VARCHAR(5),
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID)
);

--create table symptoms

CREATE TABLE Symptoms (
    SymptomID INT IDENTITY(1,1) PRIMARY KEY,
    PatientID INT,
    OralLesions VARCHAR(5),
    UnexplainedBleeding VARCHAR(5),
    DifficultySwallowing VARCHAR(5),
    WhiteRedPatches VARCHAR(5),
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID)
);

--create table tumor

CREATE TABLE Tumor (
    TumorID INT IDENTITY(1,1) PRIMARY KEY,
    PatientID INT,
    TumorSize DECIMAL(5,2),
    CancerStage INT,
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID)
);

--create treatment
CREATE TABLE Treatment (
    TreatmentID INT IDENTITY(1,1) PRIMARY KEY,
    PatientID INT,
    TreatmentType VARCHAR(50),
    CostUSD DECIMAL(10,2),
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID)
);


--outcome table 

CREATE TABLE Outcome (
    OutcomeID INT IDENTITY(1,1) PRIMARY KEY,
    PatientID INT,
    SurvivalRate DECIMAL(5,2),
    EconomicBurden INT,
    EarlyDiagnosis VARCHAR(5),
    Diagnosis VARCHAR(5),
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID)
);


