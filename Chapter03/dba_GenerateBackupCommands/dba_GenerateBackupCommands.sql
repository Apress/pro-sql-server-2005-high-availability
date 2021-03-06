if exists (select * from dbo.sysobjects where id = object_id(N'[dba_GenerateBackupCommands]') and OBJECTPROPERT(id, N'IsProcedure') = 1)
drop procedure [dba_GenerateBackupCommands]
GO

create procedure dba_GenerateBackupCommands 
	@backuptype int,
	@dbname varchar(128)
AS
--
-- Procedure Name: dba_GenerateBackupCommands
-- Purpose: 
-- This stored procedure will build your RESTORE commands using the SQL Server system tables and DMVs. 
-- Author: Allan Hirt
-- Version: 1.0, 10/07
--
-- @dbname = the name of the database to generate the commands for; must be in single quotes
-- Valid values for @backuptype
-- 1, which will return only a full backup
-- 2, which will return the combination of full + transaction logs
-- 3, which will return the combination of full + differential backups
-- 4, which will return the combination of full, differential, and transaction log backups
--
-- Example execution
-- exec dba_GenerateBackupCommands 
--	@backuptype = 4,
--	@dbname = 'TestDB'
--

-- Variables
declare @fullid int
declare @diffid int
declare @trnid int
declare @fullcount int
declare @diffcount int
declare @trncount int
declare @filepath nvarchar(1000)
declare @mediaset int
declare @loopno int

-- Get the number of full backups
set @fullcount = (select count(*) 
from msdb..backupset
where type = 'D'
and database_name = @dbname)

-- Get the number of differential backups
If @fullcount > 0 
begin
	set @fullid = (select max(backup_set_id)
		from msdb..backupset
		where type = 'D'
		and database_name = @dbname)
end

set @diffcount = (select count(*) 
from msdb..backupset
where type = 'I'
and database_name = @dbname)

-- Get the # of transaction logs
set @trncount = (select count(*)
	from msdb..backupset
	where type = 'L'
	and database_name = @dbname
	and backup_set_id >
		(select max(backup_set_id)
			from msdb..backupset
			where type = 'D'
			and database_name = @dbname))

-- Full Backup Only
If @backuptype = 1
begin
	set @filepath = (select physical_device_name
		from msdb..backupmediafamily
		where media_set_id = 
		(select media_set_id 
		from msdb..backupset
		where type = 'D'
		and database_name = @dbname
		and backup_set_id = 
			(select max(backup_set_id)
				from msdb..backupset
				where type = 'D'
				and database_name = @dbname)))
	
		PRINT 'RESTORE DATABASE [' + LTRIM(RTRIM(@dbname)) + '] FROM DISK = N' + CHAR(39) + LTRIM(RTRIM(@filepath)) + CHAR(39)
end

-- Full + Transaction Logs
If @backuptype = 2
begin
	set @filepath = (select physical_device_name
		from msdb..backupmediafamily
		where media_set_id = 
		(select media_set_id 
		from msdb..backupset
		where type = 'D'
		and database_name = @dbname
		and backup_set_id = 
			(select max(backup_set_id)
				from msdb..backupset
				where type = 'D'
				and database_name = @dbname)))
	
		PRINT 'RESTORE DATABASE [' + LTRIM(RTRIM(@dbname)) + '] FROM DISK = N' + CHAR(39) + LTRIM(RTRIM(@filepath)) + CHAR(39) + ' WITH NORECOVERY'

	set @loopno = 1

	DECLARE TLogCursor CURSOR FOR
	select backup_set_id
	from msdb..backupset
	where type = 'L'
	and database_name = @dbname
	and backup_set_id >
		(select max(backup_set_id)
			from msdb..backupset
			where type = 'D'
			and database_name = @dbname)
	
	OPEN TLogCursor

	FETCH NEXT FROM TLogCursor INTO @trnid

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @loopno = @trncount 
		BEGIN
			set @mediaset = (select media_set_id
				from msdb..backupset
				where backup_set_id = @trnid)
			set @filepath = (select physical_device_name
				from msdb..backupmediafamily
				where media_set_id = @mediaset)

			PRINT 'RESTORE LOG [' + LTRIM(RTRIM(@dbname)) + '] FROM DISK = N' + CHAR(39) + LTRIM(RTRIM(@filepath)) + CHAR(39) 			
		END

		IF @loopno <> @trncount	
		BEGIN
			set @mediaset = (select media_set_id
				from msdb..backupset
				where backup_set_id = @trnid)
			set @filepath = (select physical_device_name
				from msdb..backupmediafamily
				where media_set_id = @mediaset)

			PRINT 'RESTORE LOG [' + LTRIM(RTRIM(@dbname)) + '] FROM DISK = N' + CHAR(39) + LTRIM(RTRIM(@filepath)) + CHAR(39) + ' WITH NORECOVERY' 			
		END

		SET @loopno = @loopno + 1
		FETCH NEXT FROM TLogCursor INTO @trnid
	END
	
	CLOSE TLogCursor
	DEALLOCATE TLogCursor
end

-- Full, Differential
If @backuptype = 3
begin
	set @filepath = (select physical_device_name
		from msdb..backupmediafamily
		where media_set_id = 
		(select media_set_id 
		from msdb..backupset
		where type = 'D'
		and database_name = @dbname
		and backup_set_id = 
			(select max(backup_set_id)
				from msdb..backupset
				where type = 'D'
				and database_name = @dbname)))
	
		PRINT 'RESTORE DATABASE [' + LTRIM(RTRIM(@dbname)) + '] FROM DISK = N' + CHAR(39) + LTRIM(RTRIM(@filepath)) + CHAR(39) + ' WITH NORECOVERY'

	set @filepath = (select physical_device_name
		from msdb..backupmediafamily
		where media_set_id = 
		(select media_set_id 
		from msdb..backupset
		where type = 'I'
		and database_name = @dbname
		and backup_set_id = 
			(select max(backup_set_id)
				from msdb..backupset
				where type = 'I'
				and database_name = @dbname
				and backup_set_id >
					(select max(backup_set_id)
						from msdb..backupset
						where type = 'D'
						and database_name = @dbname))))	
	PRINT 'RESTORE DATABASE [' + LTRIM(RTRIM(@dbname)) + '] FROM DISK = N' + CHAR(39) + LTRIM(RTRIM(@filepath)) + CHAR(39)
END

-- Full, Differential, and TLogs
If @backuptype = 4
begin
	-- get the # of transaction logs after the differential
	set @trncount = (select count(*)
		from msdb..backupset
		where type = 'L'
		and database_name = @dbname
		and backup_set_id >
		(select max(backup_set_id)
			from msdb..backupset
			where type = 'I'
			and database_name = @dbname
			and backup_set_id >
				(select max(backup_set_id)
					from msdb..backupset
					where type = 'D'
					and database_name = @dbname)))


	set @filepath = (select physical_device_name
		from msdb..backupmediafamily
		where media_set_id = 
		(select media_set_id 
		from msdb..backupset
		where type = 'D'
		and database_name = @dbname
		and backup_set_id = 
			(select max(backup_set_id)
				from msdb..backupset
				where type = 'D'
				and database_name = @dbname)))
	
		PRINT 'RESTORE DATABASE [' + LTRIM(RTRIM(@dbname)) + '] FROM DISK = N' + CHAR(39) + LTRIM(RTRIM(@filepath)) + CHAR(39) + ' WITH NORECOVERY'

	set @filepath = (select physical_device_name
		from msdb..backupmediafamily
		where media_set_id = 
		(select media_set_id 
		from msdb..backupset
		where type = 'I'
		and database_name = @dbname
		and backup_set_id = 
			(select max(backup_set_id)
				from msdb..backupset
				where type = 'I'
				and database_name = @dbname
				and backup_set_id >
					(select max(backup_set_id)
						from msdb..backupset
						where type = 'D'
						and database_name = @dbname))))	
	PRINT 'RESTORE DATABASE [' + LTRIM(RTRIM(@dbname)) + '] FROM DISK = N' + CHAR(39) + LTRIM(RTRIM(@filepath)) + CHAR(39) + ' WITH NORECOVERY'

	set @loopno = 1

	DECLARE TLogCursor CURSOR FOR
	select backup_set_id
	from msdb..backupset
	where type = 'L'
	and database_name = @dbname
	and backup_set_id >
		(select max(backup_set_id)
			from msdb..backupset
			where type = 'D'
			and database_name = @dbname)
			and backup_set_id >
				(select max(backup_set_id)
					from msdb..backupset
					where type = 'I'
					and database_name = @dbname
					and backup_set_id >
						(select max(backup_set_id)
							from msdb..backupset
							where type = 'D'
							and database_name = @dbname))
	
	OPEN TLogCursor

	FETCH NEXT FROM TLogCursor INTO @trnid

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @loopno = @trncount 
		BEGIN
			set @mediaset = (select media_set_id
				from msdb..backupset
				where backup_set_id = @trnid)
			set @filepath = (select physical_device_name
				from msdb..backupmediafamily
				where media_set_id = @mediaset)

			PRINT 'RESTORE LOG [' + LTRIM(RTRIM(@dbname)) + '] FROM DISK = N' + CHAR(39) + LTRIM(RTRIM(@filepath)) + CHAR(39) 			
		END

		IF @loopno <> @trncount	
		BEGIN
			set @mediaset = (select media_set_id
				from msdb..backupset
				where backup_set_id = @trnid)
			set @filepath = (select physical_device_name
				from msdb..backupmediafamily
				where media_set_id = @mediaset)

			PRINT 'RESTORE LOG [' + LTRIM(RTRIM(@dbname)) + '] FROM DISK = N' + CHAR(39) + LTRIM(RTRIM(@filepath)) + CHAR(39) + ' WITH NORECOVERY' 			
		END

		SET @loopno = @loopno + 1
		FETCH NEXT FROM TLogCursor INTO @trnid
	END
	
	CLOSE TLogCursor
	DEALLOCATE TLogCursor
end
go
