if exists (select * from dbo.sysobjects where id = object_id(N'[dba_backup]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dba_backup]
GO

CREATE PROCEDURE [dba_backup]
	@db_name varchar(30),
	@backup_dir varchar(255),
	@backup_type int
AS
--
-- Procedure Name: dba_backup
-- Purpose: Create a backup of a SQL Server database
-- Author: Allan Hirt
-- Version: 1.0, 3/08
--
-- @db_name - this is the name of the database to back up; encased in single quotes
-- @backup_dir - this is the directory where the database will be made; encased in single quotes
-- @backup_type - this is the type of backup that will be generated. Valid values:			
-- 1 = full backup
-- 2 = differential backup
-- 3 = transaction log backup
--
-- Example execution
-- exec dba_backup
--	@db_name = 'ConsolidateTo2005',
--	@backup_dir = 'C:\SQL Backups\ConsolidateTo2005'
--	@backup_type = 3
--
DECLARE @backup_exp char(4)
	,@backup_ext char(4)
	,@backup_start_time_str varchar(50)
	,@backup_type_desc varchar(55)
	,@base_filename varchar(255)
	,@bu_filename varchar(1024)
	,@can_backup bit
	,@filestamptime datetime
	,@return_code int
	,@sqlstmt varchar(1000)
	,@sqlver char(1)
	,@version sql_variant
	,@versionstr varchar(10)

SET @backup_dir = RTRIM(LTRIM(@backup_dir))
SET @db_name = RTRIM(LTRIM(@db_name))

If @backup_type = 1 
BEGIN
	SET @backup_type_desc = 'Full Database Backup'
	SET @backup_ext = '.bak'	
	SET @backup_exp = 'FULL'
END

If @backup_type = 2 
BEGIN
	SET @backup_type_desc = 'Differential Backup'
	SET @backup_ext = '.dif'	
	SET @backup_exp = 'DIFF'
END

If @backup_type = 3 
BEGIN
	SET @backup_type_desc = 'Transaction Log Backup'
	SET @backup_ext = '.trn'	
	SET @backup_exp = 'TLOG'
END

--
--Determine Filename for Operation
--
SET @filestamptime = GETDATE()

SET @backup_start_time_str = CONVERT(varchar(12),@filestamptime,12) + REPLACE(CONVERT(varchar(12),@filestamptime,8),':','')

SET @base_filename = @db_name

SET @base_filename = REPLACE(@@SERVERNAME,'\','_') + '_' + REPLACE(@db_name,'.','_') + '_' + @backup_exp + '_' + @backup_start_time_str 

SET @backup_dir = RTRIM(LTRIM(@backup_dir))
-- Ensure that \ is at the end of the directory name
IF RIGHT(@backup_dir, 1) <> '\'
BEGIN
	SET @backup_dir = @backup_dir + '\'
END

-- Create the full file name for the backup
SET @bu_filename = @backup_dir + @base_filename + @backup_ext

IF @backup_type = 1
BEGIN
	BACKUP DATABASE  @db_name
	TO DISK = @bu_filename
END

IF @backup_type = 2
BEGIN
	BACKUP DATABASE @db_name
	TO DISK = @bu_filename
	WITH DIFFERENTIAL
END

If @backup_type = 3 
BEGIN
	BACKUP LOG @db_name 
	TO DISK = @bu_filename 
END
GO
