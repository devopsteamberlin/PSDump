Set-ExecutionPolicy RemoteSigned

# Load SharePoint PS snap-in.
Add-Type -AssemblyName "Microsoft.SharePoint, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c"
$snapin = Get-PsSnapin Microsoft.SharePoint.PowerShell -ea SilentlyContinue

if ($snapin -eq $null) {
    Add-PsSnapin Microsoft.SharePoint.PowerShell
}

#Set global variables
$SiteURL = "http://erefsps/"
$NintexWorkflowServiceURL = $SiteURL + "_vti_bin/nintexworkflow/workflow.asmx?WSDL";
# This passes in the default credentials needed.  If you need specific stuff you can use something else to
# elevate basically the permissions.  Or run this task as a user that has a Policy above all the Web Applications
# with the correct permissions
$credential = [System.Net.CredentialCache]::DefaultCredentials;
# $credential = new-object System.Net.NetworkCredential("username","password","machinename")
# List Specific Variables
$ListUrl = "MyContactList"
$ListTitle = "My Contact List"
$Description = "Demo List for attaching Nintex workflow (NWF)"
$Template = "Custom List"
$NWFExportedFilePath = "\WorkflowsToImport\Delete_Riyaz_Worded_Title.nwf"
$WorkflowFileToImport = [System.IO.Path]::Combine($MyInvocation.MyCommand.Path, $NWFExportedFilePath)

#Load common functions
$path = $MyInvocation.MyCommand.Path | Split-Path -Parent
$commonFunctionsScript = "CommonFunctions.ps1"
. (Join-Path $path $commonFunctionsScript)

# ---- Just some test code below (No standard followed)-----------
$site=Get-SPSite $SiteURL
$web=$site.RootWeb
$list=$web.Lists.TryGetList($ListTitle)

if($list -ne $null)
{
  write-host -f green $ListTitle "exists in the site" $SiteURL
}
else
{
  write-host -f Red $ListTitle "does not exist in site" $SiteURL
  Write-Host -f DarkGreen "Creating List" $ListTitle  
  New-SPList -ListTitle $ListTitle -ListUrl $ListUrl -Template $Template -Web $SiteURL -Description $Description  
}

$WorkflowFileContent = [System.IO.File]::ReadAllBytes($WorkflowFileToImport)

$ws = New-WebServiceProxy -uri $NintexWorkflowServiceURL -useDefaultCredential

$result = $ws.PublishFromNWF($WorkflowFileContent, $ListTitle, "Imported", $true)

if ($result){
	write-host -f Magenta "Nintex workflow has been published successfully to list " $ListTitle
}
else{
	write-host -f DarkRed "Error occured while publishing workflow to list " $ListTitle
}