$ErrorActionPreference = "Stop"

Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

function Main()
{
	# Script Parameter Update here
	$sp_webapp_url = "http://sp2010riyaz"
	$sp_webapp_port = 10000
	$sp_webapp_apppool = "SharePoint CBCF Portal App Pool"
		
	# The following account should be farm admin account
	$sp_webapp_apppoolaccount = "domainx\sp2010installer"
	
	$sp_webapp_hostheader = $sp_webapp_url.Substring("http://".Length)
	$sp_webapp_name = "SharePoint - " + $sp_webapp_hostheader + $sp_webapp_port
	
	$sp_webapp_databasename = "CBCF_Portal_Content"
	$sp_webapp_databaseserver = "sp2010riyaz"

	Write-Host "Creating Web application ($sp_webapp_url)..."
	
	# Retreive the web application if exists
	$GetSPWebApplication = Get-SPWebApplication | Where-Object {$_.DisplayName -eq $sp_webapp_name}
		
	If ($GetSPWebApplication -eq $null)
   	{
	 	Write-Host " - Creating Web App `"$sp_webapp_name`""
		
		#Create a new Web Application
		new-spwebapplication -name $sp_webapp_name `
		-Port $sp_webapp_port -HostHeader `
		$sp_webapp_hostheader `
		-URL $sp_webapp_url `
		-ApplicationPool $sp_webapp_apppool `
		-ApplicationPoolAccount (Get-SPManagedAccount $sp_webapp_apppoolaccount) `
		-DatabaseName $sp_webapp_databasename -DatabaseServer $sp_webapp_databaseserver `
		-Debug:$false
	}
	Else {Write-Host " - Web app `"$sp_webapp_name`" already provisioned."}
	
    Write-Host "Successfully created Web application ($sp_webapp_name)."
}

Main