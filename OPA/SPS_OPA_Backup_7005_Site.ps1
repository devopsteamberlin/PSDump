
$ErrorActionPreference = "Stop"

Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

# Example:
# BackupSPBackup -FilePath "D:\backups\backupfile.bak"
function BackupSPBackup
{
	param([string]$BackupFilePath, [string]$WebUrl)
	# Backup-SPSite the backup without asking for confirmation.
	Backup-SPSite -Identity $WebUrl -Path $BackupFilePath -Confirm:$false	
}

$backupLocation = "C:\SPSBackup\OPA"
$SiteUrl = "http://sp2010riyaz:7005/contracts"

$file = "$backupLocation\opa_backup.bak"

BackupSPBackup -BackupFilePath $file -WebUrl $SiteUrl
