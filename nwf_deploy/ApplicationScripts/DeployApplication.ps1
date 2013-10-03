param ([string]$WebAppUrl, [string]$ContentDbName)

Set-ExecutionPolicy RemoteSigned

# Load SharePoint PS snap-in.
Add-Type -AssemblyName "Microsoft.SharePoint, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c"
$snapin = Get-PsSnapin Microsoft.SharePoint.PowerShell -ea SilentlyContinue

if ($snapin -eq $null) {
    Add-PsSnapin Microsoft.SharePoint.PowerShell
}

$ApplicationScriptsFolder = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
$PackageRootFolder = [System.IO.Path]::GetDirectoryName($ApplicationScriptsFolder)
$SolutionsFolder = [System.IO.Path]::Combine($PackageRootFolder, "Solutions")
$LogsFolder = "$PackageRootFolder/Logs"
$NWAdminExecutablePath = "$Env:ProgramFiles\Nintex\Nintex Workflow 2010\NWAdmin.exe"

if(-not (Test-Path $LogsFolder)) {New-Item $LogsFolder -Type Directory | Out-Null}
$Log = "$LogsFolder/" + (Get-Date -format yyyy-MM-dd_HH.mm.ss) + ".log"

#Load common functions
. "$ApplicationScriptsFolder\SharePointFunctions.ps1"

function ProvisionApplication($url, $dbName){
#region Prerequisites
	
	$rootUrl = Normalize-Url $url
	#region Site Collection & Root Site
	$siteUrl = $rootUrl + "/Contracts"
	
	#Write-Message "fixme: Temporarily disabled to avoid build break" "Magenta"
	Write-Message "Nintex Process - Publishing Nintex workflow constants..." "cyan"
	$workflowRootFolder = "$PackageRootFolder\NintexWF"		

	# Populate site collection level workflow constants
	$constantsFilePath = "$ApplicationScriptsFolder\EnvironmentSpecific\NintexWFConstants.xml"		
	#PopulateNintexWFConstants -constantsFilePath $constantsFilePath  -siteUrl $siteUrl
		
	Write-Message "Nintex Process - Publishing (Settlement Approval Workflow)..." "cyan"
	$wfFileName = "Approval_Process_WF.nwf"	
	PublishApprovalWorkflows -workflowRootFolder $workflowRootFolder -wfFileName $wfFileName -publishAsTitle "Settlement Approval Workflow" -siteUrl $siteUrl
	
	$webUrl = $siteUrl + "/approval"
	$listName = "Settlement Approval Process Library"
	AssociateLibraryWorkflows -webUrl $webUrl -listName $listName
}

function PublishApprovalWorkflows($workflowRootFolder, $wfFileName, $publishAsTitle, $siteUrl, [string]$listName = $null){
	
	$workflowFileToPublish = "$workflowRootFolder\$wfFileName"	
	$NWServiceURL = $siteUrl + "/_vti_bin/nintexworkflow/workflow.asmx?WSDL";

	echo $NWServiceURL

	$ws = New-WebServiceProxy -uri $NWServiceURL -useDefaultCredential
	
	echo $workflowFileToPublish
		
	# Reads workflow file content
	$NWFContent = [System.IO.File]::ReadAllBytes($workflowFileToPublish)
	
	
	echo $listName
	echo $publishAsTitle
	
	$result = $ws.PublishFromNWF($NWFContent, $listName, $publishAsTitle, $true)	
}

function AssociateLibraryWorkflows($webUrl, $listName){
	# Start the workflow
	$web = Get-SPWeb $webUrl

	$library = $web.Lists[$listName];
	$taskList = $web.Lists["Workflow Tasks"];
	$workflowHistoryList = $web.Lists["NintexWorkflowHistory"];
	$installedWFTemplateName = "Settlement Approval Process"
				
	$wfTemplate = $web.WorkflowTemplates | Where-Object { $_.Name -eq $installedWFTemplateName }

	if ($wfTemplate -ne $null)
    {
		$workflowInstanceName = "Settlement Approval Process"
		$wfAssociation =[Microsoft.SharePoint.Workflow.SPWorkflowAssociation]::CreateListAssociation($wfTemplate, $workflowInstanceName, $taskList, $workflowHistoryList)
		$output = $library.WorkflowAssociations.Add($wfAssociation)
		
		$workflowInstanceName = "HESA Settlement Approval Process"
		$wfAssociation =[Microsoft.SharePoint.Workflow.SPWorkflowAssociation]::CreateListAssociation($wfTemplate, $workflowInstanceName, $taskList, $workflowHistoryList)
		$output = $library.WorkflowAssociations.Add($wfAssociation)
    }     
}

function PopulateNintexWFConstants($constantsFilePath, $siteUrl){

	if([IO.File]::Exists($constantsFilePath) -ne $true)
	{
		Write-Message "Missing Nintex constants file. $constantsFilePath" "red" $false
	}
	
	if([IO.File]::Exists($NWAdminExecutablePath) -ne $true)
	{
		Write-Message "Missing Nintex constants file. $NWAdminExecutablePath" "red" $false
	}	
	
	# execute command
	& "$NWAdminExecutablePath" -o ImportWorkflowConstants `
							-siteUrl $siteUrl `
							-inputFile $constantsFilePath `
							-handleExisting Overwrite `
							-includeSite `
							-includeSiteCollection `
							-includeFarm	
}

$0 = $myInvocation.MyCommand.Definition
$dp0 = [System.IO.Path]::GetDirectoryName($0)

$WebAppUrl = "http://sp2010riyaz:3877"
$ContentDbName = "OPA_Setlement_New_Db"

ProvisionApplication $WebAppUrl $ContentDbName