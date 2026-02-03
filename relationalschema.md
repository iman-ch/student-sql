# UniDB – Relational Schema

## Programs
**Columns**
- ProgramID INT IDENTITY -> PK
- ProgramCode VARCHAR(10) -> UNIQUE, NOT NULL
- ProgramName VARCHAR(100) -> NOT NULL
- Degree VARCHAR(10) -> NOT NULL

**Relationships**
- one-to-many -> Students (FK Students.ProgramID)
- one-to-one  -> ProgramGraduationRules (PK/FK ProgramID)
- one-to-many -> ProgramCourses (FK ProgramCourses.ProgramID)
- many-to-many -> Courses (via ProgramCourses)

---

## Students
**Columns**
- StudentID INT IDENTITY -> PK
- StudentNumber VARCHAR(20) -> UNIQUE, NOT NULL
- FirstName VARCHAR(50) -> NOT NULL
- LastName VARCHAR(50) -> NOT NULL
- Email VARCHAR(120) -> UNIQUE, NOT NULL
- ProgramID INT -> FK, NOT NULL
- StartYear SMALLINT -> NOT NULL
- Status VARCHAR(12) -> NOT NULL (default 'active')

**Relationships**
- many-to-one -> Programs (FK Students.ProgramID)
- one-to-many -> Enrollments (FK Enrollments.StudentID)
- many-to-many -> Sections (via Enrollments)

---

## Courses
**Columns**
- CourseID INT IDENTITY -> PK
- CourseCode VARCHAR(12) -> UNIQUE, NOT NULL
- CourseTitle VARCHAR(120) -> NOT NULL
- Credits DECIMAL(3,1) -> NOT NULL
- CourseNum (computed) -> TRY_CONVERT(int, RIGHT(CourseCode, 3))
- CourseLevel (computed) -> JUNIOR / SENIOR
- CHECK -> CourseNum between 100 and 499

**Relationships**
- one-to-many -> Sections (FK Sections.CourseID)
- one-to-many -> ProgramCourses (FK ProgramCourses.CourseID)
- many-to-many -> Programs (via ProgramCourses)
- one-to-many -> CoursePrerequisites (as CourseID)
- one-to-many -> CoursePrerequisites (as PrereqCourseID)
- many-to-many -> Courses (self, via CoursePrerequisites)

---

## Terms
**Columns**
- TermID INT IDENTITY -> PK
- TermCode VARCHAR(10) -> UNIQUE, NOT NULL
- StartDate DATE -> NOT NULL
- EndDate DATE -> NOT NULL
- CHECK -> EndDate > StartDate

**Relationships**
- one-to-many -> Sections (FK Sections.TermID)

---

## Sections
**Columns**
- SectionID INT IDENTITY -> PK
- CourseID INT -> FK, NOT NULL
- TermID INT -> FK, NOT NULL
- SectionCode VARCHAR(10) -> NOT NULL
- Instructor VARCHAR(80) -> NULL
- UNIQUE -> (CourseID, TermID, SectionCode)

**Relationships**
- many-to-one -> Courses (FK Sections.CourseID)
- many-to-one -> Terms (FK Sections.TermID)
- one-to-many -> Enrollments (FK Enrollments.SectionID)
- many-to-many -> Students (via Enrollments)

---

## Enrollments
**Columns**
- EnrollmentID INT IDENTITY -> PK
- StudentID INT -> FK, NOT NULL
- SectionID INT -> FK, NOT NULL
- EnrolledOn DATE -> NOT NULL (default current date)
- FinalPercent DECIMAL(5,2) -> NULL
- LetterGrade VARCHAR(2) -> FK, NULL
- CHECK -> FinalPercent between 0 and 100 (if not NULL)
- UNIQUE -> (StudentID, SectionID)

**Relationships**
- many-to-one -> Students (FK Enrollments.StudentID)
- many-to-one -> Sections (FK Enrollments.SectionID)
- many-to-one -> GradeScale (FK Enrollments.LetterGrade)

---

## GradeScale
**Columns**
- LetterGrade VARCHAR(2) -> PK
- GradePoints DECIMAL(3,2) -> NOT NULL

**Relationships**
- one-to-many -> Enrollments (FK Enrollments.LetterGrade)

---

## ProgramGraduationRules
**Columns**
- ProgramID INT -> PK, FK
- RequiredCredits DECIMAL(4,1) -> NOT NULL (default 30.0)
- Max100LevelCredits DECIMAL(4,1) -> NOT NULL
- MinProgramCredits DECIMAL(4,1) -> NOT NULL
- CHECK -> values <= RequiredCredits and >= 0

**Relationships**
- one-to-one -> Programs (PK/FK ProgramID)

---

## ProgramCourses
**Columns**
- ProgramID INT -> PK (part), FK
- CourseID INT -> PK (part), FK
- RequirementType VARCHAR(12) -> NOT NULL
- CHECK -> RequirementType IN ('REQUIRED', 'ELECTIVE')

**Relationships**
- many-to-one -> Programs (FK ProgramCourses.ProgramID)
- many-to-one -> Courses (FK ProgramCourses.CourseID)
- many-to-many -> Programs <-> Courses (bridge table)

---

## CoursePrerequisites
**Columns**
- CourseID INT -> PK (part), FK
- PrereqCourseID INT -> PK (part), FK
- CHECK -> CourseID <> PrereqCourseID

**Relationships**
- many-to-one -> Courses (as CourseID)
- many-to-one -> Courses (as PrereqCourseID)
- many-to-many -> Courses <-> Courses (self bridge)
