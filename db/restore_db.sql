USE master

DECLARE @path VARCHAR(100), @dbname VARCHAR(100), @mdfFile VARCHAR(100), @logFile VARCHAR(100), @mdfPath VARCHAR(100), @logPath VARCHAR(100)

------------------------
-- CHANGE THESE SETTINGS
------------------------
SET @path = 'C:\Temp\2014-07-04-MCP.bak'
SET @dbname = 'MCP_111214'
SET @mdfPath = 'C:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\MCP_111214.mdf'
SET @logPath = 'C:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\MCP_111214_1.ldf'
--SET @mdfPath = 'E:\MSSQL11.MSSQLSERVER\MSSQL\DATA\MCP_111214.mdf'
--SET @logPath = 'E:\MSSQL11.MSSQLSERVER\MSSQL\DATA\MCP_111214_1.ldf'
------------------------
-- END CHANGING AREA
------------------------

DECLARE @FileList TABLE
      (
      LogicalName nvarchar(128) NOT NULL,
      PhysicalName nvarchar(260) NOT NULL,
      Type char(1) NOT NULL,
      FileGroupName nvarchar(120) NULL,
      Size numeric(20, 0) NOT NULL,
      MaxSize numeric(20, 0) NOT NULL,
      FileID bigint NULL,
      CreateLSN numeric(25,0) NULL,
      DropLSN numeric(25,0) NULL,
      UniqueID uniqueidentifier NULL,
      ReadOnlyLSN numeric(25,0) NULL ,
      ReadWriteLSN numeric(25,0) NULL,
      BackupSizeInBytes bigint NULL,
      SourceBlockSize int NULL,
      FileGroupID int NULL,
      LogGroupGUID uniqueidentifier NULL,
      DifferentialBaseLSN numeric(25,0)NULL,
      DifferentialBaseGUID uniqueidentifier NULL,
      IsReadOnly bit NULL,
      IsPresent bit NULL,
      TDEThumbprint varbinary(32) NULL
 );

-- Step 1: Retrieve the Logical file name of the database from backup.
INSERT INTO @FileList
      EXEC('RESTORE FILELISTONLY FROM DISK = ''' + @path + '''');
select * from @FileList

SET @mdfFile = (select top 1 LogicalName from @FileList where PhysicalName like '%.mdf')
SET @logFile = (select top 1 LogicalName from @FileList where PhysicalName like '%.ldf')

-- check if db exists, create it if not
IF (NOT EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE ('[' + name + ']' = @dbname OR name = @dbname)))
	exec ('create database ' + @dbname)

-- Step 2: Use the values in the LogicalName Column in following Step.
----Make Database to single user Mode
EXEC('ALTER DATABASE ' + @dbname + ' SET SINGLE_USER WITH ROLLBACK IMMEDIATE')

----Restore Database
EXEC('RESTORE DATABASE ' + @dbname + ' FROM DISK = ''' + @path + ''' WITH REPLACE, MOVE ''' + @mdfFile + ''' TO ''' + @mdfPath + ''', MOVE ''' + @logFile + ''' TO ''' + @logPath + '''')

/*If there is no error in statement before database will be in multiuser
mode.
If error occurs please execute following command it will convert
database in multi user.*/
EXEC('ALTER DATABASE ' + @dbname + ' SET MULTI_USER')

go
use MCP_111214

-- fix db
if not exists(select * from sys.columns 
            where Name = N'AuditMcpUserID' and Object_ID = Object_ID(N'tProductUnit'))
begin
	ALTER TABLE [dbo].[tProductUnit] 
		add [AuditMcpUserID] [uniqueidentifier] NULL
end

if not exists(select * from sys.columns 
            where Name = N'AuditMcpUserName' and Object_ID = Object_ID(N'tProductUnit'))
begin
	ALTER TABLE [dbo].[tProductUnit] 
		add [AuditMcpUserName] varchar NULL
end

if not exists(select * from sys.columns 
            where Name = N'AuditMcpUserID' and Object_ID = Object_ID(N'tProductUnit_Audit'))
begin
	ALTER TABLE [dbo].[tProductUnit_Audit] 
		add [AuditMcpUserID] [uniqueidentifier] NULL
end

if not exists(select * from sys.columns 
            where Name = N'AuditMcpUserName' and Object_ID = Object_ID(N'tProductUnit_Audit'))
begin
	ALTER TABLE [dbo].[tProductUnit_Audit] 
		add [AuditMcpUserName] varchar NULL
end

if object_id('dbo.usptCarePoint_Find', 'p') is not null
	drop procedure usptCarePoint_Find

use master