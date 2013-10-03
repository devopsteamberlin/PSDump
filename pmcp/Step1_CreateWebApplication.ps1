$ErrorActionPreference = "Stop"

Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

function Main()
{
	# Script Parameter Update here
	$spweb = "http://sp2010riyaz"
	$port = 4040
	$apppool = "PMCP_Portal_Application_Pool"
	$hostHeader = $spweb.Substring("http://".Length)
	$webAppName = "SharePoint - " + $hostHeader + "(" + $port + ")"
	$spContentDB = "PMCP_Portal_Content"
	$dbServer = "sp2010riyaz"
	
	# The following account should be farm admin account
	$poolAccount = "domainx\sp2010installer"	

	Write-Host "Creating Web application ($spweb)..."
	
	# Retreive the web application if exists
	$GetSPWebApplication = Get-SPWebApplication | Where-Object {$_.DisplayName -eq $webAppName}
		
	If ($GetSPWebApplication -eq $null)
   	{
	 	Write-Host " - Creating Web App `"$webAppName`""
		
		#Create a new Web Application
		new-spwebapplication -name $webAppName `
		-Port $port -HostHeader `
		$hostHeader `
		-URL $spweb `
		-ApplicationPool $apppool `
		-ApplicationPoolAccount (Get-SPManagedAccount $poolAccount) `
		-DatabaseName $spContentDB -DatabaseServer $dbServer `
		-Debug:$false	
	}
	Else {Write-Host " - Web app `"$webAppName`" already provisioned."}
	
    Write-Host "Successfully created Web application ($webAppName)."
}

Main