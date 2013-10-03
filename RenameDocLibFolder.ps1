$SiteUrl = "http://sp2010riyaz:65535/CPDMSITES/CPGEN"
### Initialize environment
Set-ExecutionPolicy RemoteSigned

# Load SharePoint PS snap-in.
Add-Type -AssemblyName "Microsoft.SharePoint, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c"
$snapin = Get-PsSnapin Microsoft.SharePoint.PowerShell -ea SilentlyContinue

if ($snapin -eq $null) {
    Add-PsSnapin Microsoft.SharePoint.PowerShell
}

try{
	Write-Host -ForegroundColor Cyan "Genesee Document Library Folder Renaming Operation"
	
	#Elevated priveleges block to accommodate running scripts remotely on a server with UAC enabled.
	[Microsoft.SharePoint.SPSecurity]::RunWithElevatedPrivileges({
	
	Write-Host "Open site [$SiteUrl]..." -NoNewline		
	[System.Reflection.Assembly]::LoadWithPartialName("System.Web")
	$web = get-spweb $SiteUrl
	Write-Host -ForegroundColor Green "done." 
	
	$ExistingFolderPathName = "HealthSafe/Ability - Claims Management"
	Write-Host "GetFolder [$ExistingFolderPathName]..." -NoNewline
	#get the folder
	$folder = $web.GetFolder($ExistingFolderPathName)
	Write-Host -ForegroundColor Green "done."

	#set the path
	$NewFolderPathName = "HealthSafe/Abilities - Claims Management"
	
	Write-Host "Renaming to new folder path [$NewFolderPathName]..." -NoNewline
	#move the folder to the new path
	$folder.MoveTo($NewFolderPathName)
	Write-Host -ForegroundColor Green "done."
	
	Write-Host -ForegroundColor Green "Successfully completed."
	
	})
} 
catch 
{
	Write-Host -ForegroundColor Red "Cannot continue. An error occurred: $_"
	exit -1
}