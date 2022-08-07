



go
alter schema Questions transfer [dbo].[TrueFalseQuestion]
go
alter schema Questions transfer [dbo].[TextQuestion]

alter schema Questions TRANSFER [dbo].[MCQ]

alter schema Questions TRANSFER [dbo].[ExamQuestion]


go
alter schema Exam transfer [dbo].[Exam]
go
alter schema Exam transfer [dbo].StudentExamResult

go
alter schema Person transfer [dbo].[Student]
go
alter schema Person transfer [dbo].[Instructor]


alter schema [StudentData]TRANSFER [dbo].[DIBT]

alter schema [StudentData]TRANSFER [dbo].[Track]
go
alter schema [StudentData]TRANSFER [dbo].[Branch]
go
alter schema [StudentData]TRANSFER [dbo].[Department]

alter schema CourseData TRANSFER [dbo].[CourseTeachingYear]
alter schema CourseData TRANSFER [dbo].[Course]

alter schema CourseData TRANSFER [dbo].[Class]