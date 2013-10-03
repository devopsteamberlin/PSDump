
$ErrorActionPreference = "Stop"

Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

function BackupSPFarm
{
	param([string]$BackupLocation, [string]$WebApplicationName)
	# Must have both Farm account and the SQL Service account having read&Write access to the Share.
	# You'll also need to verify that the Farm account is a DBOwner on all your databases (You may need to do this manually from SQL).
	Backup-SPFarm -Directory $BackupLocation -BackupMethod Full -Item "Farm\Microsoft SharePoint Foundation Web Application\$WebApplicationName" -Confirm:$false	
}

# I want to backup a web application on port 7005 which was named - SharePoint - 7005
$backupLocation = "\\sp2010riyaz\OPA_Backup"
$WebApplicationName = "SharePoint - 7005"

BackupSPFarm -BackupLocation $backupLocation -WebApplicationName $WebApplicationName