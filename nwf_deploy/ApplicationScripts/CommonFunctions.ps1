function Get-NtxWorkflowService {
<#
.Synopsis
	Use to retreive the Nintex workflow web service proxy.
.Description
	Uses default credential, pass required credential when needed.
.Example
	C:\PS>Get-NtxWorkflowService -url http://erefsps/_vti_bin/nintexworkflow/workflow.asmx?WSDL -cred [System.Net.CredentialCache]::DefaultCredentials
	This example returns the web service instance using default credential.
.Notes
	None
.Link
	None
.Inputs
	None
.Outputs
	None
#>   
[CmdletBinding()]
	Param(
	[Parameter(Mandatory=$true)]
	[string]$url,
	[Parameter(Mandatory=$false)]
	[System.Net.NetworkCredential]$cred=$null
	)
 	if($cred -eq $null)
 	{
 		$cred = [System.Net.CredentialCache]::DefaultCredentials;
 	}
 
	return New-WebServiceProxy -uri $url -Credential $cred	
}

function New-SPList {
<#
.Synopsis
	Use New-SPList to create a new SharePoint List or Library.
.Description
	This advanced PowerShell function uses the Add method of a SPWeb object to create new lists and libraries in a SharePoint Web
	specified in the -Web parameter.
.Example
	C:\PS>New-SPList -Web http://intranet -ListTitle "My Documents" -ListUrl "MyDocuments" -Description "This is my library" -Template "Document Library"
	This example creates a standard Document Library in the http://intranet site.
.Example
	C:\PS>New-SPList -Web http://intranet -ListTitle "My Announcements" -ListUrl "MyAnnouncements" -Description "These are company-wide announcements." -Template "Announcements"
	This example creates an Announcements list in the http://intranet site.
.Notes
	You must use the 'friendly' name for the type of list or library.  To retrieve the available Library Templates, use Get-SPListTemplates.
.Link
	None	
.Inputs
	None
.Outputs
	None
#>    
	[CmdletBinding()]
	Param(
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
	[string]$Web,
    [Parameter(Mandatory=$true)]
	[string]$ListTitle,
    [Parameter(Mandatory=$true)]
	[string]$ListUrl,
	[Parameter(Mandatory=$false)]
	[string]$Description,
	[Parameter(Mandatory=$true)]
	[string]$Template
    )
Start-SPAssignment -Global
$SPWeb = Get-SPWeb -Identity $Web
$listTemplate = $SPWeb.ListTemplates[$Template]
$SPWeb.Lists.Add($ListUrl,$Description,$listTemplate)
$list = $SPWeb.Lists[$ListUrl]
$list.Title = $ListTitle
$list.Update()
$SPWeb.Dispose()
Stop-SPAssignment -Global
}