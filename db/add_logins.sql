create table #vars (userName varchar(100), userPassword varchar(100), setOwner bit, windowsLogin bit)

------------------------
-- INSERT USERS HERE
------------------------
insert #vars values ('IIS APPPOOL\[AppPoolName]', '', 0, 1)
insert #vars values ('DOMAIN\windowsuser', '', 1, 1)
insert #vars values ('sqlUser', 'sqlPassword', 1, 0)
------------------------
-- END INSERTING USERS
------------------------

-- create logins
declare @userName varchar(100), @userPassword varchar(100), @setOwner bit, @windowsLogin bit, @cnt int
set @cnt = 0
while (@cnt < (select count(*) from #vars))
begin
	
	set @windowsLogin = (select top 1 windowsLogin from (select *, ROW_NUMBER() over (order by userName) as rowNr from #vars) as users where rowNr = @cnt + 1)
	set @userName = (select top 1 userName from (select *, ROW_NUMBER() over (order by userName) as rowNr from #vars) as users where rowNr = @cnt + 1)
	set @setOwner = (select top 1 setOwner from (select *, ROW_NUMBER() over (order by userName) as rowNr from #vars) as users where rowNr = @cnt + 1)

	if (@windowsLogin <> 0)
		begin
			if not Exists (select loginname from master.dbo.syslogins where name = @userName)
				exec ('create login [' + @userName + '] from windows')
		end
	else
		begin
			if not Exists (select loginname from master.dbo.syslogins where name = @userName)
				begin
					set @userPassword = (select top 1 userPassword from (select *, ROW_NUMBER() over (order by userName) as rowNr from #vars) as users where rowNr = @cnt + 1)
					exec ('create login [' + @userName + '] with password=''' + @userPassword + '''')
				end
		end
	set @cnt = @cnt + 1
end
go

use MCP_111214;

declare @userName varchar(100), @setOwner bit, @cnt int
set @cnt = 0
while (@cnt < (select count(*) from #vars))
begin
	set @userName = (select top 1 userName from (select *, ROW_NUMBER() over (order by userName) as rowNr from #vars) as users where rowNr = @cnt + 1)
	set @setOwner = (select top 1 setOwner from (select *, ROW_NUMBER() over (order by userName) as rowNr from #vars) as users where rowNr = @cnt + 1)
	
	if not exists (SELECT * FROM sys.database_principals WHERE name = @userName)
		exec ('create user [' + @userName + '] from login [' + @userName + '];')

	if (@setOwner <> 0)
		exec sp_addrolemember 'db_owner', @userName;
	else
		begin
			exec sp_addrolemember 'db_datareader', @userName;
			exec sp_addrolemember 'db_datawriter', @userName;
		end

	exec ('GRANT EXECUTE TO [' + @userName + ']')
	set @cnt = @cnt + 1
end

ALTER AUTHORIZATION ON SCHEMA::db_owner TO dbo;
if exists(SELECT * FROM sys.database_principals WHERE name = 'mcpUser')
	drop user mcpUser

go

use MCPSSO_111214;
declare @userName varchar(100), @setOwner bit, @cnt int
set @cnt = 0
while (@cnt < (select count(*) from #vars))
begin
	set @userName = (select top 1 userName from (select *, ROW_NUMBER() over (order by userName) as rowNr from #vars) as users where rowNr = @cnt + 1)
	set @setOwner = (select top 1 setOwner from (select *, ROW_NUMBER() over (order by userName) as rowNr from #vars) as users where rowNr = @cnt + 1)
	
	if not exists (SELECT * FROM sys.database_principals WHERE name = @userName)
		exec ('create user [' + @userName + '] from login [' + @userName + '];')

	if (@setOwner <> 0)
		exec sp_addrolemember 'db_owner', @userName;
	else
		begin
			exec sp_addrolemember 'db_datareader', @userName;
			exec sp_addrolemember 'db_datawriter', @userName;
		end

	exec ('GRANT EXECUTE TO [' + @userName + ']')
	set @cnt = @cnt + 1
end

ALTER AUTHORIZATION ON SCHEMA::db_owner TO dbo;
if exists(SELECT * FROM sys.database_principals WHERE name = 'mcpUser')
	drop user mcpUser

drop table #vars
use master