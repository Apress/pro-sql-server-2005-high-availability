SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO


CREATE procedure dba_get_rowcounts
@db_name varchar(50)
AS
-- 
-- Name: dba_get_rowcounts
-- Author: Allan Hirt
-- Version: 1.0, 11/06
-- Purpose: To get the rowcounts for all tables in a particular database
-- This is a great way to validate databases after a migration or upgrade.
-- To do this, run this script prior to decomissioning the old database
-- and once the new database is up, run this against the new database.
-- Use a file compare tool (or Excel) to compare the output - they should both
-- be the same.
--
-- Variables
-- @db_name - this is the name of the database which you would like to get the rowcounts of each table
--
-- Example execution
-- exec dbwhereproclives..dba_get_rowcounts
--    @db_name = 'MyDB'

declare @sqlstmt1 varchar(255)
declare @sqlstmt2 varchar(2000)

set @db_name = RTRIM(LTRIM(@db_name))

set @sqlstmt1 = 'select [name] from ' + @db_name + '..sysobjects where type = ' + CHAR(39) + 'U' + CHAR(39) + ' order by [name] asc'
set @sqlstmt2 = 'declare @table_name varchar(50)'
set @sqlstmt2 = @sqlstmt2 + ' declare @sqlstmt varchar(500)'
set @sqlstmt2 = @sqlstmt2 + ' declare Table_Cursor cursor for ' + @sqlstmt1
set @sqlstmt2 = @sqlstmt2 + ' open table_cursor'
set @sqlstmt2 = @sqlstmt2 + ' fetch next from table_cursor into @table_name'
set @sqlstmt2 = @sqlstmt2 + ' while @@fetch_status = 0'
set @sqlstmt2 = @sqlstmt2 + ' BEGIN'
set @sqlstmt2 = @sqlstmt2 + ' set @sqlstmt = ' + CHAR(39) + 'SELECT COUNT(*) AS ' + CHAR(39) + ' + @table_name + ' + CHAR(39) + '_rowcount FROM ' + @db_name + '..' + CHAR(39) + ' + @table_name'
set @sqlstmt2 = @sqlstmt2 + ' exec (@sqlstmt)'
set @sqlstmt2 = @sqlstmt2 + ' fetch next from table_cursor into @table_name'
set @sqlstmt2 = @sqlstmt2 + ' END'
set @sqlstmt2 = @sqlstmt2 + ' close table_cursor'
set @sqlstmt2 = @sqlstmt2 + ' deallocate table_cursor'
exec (@sqlstmt2)

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
