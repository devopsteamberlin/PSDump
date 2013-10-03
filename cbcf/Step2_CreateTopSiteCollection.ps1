$ErrorActionPreference = "Stop"

Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

function Main()
{
	# Set variables - <Top Site>
	$SiteCollectionName = "PortalHome";
	$SiteCollectionURL = "http://sp2010riyaz:10000";
	$SiteCollectionTemplate = "CBCFRoot#0";
	$SiteCollectionLanguage = 1033;
	$SiteCollectionOwner = "domainx\sp2010installer";	
	# </Top Site>

	Write-Host "Creating Top Level Web Site ($SiteCollectionURL)..."

	$GetSPSiteCollection = Get-SPSite | Where-Object {$_.Url -eq $SiteCollectionURL}
	    
	
	If ($GetSPSiteCollection -eq $null)
	{
		Write-Host -ForegroundColor White " - Creating Site Collection `"$SiteURL`"..."
		# Create a new Sharepoint Site Collection
		New-SPSite -URL $SiteCollectionURL -OwnerAlias $SiteCollectionOwner -Language $SiteCollectionLanguage -Template $SiteCollectionTemplate -Name $SiteCollectionName
	}
	Else {Write-Host -ForegroundColor White " - Site Collection `"$SiteCollName`" already provisioned."}
}

Main