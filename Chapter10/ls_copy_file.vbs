'
' Name: ls_copy_file.vbs
' Author: Allan Hirt
'
' Purpose: To copy the t-log files involved with log shipping to the appropriate location.
'	   This is used with the log shipping functionality from the book 
'	   Pro SQL Server 2005 High Availability (Apress) by Allan Hirt.
'
' Script Version History: 
' 1.0 (January 4, 2008) - Initial Version using all variables and no DB configuration parameters from the DB
' 2.0 (January 5, 2008) - Added recursive functionality to parse all plans on a given instance
' 2.1 (January 6, 2008) - Changed the _all script to run against only one database's log shipping plan
' 2.2 (January 6, 2008) - Added log file for parsing on secondary
' 2.3 (January 7, 2008) - Added configurable transaction log backup file extension
' 3.0 (December 10, 2008) - Fixed for schema changes
'

' 
' Set the log shipping plan to copy and move files
' This is the ls_plan_id value in the table log_shipping_plans
' A value of 0 will do all log shipping plans detected
' Example:
' ls_plan_id = 1
'
ls_plan_id = 1

'
' Set the name of the instance that has the primary DB
' Example:
' source_sql = "FENDERBASSV"
'
source_sql = "LS-MIRROR-1"

'
' Set the name of the database that has the log shipping admin tables
' Example:
' source_ls_db = "DBADB"
'
source_ls_db = "DBADB2"

'
' Set the name of the user on the primary which has rights to write to the database that has the log shipping tables
' Example:
' source_ls_login = "lsadmin"
'
source_ls_login = "lsadmin"

'
' Set the password for the log shipping user connecting to the primary
' Example:
' source_ls_login = "password"
'
source_ls_pwd = "p@ssword1"

'
' Set the extension of a transaction log file
' Example:
' tlogext = "trn"
'
tlogext = "trn"


'
' Configure the connection string to the source SQL Server instance
'
SourceConnStr = "Provider=SQLOLEDB;Server=" & source_sql &";database=" & source_ls_db & ";uid=" & source_ls_login & ";pwd=" & source_ls_pwd & ";" 

set SourceConnection = CreateObject("ADODB.Connection")
set SourceData = CreateObject("ADODB.Recordset")
SourceConnection.Open = SourceConnStr

strComputer = "."
Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")

If ls_plan_id <> 0 Then
	SQLstr = "SELECT tlog_backup_dir FROM " & source_ls_db & "..log_shipping_plans WHERE ls_plan_id = " & ls_plan_id
End If

If ls_plan_id = 0 Then
	SQLstr = "SELECT ls_plan_id, tlog_backup_dir FROM " & source_ls_db & "..log_shipping_plans"
End If

Set LSSecondariesSQL = CreateObject("ADODB.Command")
Set LSSecondariesRS = CreateObject("ADODB.Recordset")
LSSecondariesSQL.ActiveConnection = SourceConnStr

Set LSPlanSQL = CreateObject("ADODB.Command")
SET LSPlanRS = CreateObject("ADODB.Recordset")
LSPlanSQL.ActiveConnection = SourceConnStr
LSPlanSQL.CommandText = SQLstr
Set LSPlanRS = LSPlanSQL.Execute

Set objFSO= CreateObject("Scripting.FileSystemObject")

if ls_plan_id = 0 Then
	ls_plan_orig_val = 0
else
	ls_plan_orig_val = 1
end if

While Not LSPlanRS.EOF	
	If ls_plan_orig_val = 0 Then
		ls_plan_id = TRIM(LSPlanRS.Fields.Item("ls_plan_id").Value)
	End If

	source_dir = TRIM(LSPlanRS.Fields.Item("tlog_backup_dir").Value)

	If RIGHT(source_dir, 1) <> "\" THEN
		source_dir_slash = source_dir & "\"
	END IF	

	If RIGHT(source_dir, 1) = "\" THEN
		source_dir_slash = source_dir
	END IF

	IF RIGHT(source_dir, 1) = "\" THEN
		source_dir_no_slash = MID(source_dir,1,LEN(source_dir)-1)
	END IF

	IF RIGHT (source_dir, 1) <> "\" THEN
		source_dir_no_slash = source_dir
	END IF

	Set colDate = objWMIService.ExecQuery("Select * from Win32_LocalTime")

	For each objDatePart in colDate
		yy = objDatePart.Year
	    	mo = objDatePart.Month
	    	dy = objDatePart.Day
	    	hr = objDatePart.Hour
		min = objDatePart.Minute
		sec = objDatePart.Second
	Next

	temp_dir_no_slash = source_dir_slash & yy & mo & dy & hr & min & sec 
	temp_dir_slash = source_dir_slash & yy & mo & dy & hr & min & sec & "\"

	copied_dir_no_slash = source_dir_slash & "Copied"
	copied_dir_slash = source_dir_slash & "Copied\"

	Set FileList = objWMIService.ExecQuery("ASSOCIATORS OF {Win32_Directory.Name=" & CHR(39) & source_dir_no_slash & CHR(39) & "} Where " & "ResultClass = CIM_DataFile" )

	LogFileNm = "FilesCopied-" & yy & mo & dy & hr & min & sec & ".log"
	LogFileNmFull = copied_dir_slash & LogFileNm

	If FileList.Count > 0 Then
		If not objFSO.FolderExists(temp_dir_no_slash) Then
		   	objFSO.CreateFolder(temp_dir_no_slash)
		End If

		If not objFSO.FolderExists(copied_dir_no_slash) Then
			objFSO.CreateFolder(copied_dir_no_slash)
		End If
		Const ForReading = 1
		Const ForWriting = 2
		Const ForAppending = 8

		Set LogFileWrite = objFSO.OpenTextFile (LogFileNmFull, ForAppending, True)

		For Each objFile in FileList
			If objFile.Extension = tlogext Then		
				filenm = objFile.FileName & "." & TRIM(objFile.Extension)

				CurrentFile = source_dir_slash & filenm

				LogLine = filenm & "," & objFile.LastModified

				' Move the file to a temporary directory in the event another process comes along
				objFSO.MoveFile CurrentFile, temp_dir_slash

				' Write filename to log file
				LogFileWrite.WriteLine LogLine		
			End If
		Next

		LogFileWrite.Close

		Set FileList = objWMIService.ExecQuery("ASSOCIATORS OF {Win32_Directory.Name=" & CHR(39) & temp_dir_no_slash & CHR(39) & "} Where " & "ResultClass = CIM_DataFile" )

		If FileList.Count > 0 Then
			SQLstr = "SELECT ls_secondary_id, copy_share FROM " & source_ls_db & "..log_shipping_secondaries WHERE ls_plan_id = " & ls_plan_id
			LSSecondariesSQL.CommandText = SQLstr
			Set LSSecondariesRS = LSSecondariesSQL.Execute

			For Each objFile in FileList
				If objFile.Extension = tlogext Then		
					ls_secondary_id = LSSecondariesRS.Fields.Item("ls_secondary_id").Value

					move_dir = TRIM(LSSecondariesRS.Fields.Item("copy_share").Value)

					If RIGHT(move_dir, 1) <> "\" THEN
						move_dir_slash = move_dir & "\"
					END IF	

					If RIGHT(move_dir, 1) = "\" THEN
						move_dir_slash = move_dir
					END IF

					IF RIGHT(move_dir, 1) = "\" THEN
						move_dir_no_slash = MID(move_dir,1,LEN(move_dir)-1)		
					END IF

					IF RIGHT (move_dir, 1) <> "\" THEN
						move_dir_no_slash = move_dir
					END IF

					Set strtDate = objWMIService.ExecQuery("Select * from Win32_LocalTime")
		
					For each objDatePart in strtDate
						strt_yy = objDatePart.Year
    						strt_mo = objDatePart.Month
	    					strt_dy = objDatePart.Day
   						strt_hr = objDatePart.Hour
						strt_min = objDatePart.Minute
						strt_sec = objDatePart.Second
					Next

					strttime = strt_yy & "-" & strt_mo & "-" & strt_dy & " " & strt_hr & ":" & strt_min & ":" & strt_sec

					filenm = objFile.FileName & "." & TRIM(objFile.Extension)

					CurrentFile = temp_dir_slash & filenm
		
					' Copy the file to the place on the secondary where it will be restored from
					objFSO.CopyFile CurrentFile, move_dir_slash

					' Move the file so it won't be attempted to be copied again
					objFSO.MoveFile CurrentFile, copied_dir_slash


					Set endDate = objWMIService.ExecQuery("Select * from Win32_LocalTime")

					For each objDatePart in endDate
						end_yy = objDatePart.Year
		    				end_mo = objDatePart.Month
	    					end_dy = objDatePart.Day
	    					end_hr = objDatePart.Hour
						end_min = objDatePart.Minute
						end_sec = objDatePart.Second
					Next
		
					endtime = end_yy & "-" & end_mo & "-" & end_dy & " " & end_hr & ":" & end_min & ":" & end_sec	
	
					SQLstr = "INSERT INTO " & source_ls_db & "..log_shipping_primary_file_history (ls_plan_id, ls_secondary_id, tlog_file, tlog_copied, tlog_copy_start, tlog_copy_end) VALUES (" & ls_plan_id & "," & ls_secondary_id & "," & CHR(39) & filenm & CHR(39) & ",1," & CHR(39) & strttime & CHR(39) &"," & CHR(39) & endtime & CHR(39) & ")"
					SourceData.Open SQLstr, SourceConnection

				End If
			Next

			LSSecondariesRS.MoveNext
			LSSecondariesRS.Close
		End If

	End If	

	LSPlanRS.MoveNext
Wend

' Copy Log File 
objFSO.CopyFile LogFileNmFull, move_dir_slash	
		
SQLstr = "UPDATE " & source_ls_db & "..log_shipping_plans SET get_backups_last_run = GETDATE() WHERE ls_plan_id = " & ls_plan_id
SourceData.Open SQLstr, SourceConnection

objFSO.DeleteFolder(temp_dir_no_slash)