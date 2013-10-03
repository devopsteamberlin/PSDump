
$ErrorActionPreference = "Stop"

Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

# Example:
# $file = Invoke-FileBrowser -Title "Select a file" -Directory "D:\backups" -Filter "Powershell Scripts|(*.ps1)"
function Invoke-FileBrowser
{
      param([string]$Title,[string]$Directory,[string]$Filter="All Files (*.*)|*.*")
      [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
      $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog
      $FileBrowser.InitialDirectory = $Directory
      $FileBrowser.Filter = $Filter
      $FileBrowser.Title = $Title
      $Show = $FileBrowser.ShowDialog()
      If ($Show -eq "OK")
      {
            Return $FileBrowser.FileName
      }
      Else
      {
            Write-Error "Restore cancelled by user."
      }
}

# Example:
# Remove-Readonly -FilePath "D:\backups\filename.txt"
function Remove-Readonly
{
	param([string]$FilePath)
	#Remove read-only attribute, otherwise access denied error.
	Set-ItemProperty -Path $FilePath -name IsReadOnly -value $false
}

# Example:
# Restore-SPBackup -FilePath "D:\backups\backupfile.bak"
function Restore-SPBackup
{
	param([string]$BackupFilePath, [string]$WebUrl)
	#Restore the backup without asking for confirmation.
	Restore-SPSite -Identity $WebUrl -Path $BackupFilePath -Confirm:$false
}

$backupLocation = "C:\SPSBackup\OPA"
$SiteUrl = "http://sp2010riyaz:7005/contracts"

$file = Invoke-FileBrowser -Title "Browse" -Directory $backupLocation -Filter "All Files (*.*)|*.*"
Remove-Readonly -FilePath $file
Restore-SPBackup -BackupFilePath $file -WebUrl $SiteUrl
