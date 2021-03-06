'
' Name: backup_retention_older_folder.vbs
' Author: Allan Hirt
'
' Purpose: To automate retention policies for SQL Server backups
'	   This script will move all SQL backup files older than today to a  
'	   folder named Older and then will go through and delete all files
'	   older than RetentionDays
'	   This is an example from the book Pro SQL Server 2005 High Availability (Apress) 
'	   by Allan Hirt.
'
' Script Version History: 
' 1.0 (January 7, 2008) - Initial Version 
'

Const adVarChar = 200
Const adDateTime = 7
Const MaxCharacters = 1000

'
' RetentionDays is the maximum number of days a backup file should 
' remain on the drive
' Example: 
' RetentionDays = 14
'
RetentionDays = 14

'
' topdir is the top level folder for all backups
' Example:
' topdir = "C:\Backups"
'
topdir = "C:\SQL Backups"

'
' diffext is the extension of the differential backups
' Example:
' diffext = "Diff"
'
diffext = "dif"

'
' fullext is the extension of the full backups
' Example:
' diffloc = "bak"
'
fullext = "bak"


'
' tlogext is the extension of the differential backups
' Example:
' tlogext = "trn"
'
'
tlogext = "trn"

'
' strcomputer is the name of the computer where the script will be executed. Putting a period (.) will
' tell the script to run it on the local computer.
' Unless you have a need, leave this as the default value.
' Example:
' strcomputer = "."
'
strcomputer = "."

Set objFSO= CreateObject("Scripting.FileSystemObject")

Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")

Set colSubfolders = objWMIService.ExecQuery ("Associators of {Win32_Directory.Name='" & topdir & "'} " & "Where AssocClass = Win32_Subdirectory " & "ResultRole = PartComponent")

Set colDate = objWMIService.ExecQuery("Select * from Win32_LocalTime")

For each objDatePart in colDate
	yy = objDatePart.Year
    	mo = objDatePart.Month
    	dy = objDatePart.Day
    	hr = objDatePart.Hour
	min = objDatePart.Minute
	sec = objDatePart.Second
Next

TodayDate =  mo & "/" & dy & "/" & yy 
NowTime = hr & ":" & min & ":" & sec
CurrentTimeValue = TodayDate & " " & NowTime

strComputer = "."
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")

strFolderName = topdir

dim subfolders(500)
dim foldertodel(500,500)
dim totdirs
dim subdirval

subdirval = 0

Set colSubfolders = objWMIService.ExecQuery ("Associators of {Win32_Directory.Name='" & strFolderName & "'} " & "Where AssocClass = Win32_Subdirectory " & "ResultRole = PartComponent")

subfolders(subdirval) = strFolderName

For Each objFolder in colSubfolders
    GetSubFolders strFolderName
Next

totdirs = subdirval + 1

Set filedate = CreateObject("WbemScripting.SWbemDateTime")

'
' Move and Delete Older Files
'
For z = 1 to totdirs
	Set FileList = objWMIService.ExecQuery("ASSOCIATORS OF {Win32_Directory.Name=" & CHR(39) & subfolders(z-1) & CHR(39) & "} Where " & "ResultClass = CIM_DataFile" )

	For Each objFile In FileList
		' First ensure that only SQL backup files will be examined and possibly deleted	
		If (objFile.Extension = fullext) or (objFile.Extension = diffext) or (objFile.Extension = tlogext) Then	
   			filedate.Value = objFile.LastModified
			filecreationhours = filedate.Hours
			If filecreationhours < 10 Then
				filecreationhours = "0" & filecreationhours
			End If
	
			filecreationminutes = filedate.Minutes
			If filecreationminutes < 10 Then
				filecreationminutes = "0" & filecreationminutes
			End If

			filecreationseconds = filedate.Seconds
			If filecreationseconds < 10 Then
				filecreationseconds = "0" & filecreationseconds
			End If

			filecreationdate = filedate.Month & "/" & filedate.Day & "/" & filedate.Year & " " & filecreationHours & ":" & filecreationMinutes & ":" & filecreationSeconds

			fullfolderpath = subfolders(z-1) & "\" & "Older"

			' Date difference in days
			FileDateDifferential = DateDiff("d", filecreationdate, CurrentTimeValue)

			If FileDateDifferential > RetentionDays Then
				objFSO.DeleteFile objFile.Name
			End If

			If (FileDateDifferential >= 1) and (FileDateDifferential <= Retentiondays) Then
				filetomove = subfolders(z-1) & "\" & objFile.Filename & "." & objFile.Extension
				Set FileProp = objFSO.GetFile(filetomove)

				filefolder = objFile.Path

				filefolderpos = Instr(UCase(filefolder),UCase("Older"))

				If filefolderpos = 0 Then
					If Not objFso.FolderExists(subfolders(z-1) & "\Older") Then
						objFSO.CreateFolder(subfolders(z-1) & "\Older")
					End If

					objFSO.MoveFile filetomove, fullfolderpath & "\"
				End If

				If filefolderpos >= 1 Then
					objFSO.MoveFile filetomove, subfolders(z-1) & "\"
				End If
			End If
		End If
	Next
Next

Sub GetSubFolders(strFolderName)
    Set colSubfolders2 = objWMIService.ExecQuery ("Associators of {Win32_Directory.Name='" & strFolderName & "'} " & "Where AssocClass = Win32_Subdirectory " & "ResultRole = PartComponent")

    For Each objFolder2 in colSubfolders2
        strFolderName = objFolder2.Name
	StoreInArray strFolderName
        GetSubFolders strFolderName
    Next
End Sub

Sub StoreInArray(strFolderName)
	subdirval = subdirval + 1
	subfolders(subdirval) = strFolderName
End Sub

