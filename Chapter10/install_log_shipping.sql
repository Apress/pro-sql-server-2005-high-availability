--
-- Script Name: install_log_shipping.sql
-- Purpose: Create the objects used by custom log shipping
-- Author: Allan Hirt 
-- Website: http://www.sqlha.com
-- E-mail: allan@sqlha.com
-- Version: 1.0, 12/10/08
--

--
-- Drop Objects If They Exist
--
if exists (select * from dbo.sysobjects where id = object_id(N'[FK_log_shipping_files_to_restore_log_shipping_plans]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [log_shipping_files_to_restore] DROP CONSTRAINT FK_log_shipping_files_to_restore_log_shipping_plans
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[FK_log_shipping_primary_file_history_log_shipping_plans]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [log_shipping_primary_file_history] DROP CONSTRAINT FK_log_shipping_primary_file_history_log_shipping_plans
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[FK_log_shipping_secondaries_log_shipping_plans]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [log_shipping_secondaries] DROP CONSTRAINT FK_log_shipping_secondaries_log_shipping_plans
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[FK_log_shipping_primary_file_history_log_shipping_secondaries]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [log_shipping_primary_file_history] DROP CONSTRAINT FK_log_shipping_primary_file_history_log_shipping_secondaries
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[log_shipping_files_to_restore]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [log_shipping_files_to_restore]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[log_shipping_plans]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [log_shipping_plans]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[log_shipping_primary_file_history]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [log_shipping_primary_file_history]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[log_shipping_secondaries]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [log_shipping_secondaries]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[ls_add_secondary]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [ls_add_secondary]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[ls_create_plan]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [ls_create_plan]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[ls_list_plans]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [ls_list_plans]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[ls_list_secondaries]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [ls_list_secondaries]
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[ls_restore_tlog]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [ls_restore_tlog]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[ls_primary_report]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [ls_secondary_report]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[ls_secondary_report]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [ls_primary_report]
GO

--
-- Create the tables
--
CREATE TABLE [log_shipping_files_to_restore] (
	[ls_restore_history_id] [int] IDENTITY (1, 1) NOT NULL ,
	[ls_plan_id] [int] NOT NULL ,
	[ls_secondary_id] [int] NOT NULL ,
	[db_to_restore] [sysname] NOT NULL ,
	[tlog_file] [varchar] (255) NOT NULL ,
	[tlog_modified_dt] [datetime] NOT NULL ,
	[tlog_restored] [int] NOT NULL ,
	[tlog_restore_start] [datetime] NULL ,
	[tlog_restore_end] [datetime] NULL ,
	[tlog_restore_error] [int] NULL 
) ON [PRIMARY]
GO

CREATE TABLE [log_shipping_plans] (
	[ls_plan_id] [int] IDENTITY (1, 1) NOT NULL ,
	[primary_instance_name] [sysname] NOT NULL ,
	[primary_db_name] [sysname] NOT NULL ,
	[tlog_backup_dir] [varchar] (200) NOT NULL ,
	[get_backups_last_run] datetime NULL
) ON [PRIMARY]
GO

CREATE TABLE [log_shipping_primary_file_history] (
	[ls_file_history_id] [int] IDENTITY (1, 1) NOT NULL ,
	[ls_plan_id] [int] NOT NULL ,
	[ls_secondary_id] [int] NOT NULL ,
	[tlog_file] [varchar] (255) NOT NULL ,
	[tlog_copied] [bit] NULL ,
	[tlog_copy_start] [datetime] NULL ,
	[tlog_copy_end] [datetime] NULL 
) ON [PRIMARY]
GO

CREATE TABLE [log_shipping_secondaries] (
	[ls_secondary_id] [int] IDENTITY (1, 1) NOT NULL ,
	[ls_plan_id] [int] NOT NULL ,
	[secondary_instance_name] [sysname] NOT NULL ,
	[copy_share] [varchar] (200) NOT NULL ,
	[secondary_restore_dir] [varchar] (200) NOT NULL ,
	[secondary_db_name] [sysname] NOT NULL 
) ON [PRIMARY]
GO

ALTER TABLE [log_shipping_files_to_restore] ADD 
	CONSTRAINT [PK_log_shipping_files_to_restore] PRIMARY KEY  CLUSTERED 
	(
		[ls_restore_history_id]
	)  ON [PRIMARY] 
GO

ALTER TABLE [log_shipping_plans] ADD 
	CONSTRAINT [PK_log_shipping_plans] PRIMARY KEY  CLUSTERED 
	(
		[ls_plan_id]
	)  ON [PRIMARY] 
GO

ALTER TABLE [log_shipping_primary_file_history] ADD 
	CONSTRAINT [PK_log_shipping_primary_file_history] PRIMARY KEY  CLUSTERED 
	(
		[ls_file_history_id]
	)  ON [PRIMARY] 
GO

ALTER TABLE [log_shipping_secondaries] ADD 
	CONSTRAINT [PK_log_shipping_secondaries] PRIMARY KEY  CLUSTERED 
	(
		[ls_secondary_id]
	)  ON [PRIMARY] 
GO

ALTER TABLE [log_shipping_files_to_restore] ADD 
	CONSTRAINT [FK_log_shipping_files_to_restore_log_shipping_plans] FOREIGN KEY 
	(
		[ls_plan_id]
	) REFERENCES [log_shipping_plans] (
		[ls_plan_id]
	)
GO

ALTER TABLE [log_shipping_primary_file_history] ADD 
	CONSTRAINT [FK_log_shipping_primary_file_history_log_shipping_plans] FOREIGN KEY 
	(
		[ls_plan_id]
	) REFERENCES [log_shipping_plans] (
		[ls_plan_id]
	),
	CONSTRAINT [FK_log_shipping_primary_file_history_log_shipping_secondaries] FOREIGN KEY 
	(
		[ls_secondary_id]
	) REFERENCES [log_shipping_secondaries] (
		[ls_secondary_id]
	)
GO

ALTER TABLE [log_shipping_secondaries] ADD 
	CONSTRAINT [FK_log_shipping_secondaries_log_shipping_plans] FOREIGN KEY 
	(
		[ls_plan_id]
	) REFERENCES [log_shipping_plans] (
		[ls_plan_id]
	)
GO


--
-- Create the stored procedures
--
CREATE PROCEDURE [ls_add_secondary]
	@ls_plan_id int,
	@secondary_ins_name sysname,
	@secondary_db_name sysname,
	@copy_share varchar(200),
	@secondary_restore_dir varchar(200)
AS
--
-- Procedure Name: ls_add_secondary
-- Purpose: Add a secondary to an existing log shipping plan
-- Author: Allan Hirt 
-- Website: http://www.sqlha.com
-- E-mail: allan@sqlha.com
-- Version: 1.0, 4/4/08
--
-- @ls_plan_id - this is the Plan Id associated with the log shipping plan
-- @secondary_ins_name - This is the name of the first or only SQL Server instance containing the secondary database
-- @secondary_db_name - This is the name of the database that is the destination for log shipping
-- @copy_share - This is the share name where the files will be copied to
-- @secondary_restore_dir - This is the location where the secondary will restore the t-logs from (could be a local directory on the secondary or a share)
--
	INSERT INTO log_shipping_secondaries (ls_plan_id, secondary_instance_name, secondary_db_name, copy_share, secondary_restore_dir) VALUES (@ls_plan_id, @secondary_ins_name, @secondary_db_name, @copy_share, @secondary_restore_dir)		
GO

CREATE PROCEDURE [ls_create_plan]
	@primary_ins_name sysname,
	@primary_db_name sysname,
	@tlog_backup_dir varchar(255)
AS
--
-- Procedure Name: ls_create_plan
-- Purpose: Initialize the log shipping plan
-- Author: Allan Hirt 
-- Website: http://www.sqlha.com
-- E-mail: allan@sqlha.com
-- Version: 1.0, 4/4/08
--
-- @primary_ins_name - This is the name of the SQL Server instance containing the primary database
-- @primary_db_name - This is the name of the database that is the source for log shipping
-- @primary_copy_dir - This is the name of the directory on the primary that contains the t-log backups.
-- 
	INSERT INTO log_shipping_plans (primary_instance_name, primary_db_name, tlog_backup_dir) VALUES (@primary_ins_name, @primary_db_name, @tlog_backup_dir)
GO

CREATE PROCEDURE [ls_list_plans]
	@db_name sysname = NULL
AS
--
-- Procedure Name: ls_list_plans
-- Purpose: Lists the configured log shipping plans
-- Author: Allan Hirt 
-- Website: http://www.sqlha.com
-- E-mail: allan@sqlha.com
-- Version: 1.0, 4/11/08
--
-- @db_name - If specified, this will return the ID for plans associated with that database.
-- If @db_name is not specified, it will return all IDs

IF @db_name IS NOT NULL
BEGIN
	SELECT lsp.ls_plan_id as 'Plan ID', lsp.primary_instance_name as 'Primary Instance', lsp.primary_db_name as 'Source Database', tlog_backup_dir as 'Backup Directory'
	FROM log_shipping_plans lsp
	WHERE primary_db_name = @db_name
END

IF @db_name IS NULL
BEGIN
	SELECT lsp.ls_plan_id as 'Plan ID', lsp.primary_instance_name as 'Primary Instance', lsp.primary_db_name as 'Source Database', tlog_backup_dir as 'Backup Directory'
	FROM log_shipping_plans lsp
END
GO

CREATE PROCEDURE [ls_list_secondaries]
	@plan_id int = NULL
AS
--
-- Procedure Name: ls_list_secondaries
-- Purpose: Lists the configured secondaries
-- Author: Allan Hirt 
-- Website: http://www.sqlha.com
-- E-mail: allan@sqlha.com
-- Version: 1.0, 4/11/08
--
-- @plan_id - If specified, this will return the ID for plans associated with that database.
-- If @plan_id is not specified, it will return all IDs

IF @plan_id IS NOT NULL
BEGIN
	SELECT lss.ls_plan_id AS 'Plan ID', lss.ls_secondary_id as 'Secondary ID', lss.secondary_instance_name AS 'Secondary Instance', lss.secondary_db_name AS 'Standby Database', lss.copy_share as 'Copy Share', lss.secondary_restore_dir as 'Restore Directory'
	FROM log_shipping_secondaries lss
	WHERE lss.ls_plan_id = @plan_id
END

IF @plan_id IS NULL
BEGIN
	SELECT lss.ls_plan_id AS 'Plan ID', lss.ls_secondary_id as 'Secondary ID', lss.secondary_instance_name AS 'Secondary Instance', lss.secondary_db_name AS 'Standby Database', lss.copy_share as 'Copy Share', lss.secondary_restore_dir as 'Restore Directory'
	FROM log_shipping_secondaries lss
END
GO

CREATE PROCEDURE [ls_primary_report]
	@proc_db_name sysname,
	@db_name sysname = NULL
AS
--
-- Procedure Name: ls_primary_report
-- Purpose: Reports the status of files copied
-- Author: Allan Hirt 
-- Website: http://www.sqlha.com
-- E-mail: allan@sqlha.com
-- Version 1.0, 12/10/08
--
DECLARE @sql_txt varchar(8000)

SET @sql_txt = 'SELECT  fh.ls_plan_id as "Plan ID", fh.ls_secondary_id AS "Secondary ID", lp.primary_instance_name as "Primary", ls.secondary_instance_name as "Secondary", lp.primary_db_name as "Primary Database", fh.tlog_file as "T-Log File", CASE tlog_Copied WHEN 0 THEN ' + CHAR(39) + 'No' + CHAR(39) + ' WHEN 1 THEN ' + CHAR(39) + 'Yes' + CHAR(39)+ ' END AS "Restored?", fh.tlog_copy_start as "Copy Start", fh.tlog_copy_end as "Copy End" ' 
SET @sql_txt = @sql_txt + ' FROM ' + @proc_db_name + '..log_shipping_primary_file_history fh, ' + @proc_db_name + '..log_shipping_plans lp, ' + @proc_db_name + '..log_shipping_secondaries ls '
SET @sql_txt = @sql_txt + ' WHERE fh.ls_plan_id = lp.ls_plan_id '
SET @sql_txt = @sql_txt + ' AND fh.ls_secondary_id = ls.ls_secondary_id '

IF @db_name IS NOT NULL
BEGIN
	SET @sql_txt = @sql_txt + ' AND ls.secondary_db_name = ' + CHAR(39) + @db_name + CHAR(39)
END

PRINT @sql_txt
EXEC(@sql_txt)
GO

CREATE PROCEDURE [ls_restore_tlog]
	@proc_db_name sysname,
	@ls_plan_id int,
	@ls_secondary_id int,
	@recovery_mode bit,
	@keep_replication bit,
	@recover bit
AS
--
-- Procedure Name: ls_restore_tlog
-- Purpose: Restores the transaction log as part of custom log shipping
-- Author: Allan Hirt 
-- Website: http://www.sqlha.com
-- E-mail: allan@sqlha.com
-- Version: 1.0, 2/21/08
-- Version 2.0, 12/10/08 - Bug fixes
--
-- @ls_plan_id - this is the Plan Id associated with the log shipping plan
-- @ls_secondary_id - This is the id of the secondary associated with the plan
--
-- @recovery_mode values
-- 0 = NORECOVERY
-- 1 = WITH STANDBY
--
-- @keep_replication values
-- 0 = NO
-- 1 = YES
--
-- @recover values
-- 0 = NO
-- 1 = YES
--
DECLARE @restore_to_db varchar(50)
DECLARE @file_to_restore varchar(255)
DECLARE @file_id int
DECLARE @sql_txt varchar(8000)
DECLARE @start_restore datetime
DECLARE @end_restore datetime
DECLARE @err int
DECLARE @value int


DECLARE restore_cursor cursor
FOR 
	SELECT ls_restore_history_id, tlog_file, db_to_restore
	FROM log_shipping_files_to_restore
	WHERE ls_plan_id = @ls_plan_id
	AND ls_secondary_id = @ls_secondary_id
	AND tlog_restored = 0
	ORDER BY tlog_modified_dt asc

OPEN restore_cursor

FETCH NEXT FROM restore_cursor INTO @file_id, @file_to_restore, @restore_to_db

WHILE @@fetch_status = 0
begin
	-- Build RESTORE statement
	SET @sql_txt = 'RESTORE LOG ' + @restore_to_db
	SET @sql_txt = @sql_txt + ' FROM DISK = ' + CHAR(39) + @file_to_restore + CHAR(39)
	IF @recovery_mode = 0
	BEGIN
		SET @sql_txt = @sql_txt + ' WITH NORECOVERY'
	END
	IF @recovery_mode = 1
	BEGIN
		SET @sql_txt = @sql_txt + ' WITH STANDBY'
	END
	IF @keep_replication = 1
	BEGIN
		SET @sql_txt = @sql_txt + ', KEEP_REPLICATION'
	END

	SET @start_restore = GETDATE()
	
	EXEC(@sql_txt)

	SET @end_restore = GETDATE()

	SET @err = @@error
	
	SET @sql_txt = 'UPDATE ' + @proc_db_name + '..log_shipping_files_to_restore set tlog_restore_start = ' + CHAR(39) + RTRIM(CAST(@start_restore AS varchar(255))) + CHAR(39) + ' where ls_restore_history_id = ' + CAST(@file_id as varchar(10))

	EXEC(@sql_txt)

	SET @sql_txt = 'UPDATE ' + @proc_db_name + '..log_shipping_files_to_restore set tlog_restore_end = ' + CHAR(39) + RTRIM(CAST(@end_restore AS varchar(255))) + CHAR(39) + ' where ls_restore_history_id =' + RTRIM(CAST(@file_id as varchar(10)))
	EXEC(@sql_txt)

	IF @err = 0
	BEGIN
		SET @sql_txt = 'UPDATE ' + @proc_db_name + '..log_shipping_files_to_restore set tlog_restored = 1 where ls_restore_history_id = ' + CAST(@file_id as varchar(10))
		EXEC(@sql_txt)

		SET @sql_txt = 'UPDATE ' + @proc_db_name + '..log_shipping_files_to_restore set tlog_restore_error = ' + RTRIM(CAST(@err as varchar(10))) + ' where ls_restore_history_id = ' + RTRIM(CAST(@file_id as varchar(10)))
		EXEC(@sql_txt)
	END

	IF @err <> 0
	BEGIN
		SET @sql_txt = 'UPDATE ' + @proc_db_name + '..log_shipping_files_to_restore set tlog_restored = 2 where ls_restore_history_id = ' + RTRIM(CAST(@file_id as varchar(10)))
		EXEC(@sql_txt)
 
		SET @sql_txt = 'UPDATE ' +@proc_db_name + '..log_shipping_files_to_restore set tlog_restore_error = ' + RTRIM(CAST(@err as varchar(10))) + ' where ls_restore_history_id = ' + RTRIM(CAST(@file_id as varchar(10)))
		EXEC(@sql_txt)
	END

	FETCH NEXT FROM restore_cursor into @file_id, @file_to_restore, @restore_to_db
end
close restore_cursor
deallocate restore_cursor

IF @recover = 1
BEGIN
	RESTORE DATABASE @restore_to_db WITH RECOVERY
END
GO

CREATE PROCEDURE [ls_secondary_report]
	@proc_db_name sysname,
	@db_name sysname = NULL
AS
--
-- Procedure Name: ls_secondary_report
-- Purpose: Reports the status of transaction log backup files restored
-- Author: Allan Hirt 
-- Website: http://www.sqlha.com
-- E-mail: allan@sqlha.com
-- Version 1.0, 12/10/08
--
DECLARE @sql_txt varchar(8000)

SET @sql_txt = 'SELECT  ftr.ls_plan_id as "Plan ID", ftr.ls_secondary_id AS "Secondary ID", lp.primary_instance_name as "Primary", ls.secondary_instance_name as "Secondary", ftr.db_to_restore as "Database", ftr.tlog_file as "T-Log File", CASE tlog_restored WHEN 0 THEN ' + CHAR(39) + 'No' + CHAR(39) + ' WHEN 1 THEN ' + CHAR(39) + 'Yes' + CHAR(39)+ ' END AS "Restored?", ftr.tlog_restore_start as "Restore Start", ftr.tlog_restore_end as "Restore End" ' 
SET @sql_txt = @sql_txt + ' FROM ' + @proc_db_name + '..log_shipping_files_to_restore ftr, ' + @proc_db_name + '..log_shipping_plans lp, ' + @proc_db_name + '..log_shipping_secondaries ls '
SET @sql_txt = @sql_txt + ' WHERE ftr.ls_plan_id = lp.ls_plan_id '
SET @sql_txt = @sql_txt + ' AND ftr.ls_secondary_id = ls.ls_secondary_id '

IF @db_name IS NOT NULL
BEGIN
	SET @sql_txt = @sql_txt + ' AND ls.secondary_db_name = ' + CHAR(39) + @db_name + CHAR(39)
END

EXEC(@sql_txt)
GO

-- 
-- Add lsadmin login
--
if not exists (select * from master.dbo.syslogins where loginname = N'lsadmin')
BEGIN
	declare @logindb nvarchar(132), @loginlang nvarchar(132) select @logindb = N'master', @loginlang = N'us_english'
	if @logindb is null or not exists (select * from master.dbo.sysdatabases where name = @logindb)
		select @logindb = N'master'
	if @loginlang is null or (not exists (select * from master.dbo.syslanguages where name = @loginlang) and @loginlang <> N'us_english')
		select @loginlang = @@language
	exec sp_addlogin 
		@loginame = N'lsadmin', 
		@passwd = 'p@ssword1', 
		@defdb = @logindb, 
		@deflanguage = @loginlang
END
GO

if not exists (select * from dbo.sysusers where name = N'lsadmin')
	EXEC sp_grantdbaccess N'lsadmin', N'lsadmin'
GO

exec sp_addrolemember N'db_datareader', N'lsadmin'
GO

exec sp_addrolemember N'db_datawriter', N'lsadmin'
GO
 
GRANT  SELECT ,  UPDATE ,  INSERT ,  DELETE  ON [log_shipping_plans]  TO [lsadmin]
GO

GRANT  SELECT ,  UPDATE ,  INSERT ,  DELETE  ON [log_shipping_secondaries]  TO [lsadmin]
GO

GRANT  SELECT ,  UPDATE ,  INSERT ,  DELETE  ON [log_shipping_files_to_restore]  TO [lsadmin]
GO

GRANT  SELECT ,  UPDATE ,  INSERT ,  DELETE  ON [log_shipping_primary_file_history]  TO [lsadmin]
GO
