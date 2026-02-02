IF DB_ID('UniDB') IS NULL
  CREATE DATABASE UniDB;
GO

USE UniDB;
GO

-- drop tables (based on dependency)
DROP TABLE IF EXISTS dbo.Enrollments;
DROP TABLE IF EXISTS dbo.Sections;
DROP TABLE IF EXISTS dbo.CoursePrerequisites;
DROP TABLE IF EXISTS dbo.ProgramCourses;
DROP TABLE IF EXISTS dbo.Students;
DROP TABLE IF EXISTS dbo.ProgramGraduationRules;
DROP TABLE IF EXISTS dbo.GradeScale;
DROP TABLE IF EXISTS dbo.Courses;
DROP TABLE IF EXISTS dbo.Terms;
DROP TABLE IF EXISTS dbo.Programs;
GO

-- tables
-- create table programs
CREATE TABLE dbo.Programs(
    ProgramID INT IDENTITY(1,1) PRIMARY KEY,
    ProgramCode VARCHAR(10) NOT NULL UNIQUE,
    ProgramName VARCHAR(100) NOT NULL,
    Degree VARCHAR(10) NOT NULL
);
GO
-- create table students
CREATE TABLE dbo.Students (
    StudentID INT IDENTITY(1,1) PRIMARY KEY,
    StudentNumber VARCHAR(20) NOT NULL UNIQUE,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(120) NOT NULL UNIQUE,
    ProgramID INT NOT NULL,
    StartYear SMALLINT NOT NULL,
    Status VARCHAR(12) NOT NULL DEFAULT 'active',
    CONSTRAINT FK_Students_Program
    FOREIGN KEY (ProgramID) REFERENCES dbo.Programs(ProgramID)
);
GO
-- create table courses
CREATE TABLE dbo.Courses(
    CourseID INT IDENTITY(1,1) PRIMARY KEY,
    CourseCode VARCHAR(12) NOT NULL UNIQUE,
    CourseTitle VARCHAR(120) NOT NULL,
    Credits DECIMAL(3,1) NOT NULL
);
GO
-- create table terms
CREATE TABLE dbo.Terms (
    TermID INT IDENTITY(1,1) PRIMARY KEY,
    TermCode VARCHAR(10) NOT NULL UNIQUE,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    CONSTRAINT CK_Terms_Dates CHECK (EndDate > StartDate)
);
GO
-- create table sections
CREATE TABLE dbo.Sections (
    SectionID INT IDENTITY(1,1) PRIMARY KEY,
    CourseID INT NOT NULL,
    TermID INT NOT NULL,
    SectionCode VARCHAR(10) NOT NULL,
    Instructor VARCHAR(80) NULL,
    CONSTRAINT FK_Sections_Course FOREIGN KEY (CourseID) REFERENCES dbo.Courses(CourseID),
    CONSTRAINT FK_Sections_Term   FOREIGN KEY (TermID)   REFERENCES dbo.Terms(TermID),
    CONSTRAINT UQ_Section UNIQUE (CourseID, TermID, SectionCode)
);
GO
-- creat table enrollements
CREATE TABLE dbo.Enrollments (
    EnrollmentID INT IDENTITY(1,1) PRIMARY KEY,
    StudentID INT NOT NULL,
    SectionID INT NOT NULL,
    EnrolledOn DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    FinalPercent DECIMAL(5,2) NULL,
    LetterGrade VARCHAR(2) NULL,
    CONSTRAINT CK_FinalPercent CHECK (FinalPercent IS NULL OR (FinalPercent >= 0 AND FinalPercent <= 100)),
    CONSTRAINT FK_Enrollments_Student FOREIGN KEY (StudentID) REFERENCES dbo.Students(StudentID),
    CONSTRAINT FK_Enrollments_Section FOREIGN KEY (SectionID) REFERENCES dbo.Sections(SectionID),
    CONSTRAINT UQ_Enrollment UNIQUE (StudentID, SectionID)
);
GO
-- insert programs
-- insert basic stuff like programs
INSERT INTO dbo.Programs (ProgramCode, ProgramName, Degree) VALUES
('CS','Computer Science','BSc'),
('BU','Business Administration','BBA'),
('EN','Engineering','BEng');
GO

-- support tables
-- gradescale
CREATE TABLE dbo.GradeScale(
    LetterGrade VARCHAR(2) NOT NULL PRIMARY KEY,
    GradePoints DECIMAL(3,2) NOT NULL
);
GO
INSERT INTO dbo.GradeScale (LetterGrade, GradePoints) VALUES
('A+',4.00),('A',4.00),('A-',3.70),
('B+',3.30),('B',3.00),('B-',2.70),
('C+',2.30),('C',2.00),('C-',1.70),
('D+',1.30),('D',1.00),('D-',0.70),
('F',0.00);
GO

-- edit enrollment table to make sure grade is from scale
ALTER TABLE dbo.Enrollments
ADD CONSTRAINT FK_Enrollments_GradeScale
FOREIGN KEY (LetterGrade) REFERENCES dbo.GradeScale(LetterGrade);
GO

-- to graduate must have 30 creds, at max 12 100 level creds, at least 20 program creds
CREATE TABLE dbo.ProgramGraduationRules (
    ProgramID INT PRIMARY KEY,
    RequiredCredits DECIMAL(4,1) NOT NULL DEFAULT 30.0,
    Max100LevelCredits DECIMAL(4,1) NOT NULL, -- 12.0
    MinProgramCredits DECIMAL(4,1) NOT NULL, -- 20.0
    CONSTRAINT FK_PGR_Program FOREIGN KEY (ProgramID) REFERENCES dbo.Programs(ProgramID),
    CONSTRAINT CK_PGR_Values CHECK (
        RequiredCredits > 0
        AND Max100LevelCredits >= 0
        AND MinProgramCredits >= 0
        AND Max100LevelCredits <= RequiredCredits
        AND MinProgramCredits <= RequiredCredits
    )
);
GO


CREATE TABLE dbo.ProgramCourses (
    ProgramID INT NOT NULL,
    CourseID  INT NOT NULL,
    RequirementType VARCHAR(12) NOT NULL,
    CONSTRAINT PK_ProgramCourses PRIMARY KEY (ProgramID, CourseID),
    CONSTRAINT FK_PC_Program FOREIGN KEY (ProgramID) REFERENCES dbo.Programs(ProgramID),
    CONSTRAINT FK_PC_Course  FOREIGN KEY (CourseID)  REFERENCES dbo.Courses(CourseID),
    CONSTRAINT CK_PC_Type CHECK (RequirementType IN ('REQUIRED','ELECTIVE'))
);
GO

-- course prerequisites: course -> prereq course
CREATE TABLE dbo.CoursePrerequisites (
    CourseID INT NOT NULL,
    PrereqCourseID INT NOT NULL,
    CONSTRAINT PK_CoursePrerequisites PRIMARY KEY (CourseID, PrereqCourseID),
    CONSTRAINT FK_CP_Course FOREIGN KEY (CourseID) REFERENCES dbo.Courses(CourseID),
    CONSTRAINT FK_CP_Prereq FOREIGN KEY (PrereqCourseID) REFERENCES dbo.Courses(CourseID),
    CONSTRAINT CK_CP_NoSelf CHECK (CourseID <> PrereqCourseID)
);
GO

-- add more constraints
ALTER TABLE dbo.Courses
ADD CourseNum AS TRY_CONVERT(int, RIGHT(CourseCode, 3)) PERSISTED;
GO

-- junior vs. senior courses
ALTER TABLE dbo.Courses
ADD CourseLevel AS (
    CASE
        WHEN TRY_CONVERT(int, RIGHT(CourseCode, 3)) BETWEEN 100 AND 199 THEN 'JUNIOR'
        WHEN TRY_CONVERT(int, RIGHT(CourseCode, 3)) BETWEEN 200 AND 499 THEN 'SENIOR'
        ELSE NULL
    END
) PERSISTED;
GO


-- course num has to be valid
ALTER TABLE dbo.Courses
ADD CONSTRAINT CK_Courses_CourseNum
CHECK (TRY_CONVERT(int, RIGHT(CourseCode, 3)) BETWEEN 100 AND 499);
GO
-- one rule row per program
INSERT INTO dbo.ProgramGraduationRules (ProgramID, RequiredCredits, Max100LevelCredits, MinProgramCredits)
SELECT ProgramID, 30.0, 12.0, 20.0
FROM dbo.Programs;
GO


-- basic views
-- SELECT name
-- FROM sys.tables
-- ORDER BY name;
-- GO

SELECT 'Programs' AS TableName, COUNT(*) AS Rows FROM dbo.Programs
UNION ALL SELECT 'Courses', COUNT(*) FROM dbo.Courses
UNION ALL SELECT 'Terms', COUNT(*) FROM dbo.Terms
UNION ALL SELECT 'Students', COUNT(*) FROM dbo.Students
UNION ALL SELECT 'Sections', COUNT(*) FROM dbo.Sections
UNION ALL SELECT 'Enrollments', COUNT(*) FROM dbo.Enrollments
UNION ALL SELECT 'ProgramCourses', COUNT(*) FROM dbo.ProgramCourses
UNION ALL SELECT 'CoursePrerequisites', COUNT(*) FROM dbo.CoursePrerequisites
UNION ALL SELECT 'ProgramGraduationRules', COUNT(*) FROM dbo.ProgramGraduationRules
UNION ALL SELECT 'GradeScale', COUNT(*) FROM dbo.GradeScale;