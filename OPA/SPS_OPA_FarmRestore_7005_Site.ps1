
$ErrorActionPreference = "Stop"

Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

function RestoreSPFarm
{
	param([string]$BackupLocation, [string]$WebApplicationName)
	# Restore the web application	
	Restore-SPFarm -Directory $BackupLocation -RestoreMethod Overwrite -Item  "Farm\Microsoft SharePoint Foundation Web Application\$WebApplicationName"
}

# I want to backup a web application on port 7005 which was named - SharePoint - 7005
$backupLocation = "\\sp2010riyaz\OPA_Backup"
$WebApplicationName = "SharePoint - 7005"

RestoreSPFarm -BackupLocation $backupLocation -WebApplicationName $WebApplicationName