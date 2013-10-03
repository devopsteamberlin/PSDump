$FilePath = "C:\mywork\scm\CapitalPower.DocumentManagement\Dev\Main\CapitalPower.DM.Deployment\Application\Maintenance\dm-metadata-store-CE.bak"
### Initialize environment
Set-ExecutionPolicy RemoteSigned

# Load SharePoint PS snap-in.
Add-Type -AssemblyName "Microsoft.SharePoint, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c"
$snapin = Get-PsSnapin Microsoft.SharePoint.PowerShell -ea SilentlyContinue

if ($snapin -eq $null) {
    Add-PsSnapin Microsoft.SharePoint.PowerShell
}

#Set global variables
$SolutionInstallRetryAttempts = 36
$SolutionInstallSleepDelay = 5
$ScriptsFolder = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
$PackageRootFolder = [System.IO.Path]::GetDirectoryName($ScriptsFolder)
$SolutionsFolder = [System.IO.Path]::Combine($PackageRootFolder, "Solutions")
$MMSDataFolder = [System.IO.Path]::Combine($PackageRootFolder, "MMSData")
$LogsFolder = "$PackageRootFolder/Logs"
if(-not (Test-Path $LogsFolder)) {New-Item $LogsFolder -Type Directory | Out-Null}
$Log = "$LogsFolder/" + (Get-Date -format yyyy-MM-dd_HH.mm.ss) + ".log"


###############################################################################
# Exports a managed metadata store to a file.
###############################################################################
function Export-ManagedMetadataStore($filePath, $mmsServiceApplicationName){
  Write-Message "Exporting managed metadata service application data to file `"$filePath`"..." "cyan"
	if($filePath -eq $null -or $filePath -eq "") {
		throw "Export file path is required."
	}
	if($mmsServiceApplicationName -eq $null -or $filePath -eq "") {
		throw "Name of metadata service application is required."
	}
	$folderPath = [System.IO.Path]::GetDirectoryName($filePath)
	if([System.IO.Directory]::Exists($folderPath) -ne $true){
		Write-Message "A directory `"$folderPath`" does not exist. Creating..." "yellow"
		New-Item -Path $folderPath -type directory -ea:Stop | Out-Null
	}
	$mmsApp = Get-SPServiceApplication | ? `
		{$_.TypeName -eq "Managed Metadata Service" -and $_.DisplayName -eq $mmsServiceApplicationName}
	if($mmsApp -eq $null){
		throw "Cannot find a service application of type 'Managed Metadata Service' with display name `'$mmsServiceApplicationName`'."
	}

	$mmsProxy = Get-SPServiceApplicationProxy | ? `
		{$_.TypeName -eq "Managed Metadata Service Connection" -and $_.DisplayName -eq $mmsServiceApplicationName}
	if($mmsProxy -eq $null){
		throw "Cannot find a service application proxy of type 'Managed Metadata Service Connection' with display name `'$mmsServiceApplicationName`'."
	}
	Export-SPMetadataWebServicePartitionData -Identity $mmsApp.Id -ServiceProxy $mmsProxy -Path $filePath -ea:Stop
}

###############################################################################
# Imports managed metadata store from a file, overwriting its data.
###############################################################################
function Import-ManagedMetadataStore($filePath, $mmsServiceApplicationName){
 	Write-Message "Importing managed metadata service application data from file `"$filePath`"..." "cyan"
	if($filePath -eq $null -or $filePath -eq "") {
		throw "Import file path is required."
	}
	if($mmsServiceApplicationName -eq $null -or $filePath -eq "") {
		throw "Name of metadata service application is required."
	}
	if([System.IO.File]::Exists($filePath) -ne $true){
		throw "A file not found at a path `"$filePath`"."
	}
	$mmsApp = Get-SPServiceApplication | ? `
		{$_.TypeName -eq "Managed Metadata Service" -and $_.DisplayName -eq $mmsServiceApplicationName}
	if($mmsApp -eq $null){
		throw "Cannot find a service application of type 'Managed Metadata Service' with display name `'$mmsServiceApplicationName`'."
	}

	$mmsProxy = Get-SPServiceApplicationProxy | ? `
		{$_.TypeName -eq "Managed Metadata Service Connection" -and $_.DisplayName -eq $mmsServiceApplicationName}
	if($mmsProxy -eq $null){
		throw "Cannot find a service application proxy of type 'Managed Metadata Service Connection' with display name `'$mmsServiceApplicationName`'."
	}
  	try{
		Import-SPMetadataWebServicePartitionData 	-Identity $mmsApp.Id `
													-ServiceProxy $mmsProxy `
													-Path $filePath `
													-ea:Stop `
													-OverwriteExisting
	}catch{
		throw ("$_. If having permissions issues, check that service account " + `
		"of the MMS application has bulkadmin role in SQL server. For more info see " + `
		"http://blogs.msdn.com/b/taj/archive/2011/03/20/import-spmetadatawebservicepartitiondata-error-in-multi-server-deployment.aspx")
	}
}

###############################################################################
# Writes a message to the output and to the log file.
###############################################################################
function Write-Message ($message, $foregroundColor, $writeToLog = $true) {
    if($message -ne $null) {
        Write-Host $message -foregroundcolor $foregroundColor
        
        if($writeToLog -eq $true) {
            $stamp = Get-Date -format "yyyy-MM-dd HH:mm:ss"
            $stampedMessage = $stamp + "  " + $message
            $stampedMessage | Out-File -FilePath $Log -Width 255 -Append -Force
        }
    }
}

### Begin script execution here.
Write-Message  "`r`n***  Term store export script for Capital Power Document Management Portal  ***`r`n" "cyan"
$scriptUsage = "Script usage: `r`n$($MyInvocation.MyCommand) -FilePath <path to term store file>`r`n"

if(($FilePath -eq [string]::Empty) -or ($FilePath -eq $null)) {
    Write-Message "Missing parameter value. $scriptUsage" "red" $false
	exit -1
}
Write-Message "Log file name: $Log" "white" $false
$mmsAppName = "Managed Metadata Service"
try{
	Export-ManagedMetadataStore $filePath $mmsAppName
	Write-Message "done." "cyan" $false
	exit 0
} catch {
    Write-Message "Failed to export term store. Error message: `"$_`"" "red"
	exit -1
}
