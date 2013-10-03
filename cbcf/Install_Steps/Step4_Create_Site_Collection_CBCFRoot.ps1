$ErrorActionPreference = "Stop"

Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

function Main()
{
	# Set variables - <Top Site>
	$SiteCollectionName = "CBCFROOT";
	$SiteCollectionURL = "http://sp2010riyaz:10000";
	$SiteCollectionTemplate = "CBCFRoot#0";
	$SiteCollectionLanguage = 1033;
	$SiteCollectionOwner = "domainx\sp2010installer";	
	# </Top Site>
	
	$SearchSiteUrl="http://sp2010riyaz:10000/Search/"
	$SearchSiteTemplate="CBCFSearch#0"
	$SubSites="Search"

	Write-Host "Creating Top Level Web Site ($SiteCollectionURL)..."

	$GetSPSiteCollection = Get-SPSite | Where-Object {$_.Url -eq $SiteCollectionURL}
	    
	
	If ($GetSPSiteCollection -eq $null)
	{
		Write-Host -ForegroundColor Green " - Creating Site Collection `"$SiteURL`"..."
		
		stsadm -o createsite -url $SiteCollectionURL  -owneremail "someone@example.com" -ownerlogin $SiteCollectionOwner -lcid $SiteCollectionLanguage -sitetemplate $SiteCollectionTemplate -title $SiteCollectionName

		# Create a new Sharepoint Site Collection
		#New-SPSite -URL $SiteCollectionURL -Template $SiteCollectionTemplate -Name $SiteCollectionName -OwnerAlias $SiteCollectionOwner -Language $SiteCollectionLanguage
	}
	Else {Write-Host -ForegroundColor Green " - Site Collection `"$SiteCollName`" already provisioned."}
	
	# -----------------------------------------------------------
	
	Write-Host "Creating Search Sub site ($SearchSiteUrl)..."

	$GetSPSearchSite = Get-SPSite | Where-Object {$_.Url -eq $SearchSiteUrl}	    
	
	If ($GetSPSearchSite -eq $null)
	{
		Write-Host -ForegroundColor Green " - Creating Site `"$SearchSiteUrl`"..."
		
		stsadm -o createweb -url $SearchSiteUrl  -lcid $SiteCollectionLanguage -sitetemplate $SearchSiteTemplate -title $SubSites -unique
		
		# Create a new Sharepoint Search Site
		#New-SPSite -URL $SearchSiteUrl -Template $SearchSiteTemplate -Name $SubSites
	}
	Else {Write-Host -ForegroundColor Green " - Site `"$SearchSiteUrl`" already provisioned."}
	
	Write-Host "Press any key to continue ..."
	
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

Main