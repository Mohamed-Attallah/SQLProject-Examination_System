--student schema
--as view  
go
create view  ShowAllCourses as
select cr.Title as course ,i.[Name]as instructorName,
t.[Name]as track,cl.Number as class,b.Name as branch
from CourseData.Course cr,Person.Instructor i,StudentData.Track t,CourseData.Class cl,
StudentData.Branch b,
CourseData.CourseTeachingYear cty,
StudentData.DIBT 
where
cr.ID=cty.CourseID and
cr.IsDeleted=0 and
cl.ID=cty.ClassID and
i.ID=cty.InstructorID and
DIBT.CourseID=cr.ID and
DIBT.TrackID=t.ID and
DIBT.BranchID=b.ID

select * from ShowAllCourses

--as func
go
create function AvailableCourses() 
returns @AvailableCourses table
  (
   CourseTitle SmallCustomString,
   InstructorName SmallCustomString,
   TrackName  SmallCustomString,
   ClassNumber varchar(3),
   BranchName SmallCustomString
   )
as
begin
  insert into @AvailableCourses
  select cr.Title ,i.[Name],
	t.[Name],cl.Number,b.Name as branch
	from 	CourseData.Course cr,Person.Instructor i,StudentData.Track t,CourseData.Class cl,
StudentData.Branch b,
CourseData.CourseTeachingYear cty,
StudentData.DIBT where
	cr.ID=cty.CourseID and
	cr.IsDeleted=0 and
	cl.ID=cty.ClassID and
	i.ID=cty.InstructorID and
	DIBT.CourseID=cr.ID and
	DIBT.TrackID=t.ID and
	DIBT.BranchID=b.ID
return
end

select * from AvailableCourses()
----------------------------------ShowStudentCourses
go
create PROCEDURE ShowStudentCourses
@UserName SmallCustomString
as
begin
select  distinct cr.Title as course ,i.[Name]as instructorName,t.[Name]as track,cl.Number as class,b.Name as branch
from CourseData.Course cr,Person.Instructor i,StudentData.Track t,CourseData.Class cl,
StudentData.Branch b,
CourseData.CourseTeachingYear cty,StudentData.DIBT ,Person.Student
where
cr.ID=cty.CourseID and
cr.IsDeleted=0 and
cl.ID=cty.ClassID and
i.ID=cty.InstructorID and
DIBT.CourseID=cr.ID and
DIBT.TrackID=t.ID and
DIBT.BranchID=b.ID and
cr.ID=DIBT.CourseID and
DIBT.StudentID=(select ID from Person.Student where UserName=@UserName)
end
--
ShowStudentCourses 'NadaUser'

--!!repeated records

create PROCEDURE EditUserName
@OldUserName SmallCustomString,@newUserName SmallCustomString
as update Person.Student set UserName=@newUserName where UserName=@OldUserName

EditUserName 'NoorUser' ,'NoorUser1'

create PROCEDURE EditPassWord
@UserName SmallCustomString,@newPassword SmallCustomString
as update Person.Student set Password=@newPassword where UserName=@UserName
EditPassWord 'NoorUser','NoorPass'



create PROCEDURE AddStudentToCourse
@UserName SmallCustomString,@Title SmallCustomString
as
declare @courseID int;
select @courseID=ID from CourseData.Course where Title=@Title;
declare @studentID SmallCustomString;
select @studentID=ID from Person.Student where UserName=@UserName;
Update StudentData.DIBT set CourseID =@courseID where StudentID=@studentID  


insert into [StudentData].[DIBT] values (1,1,1,2,1,2,default)


create PROCEDURE RemoveStudentFromCourse
@UserName SmallCustomString,@Title SmallCustomString
as
declare @courseID int;
select @courseID=ID from CourseData.Course where Title=@Title;
declare @studentID SmallCustomString;
select @studentID=ID from Person.Student where UserName=@UserName;
Update StudentData.DIBT set IsDeleted =1 where StudentID=@studentID and CourseID=@courseID

--RemoveStudentFromCourse 

alter  procedure DoExam 
@UserName SmallCustomString,@ExamID SmallCustomString
as
begin
declare @studentID SmallCustomString;
select @studentID=ID from Person.Student where UserName=@UserName;
  if exists(select* from Exam.StudentExamResult where ExamID=@ExamID and StudentID=@studentID)
  begin
    if(DATEDIFF (second,getdate(),(select EndTime from Exam.Exam where ID=@ExamID))>50)
	begin
       print 'your Exam is running '
	end
	else  print 'the Exam closed '
 end
 else  print 'this exam is not for you '
end

DoExam 'NoorUser','1'

insert into Exam.Exam values(getDate(),dateAdd(hour,1,getDate()),1,0,default)
insert into Exam.StudentExamResult values(1,1,50)
---------------------------------------------------
---------------------------------------------------
--select*from MCQ
--select* from ExamQuestion
--update Questions.ExamQuestion set StudentAnswerResult=0
--CalculateQuestionResult 

create  procedure CalculateQuestionResult 
(@UserName SmallCustomString,@QuestionID int,@ExamID int ,@QuestionType char(3))
as
begin
declare @studentID int;
select @studentID=ID from Person.Student where UserName=@UserName;
		declare @studentAnswer BigCustomString
		declare @correctAnswer BigCustomString
		declare @FullDegree int
		declare @StudentAnswerResult int
		select @StudentAnswerResult=0
		if (@QuestionType='MCQ')
		begin
		    select  @QuestionID = MCQID from Questions.ExamQuestion where ExamID=@ExamID
			select @correctAnswer=CorrectChoice from Questions.MCQ where ID=@QuestionID
			select @FullDegree =FullDegree from Questions.MCQ where ID=@QuestionID
			select  @studentAnswer =StudentAnswer from Questions.ExamQuestion where @QuestionID=MCQID
			if(@studentAnswer=@correctAnswer)
				select @StudentAnswerResult+=@FullDegree
            update Questions.ExamQuestion set StudentAnswerResult=@StudentAnswerResult where MCQID=@QuestionID
		end
		else if(@QuestionType='TXQ')
		begin
		    select  @QuestionID = TXQID from Questions.ExamQuestion where ExamID=@ExamID
			select @correctAnswer=BestAnswer from Questions.TextQuestion where ID=@QuestionID
			select @FullDegree =FullDegree from Questions.TextQuestion where ID=@QuestionID
			select  @studentAnswer =StudentAnswer from Questions.ExamQuestion where @QuestionID=TXQID
			if(DIFFERENCE(@studentAnswer,@correctAnswer)>=2)
				select @StudentAnswerResult+=@FullDegree/2
           else if(DIFFERENCE(@studentAnswer,@correctAnswer)>=3)
		        select @StudentAnswerResult+=@FullDegree
		  update Questions.ExamQuestion set StudentAnswerResult=@StudentAnswerResult where TXQID=@QuestionID
		end
		else if(@QuestionType ='TFQ')
	   begin
	        select  @QuestionID = TFQID from Questions.ExamQuestion where ExamID=@ExamID
			select @correctAnswer=CorrectAnswer from Questions.TrueFalseQuestion where ID=@QuestionID
			select @FullDegree =FullDegree from Questions.TrueFalseQuestion where ID=@QuestionID
			select  @studentAnswer =StudentAnswer from Questions.ExamQuestion where @QuestionID=TFQID
			if(@studentAnswer=@correctAnswer)
				select @StudentAnswerResult+=@FullDegree
        	update Questions.ExamQuestion set StudentAnswerResult=@StudentAnswerResult where TFQID=@QuestionID
		end
    end
-----------------------------------------------------------------------

update StudentExamResult set Result=0 where StudentID=1 and ExamID=1

 alter  procedure CalculateFinalResult 
(@UserName SmallCustomString,@ExamID SmallCustomString )
as

declare @studentID int
select @studentID = ID from Person.Student where UserName=@UserName 
declare @FinalResult int
declare s_cur cursor
 for select MCQID,TFQID,TXQID ,QuestionType from Questions.ExamQuestion
 for read only  --read only or Update
declare @MCQID int
declare @TFQID int
declare @TXQID int
declare @QuestionType char(3)
open s_cur 
begin
 fetch s_cur into   @MCQID ,
					 @TFQID ,
					@TXQID ,
					@QuestionType
 While @@fetch_status=0  
 begin
  if(@QuestionType='MCQ')

   exec CalculateQuestionResult @UserName ,@MCQID ,@ExamID ,@QuestionType 
   
  else if(@QuestionType='TXQ')
  
 exec   CalculateQuestionResult @UserName ,@TXQID ,@ExamID ,@QuestionType 
	
 else if(@QuestionType='TFQ')
  exec CalculateQuestionResult @UserName ,@TFQID ,@ExamID ,@QuestionType 
  
 fetch s_cur into   @MCQID ,
					 @TFQID ,
					@TXQID ,
					@QuestionType
end
end
close s_cur
deallocate s_cur

Select @FinalResult = sum(StudentAnswerResult) from Questions.ExamQuestion where ExamID=@ExamID and StudentID=@studentID
update Exam.StudentExamResult set Result= @FinalResult where ExamID=@ExamID and StudentID=@studentID
--CalculateFinalResult  
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

                 /*EditInstructor*/
Create PROCEDURE EditInstructor (@ID ID,@Name SmallCustomString,@UserName SmallCustomString,@Password SmallCustomString,@StatementType NVARCHAR(20) = '')  
AS  
  BEGIN  
      IF @StatementType = 'Insert'  
        BEGIN  
            INSERT INTO  Person.[Instructor]
                        (Name,UserName,Password,ManagerId,IsDeleted)  
            VALUES     (@Name,@UserName,@Password,1,0)  
        END  
     ELSE IF @StatementType = 'Update'  
        BEGIN  
            UPDATE  Person.[Instructor]
            SET    Name = @Name,  
                   UserName = @UserName,  
                   Password = @Password
            WHERE  ID = @ID  
        END     
  END
  
  exec EditInstructor @ID=0,@Name='nawalZaki',@UserName='NonaUser',@Password='1234',@StatementType='Insert'
  exec EditInstructor @ID=4,@Name='nawall',@UserName='Nona4040',@Password='1234',@StatementType='Update'
                /*Show Data Of Instructors*/
create function ShowInstructors(@UserName SmallCustomString) 
returns @ShowInstructors table
		(
		 ID ID primary key,
		Name SmallCustomString,
		UserName SmallCustomString
		)
as
begin
	insert into @ShowInstructors
	select ID,Name,UserName
	from Person.Instructor 
	where UserName=@UserName and IsDeleted=0

return
end

Select * from ShowInstructors('NonaUser')

                    /*Delete Instructor*/
Create PROCEDURE DeleteInstructor (@UserName SmallCustomString)  
AS  
  BEGIN 
        declare @InstructorID AS int ,@CourseID AS int
		set @InstructorID= (select ID from Person.[Instructor] where UserName=@UserName)
		set @CourseID= (select ID from CourseData.[Course] where instructorID=@InstructorID)
		 UPDATE  [CourseData].[CourseTeachingYear]
            SET IsDeleted = 1
			WHERE  CourseID=@CourseID 
            DELETE FROM Person.[Instructor]
            WHERE  UserName = @UserName 
 END  

 exec  DeleteInstructor @UserName='AlyUser'
                 /*Fuction For Get ID's Manager */
Create function ShowManagers() 
returns @ShowManagers table
		(
		 ID ID primary key,
		Name SmallCustomString,
		UserName SmallCustomString
		)
as
begin
	insert into @ShowManagers
	select ID,Name,UserName
	from Person.Instructor 
	where ManagerId IS NULL

return
end
Select * from ShowManagers()
                     /*EditCourse*/
alter PROCEDURE EditCourse (@ID int,@Title SmallCustomString,@Description  BigCustomString,@MinDegree int,@MaxDegree int,@InstructorID int,@StatementType NVARCHAR(20) = '')  
AS  
  BEGIN  
      IF @StatementType = 'Insert'  
        BEGIN  
            INSERT INTO  [CourseData].[Course] 
                        (Title,Description,MinDegree,MaxDegree,instructorID,IsDeleted)  
            VALUES     (@Title,@Description,@MinDegree,@MaxDegree,@InstructorID,0)  
        END  
  
      IF @StatementType = 'Update'  
        BEGIN  
            UPDATE [CourseData].[Course] 
            SET    Title = @Title,  
                   Description = @Description,  
                   MinDegree = @MinDegree,
				   MaxDegree=@MaxDegree,
				    instructorID=@InstructorID
            WHERE  ID = @Id  
        END   
  END 
  
  exec EditCourse @Id=0,@Title='Html5',@Description='More featured from Html',@MinDegree=50,@MaxDegree=100,@InstructorID=3,@StatementType='Insert'
   exec EditCourse @Id=4,@Title='Html',@Description='More featured from Html',@MinDegree=50,@MaxDegree=100,@InstructorID=3,@StatementType='Update'



   /*Delete Courses*/ 
  create PROCEDURE DeleteCourse (@Title SmallCustomString)  
AS  
  BEGIN 
    
            DELETE FROM  CourseData.Course
            WHERE  Title=@Title 
 END
 exec DeleteCourse @Title='Html' 


                     /*EditInsructorInCourse*/
create PROCEDURE EditInsructorInCourse (@Title SmallCustomString,@UserName SmallCustomString)
AS
BEGIN
 declare @InstructorID AS ID
 set @InstructorID = (select ID from Person.Instructor where UserName=@UserName);
      UPDATE  CourseData.[Course]
            SET    instructorID=@InstructorID 
            WHERE  Title = @Title  
End

exec EditInsructorInCourse @Title='XML',@UserName='Nona4040';

                       /*EditDepartment*/
Create PROCEDURE EditDepartment (@DepartmentName SmallCustomString,@TrackName SmallCustomString,@BranchName SmallCustomString)
AS
BEGIN
declare @DepartmentID AS ID , @TrackID AS ID , @BranchID AS ID
    set @DepartmentID = (select ID from StudentData.[Department] where Name=@DepartmentName);
	set @TrackID = (select ID from StudentData.[Track] where Name=@TrackName);
	set @BranchID = (select ID from StudentData.[Branch] where Name=@BranchName);

    UPDATE StudentData.[DIBT]
            SET    BranchID=@BranchID , TrackID=@TrackID
            WHERE   DeptID= @DepartmentID  
End

exec EditDepartment @DepartmentName='InformationSystem',@TrackName='Testing',@BranchName='Assuit'
                        /*View About Department*/
create View DetailsAboutDepartment AS
		select d.name As NameOfDepartment,t.name As NameOfTrack ,b.name AS NameOfBranch
		from StudentData.Department d, StudentData.Track t,StudentData.Branch b ,StudentData.DIBT x
		where x.BranchID=b.ID and x.DeptID=d.ID and x.TrackID=t.ID

select * from DetailsAboutDepartment

						   /*and new track*/
create PROCEDURE AddNewTrack (@Name SmallCustomString)  
AS  
  BEGIN  
            INSERT INTO  StudentData.Track 
            VALUES     (@Name,0)  
 END 

exec AddNewTrack @Name='Mobile'




----------------------------------------------------------------
----------------------------------------------------------------

--permession

--filegroup
--schema
--index 
--bulk insert from excel

--backup& snapshot
--transaction
--trigger
--sequence
