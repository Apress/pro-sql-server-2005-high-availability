'
' Name: ls_restore_file.vbs
' Author: Allan Hirt
'
' Purpose: To populate the table to tell SQL Server which t-log files to restore
'	   This is used with the log shipping functionality from the book 
'	   Pro SQL Server 2005 High Availability (Apress) by Allan Hirt.
'
' Script Version History: 
' 1.0 (January 7, 2008) - Initial Version 
' 2.0 (December 10, 2008) - Account for schema updates
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
' set source_sql = "FENDERBASSV"
'
source_sql = "LS-MIRROR-3\WITNESS"

'
' Set the name of the database that has the log shipping admin tables
' Example:
' set source_ls_db = "DBADB"
'
source_ls_db = "DBADB"

'
' Set the name of the user on the primary which has rights to write to the database that has the log shipping tables
' Example:
' set source_ls_login = "lsadmin"
'
source_ls_login = "lsadmin"

'
' Set the password for the log shipping user connecting to the primary
' Example:
' set source_ls_login = "password"
'
source_ls_pwd = "p@ssword1"

'
' Configure the connection string to the source SQL Server instance
'
SourceConnStr = "Provider=SQLOLEDB;Server=" & source_sql &";database=" & source_ls_db & ";uid=" & source_ls_login & ";pwd=" & source_ls_pwd & ";" 

set SourceConnection = CreateObject("ADODB.Connection")
set SourceData = CreateObject("ADODB.Recordset")
SourceConnection.Open = SourceConnStr

strComputer = "."
Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")

SQLstr = "SELECT ls_plan_id FROM " & source_ls_db & "..log_shipping_plans WHERE ls_plan_id = " & ls_plan_id

Set LSPlanSQL = CreateObject("ADODB.Command")
Set LSPlanRS = CreateObject("ADODB.Recordset")
LSPlanSQL.ActiveConnection = SourceConnStr
LSPlanSQL.CommandText = SQLstr
Set LSPlanRS = LSPlanSQL.Execute

Set LSSecondariesSQL = CreateObject("ADODB.Command")
Set LSSecondariesRS = CreateObject("ADODB.Recordset")
LSSecondariesSQL.ActiveConnection = SourceConnStr

Set objFSO= CreateObject("Scripting.FileSystemObject")

While Not LSPlanRs.EOF
	ls_plan_id = LSPlanRs.Fields.Item("ls_plan_id").Value

	SQLstr = "SELECT ls_secondary_id, secondary_db_name, secondary_restore_dir FROM " & source_ls_db & "..log_shipping_secondaries WHERE ls_plan_id = " & ls_plan_id

	LSSecondariesSQL.CommandText = SQLstr
	Set LSSecondariesRS = LSSecondariesSQL.Execute

	While Not LSSecondariesRS.EOF
		ls_secondary_id = TRIM(LSSecondariesRS.Fields.Item("ls_secondary_id").Value)
		
		restore_dir = TRIM(LSSecondariesRS.Fields.Item("secondary_restore_dir").Value)

		db_to_restore =  TRIM(LSSecondariesRS.Fields.Item("secondary_db_name").Value)

		If RIGHT(restore_dir, 1) <> "\" THEN
			restore_dir_slash = restore_dir & "\"
		END IF	

		If RIGHT(restore_dir, 1) = "\" THEN
			restore_dir_slash = restore_dir
		END IF

		IF RIGHT(restore_dir, 1) = "\" THEN
			restore_dir_no_slash = MID(restore_dir,1,LEN(restore_dir)-1)		
		END IF

		IF RIGHT (restore_dir, 1) <> "\" THEN
			restore_dir_no_slash = restore_dir
		END IF


		Set FileList = objWMIService.ExecQuery("ASSOCIATORS OF {Win32_Directory.Name=" & CHR(39) & restore_dir_no_slash & CHR(39) & "} Where " & "ResultClass = CIM_DataFile" )

		If FileList.Count > 0 Then
			For Each objFile in FileList		
				If objFile.Extension = "log" Then
	      				logfile = TRIM(objFile.FileName) & "." & objFile.Extension
					msgbox logfile

					full_log_file = restore_dir_slash & logfile
					
					Set ReadLogFile = objFSO.OpenTextFile(full_log_file,1,false)

					While not ReadLogFile.atEndOfStream 
						fileinfo = TRIM(ReadLogFile.readline) 
						
						' Find the comma
						delimpos = InStr(fileinfo,",")

						RestoreFile = restore_dir_slash & MID(fileinfo,1,delimpos-1)

						filemoddate = MID(fileinfo,delimpos+1,LEN(fileinfo))

						yy = mid(filemoddate,1,4)
			    			mo = mid(filemoddate,5,2)
			    			dy = mid(filemoddate,7,2)
				    		hr = mid(filemoddate,9,2)
						min = mid(filemoddate,11,2)
						sec = mid(filemoddate,13,2)

						moddate = yy & "-" & mo & "-" & dy & " " & hr & ":" & min & ":" & sec

						SQLstr = "INSERT INTO " & source_ls_db & "..log_shipping_files_to_restore (ls_plan_id, ls_secondary_id, db_to_restore, tlog_file, tlog_modified_dt, tlog_restored) VALUES (" & ls_plan_id & "," & ls_secondary_id & "," & CHR(39) & db_to_restore & CHR(39) & "," & CHR(39) & RestoreFile & CHR(39) & "," & CHR(39) & moddate & CHR(39) &",0)"
						SourceData.Open SQLstr, SourceConnection					
					Wend 
					
					ReadLogFile.close 

					objFile.Delete full_log_file
				End If
			Next
		End If

		LSSecondariesRS.MoveNext
	Wend

	LSPlanRS.MoveNext
Wend
