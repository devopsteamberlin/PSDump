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
$ApplicationScriptsFolder = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
$PackageRootFolder = [System.IO.Path]::GetDirectoryName($ApplicationScriptsFolder)
$SolutionsFolder = [System.IO.Path]::Combine($PackageRootFolder, "Solutions")
$DataFolder = [System.IO.Path]::Combine($PackageRootFolder, "Data")
$LogsFolder = "$PackageRootFolder/Logs"
$NWAdminExecutablePath = "$Env:ProgramFiles\Nintex\Nintex Workflow 2010\NWAdmin.exe"

if(-not (Test-Path $LogsFolder)) {New-Item $LogsFolder -Type Directory | Out-Null}
$Log = "$LogsFolder/" + (Get-Date -format yyyy-MM-dd_HH.mm.ss) + ".log"

#Load common functions
. "$ApplicationScriptsFolder\SharePointFunctions.ps1"

# Load environment-specific configuration functions.
# MSBuild wires up a version of this file matching selected build configuration.
. "$ApplicationScriptsFolder\EnvironmentSpecific\ConfigFunctions.ps1"
