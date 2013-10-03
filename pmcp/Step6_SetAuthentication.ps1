$ErrorActionPreference = "Stop"

Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

function Main()
{
	$webapp = Get-SPWebApplication "http://www.navdevrs.pmcp.ca:40/"	
	$zone=[microsoft.sharepoint.administration.spurlzone]::Internet

	$ap = @()

	Get-SPAuthenticationProvider -WebApplication $webapp.Name -Zone:$zone | ForEach-Object { 
	  if( $_.GetType().FullName -ne "Microsoft.SharePoint.Administration.SPFormsAuthenticationProvider"){
		$ap = $ap + $_
	}
	}
	
	$ap = $ap + (New-SPAuthenticationProvider -ASPNETMembershipProvider "FBA" -ASPNETRoleProviderName "FBARole")
	Set-SPWebApplication -Identity $webapp.Name -Zone:$zone -AuthenticationProvider $ap	
	$webapp.Update()
	
    Write-Host "Successfully updated Web application ($webAppName)."
}

Main