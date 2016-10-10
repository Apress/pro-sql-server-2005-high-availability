'
' Name: check_for_pending_reboots.vbs
' Author: Allan Hirt (allan.hirt@sqlha.com)
' Date: 3-19-08
' Version: 1.0
' Purpose: Check to see if a system has a pending reboot and to document which files are causing it.
'

Const ForAppending = 8
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objLogFile = _
     objFSO.OpenTextFile("c:\pending_reboots.txt", _
         ForAppending, True)


Const HKEY_LOCAL_MACHINE = &H80000002
Const REG_SZ = 1
Const REG_EXPAND_SZ = 2
Const REG_BINARY = 3
Const REG_DWORD = 4
Const REG_MULTI_SZ = 7

pending_reboot = 0
 
strComputer = "."
 
Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & _ 
    strComputer & "\root\default:StdRegProv")
 
strKeyPath = "SYSTEM\CurrentControlSet\Control\Session Manager"
 
oReg.EnumValues HKEY_LOCAL_MACHINE, strKeyPath, _
    arrValueNames, arrValueTypes
 
For i=0 To UBound(arrValueNames)
    If arrValueNames(i) = "PendingFileRenameOperations" Then
	pending_reboot = 1
    End If
Next

If pending_reboot = 0 Then
	objLogFile.Write "No pending reboots."
End If

If pending_reboot = 1 Then
	strValueName = "PendingFileRenameOperations"
	oReg.GetMultiStringValue HKEY_LOCAL_MACHINE,strKeyPath, _
    		strValueName,arrValues
	
	objLogFile.Write "The following files require the machine to be rebooted:"
	objLogFile.Writeline
 
	For Each strValue In arrValues
    		objLogFile.Write strValue
		objLogFile.Writeline
	Next
End If

objLogFile.Close