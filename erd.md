erDiagram
  PROGRAMS ||--o{ STUDENTS : has
  PROGRAMS ||--|| PROGRAMGRADUATIONRULES : rules
  PROGRAMS ||--o{ PROGRAMCOURSES : includes
  COURSES  ||--o{ PROGRAMCOURSES : mapped_by

  COURSES ||--o{ SECTIONS : offered_as
  TERMS   ||--o{ SECTIONS : occurs_in

  STUDENTS ||--o{ ENROLLMENTS : makes
  SECTIONS ||--o{ ENROLLMENTS : contains
  GRADESCALE ||--o{ ENROLLMENTS : assigns

  COURSES ||--o{ COURSEPREREQUISITES : course
  COURSES ||--o{ COURSEPREREQUISITES : prereq

  PROGRAMS {
    int ProgramID PK
    string ProgramCode
    string ProgramName
    string Degree
  }

  STUDENTS {
    int StudentID PK
    string StudentNumber
    string FirstName
    string LastName
    string Email
    int ProgramID FK
    int StartYear
    string Status
  }

  COURSES {
    int CourseID PK
    string CourseCode
    string CourseTitle
    float Credits
    int CourseNum "computed"
    string CourseLevel "computed"
  }

  TERMS {
    int TermID PK
    string TermCode
    date StartDate
    date EndDate
  }

  SECTIONS {
    int SectionID PK
    int CourseID FK
    int TermID FK
    string SectionCode
    string Instructor
  }

  ENROLLMENTS {
    int EnrollmentID PK
    int StudentID FK
    int SectionID FK
    date EnrolledOn
    float FinalPercent
    string LetterGrade FK
  }

  GRADESCALE {
    string LetterGrade PK
    float GradePoints
  }

  PROGRAMGRADUATIONRULES {
    int ProgramID PK, FK
    float RequiredCredits
    float Max100LevelCredits
    float MinProgramCredits
  }

  PROGRAMCOURSES {
    int ProgramID PK, FK
    int CourseID PK, FK
    string RequirementType
  }

  COURSEPREREQUISITES {
    int CourseID PK, FK
    int PrereqCourseID PK, FK
  }
