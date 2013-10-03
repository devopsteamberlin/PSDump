Add-PsSnapin Microsoft.SharePoint.PowerShell

# Loading of SharePoint dll.
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint") 

# This script creates 50 subsites on the set site collection url.
Write-Output " "
Write-Output "Creation of 50 sub-sites in progress..."

# Parameters used in the script
$SiteCollectionUrl = "http://www.yukoon.com:81/department/dep1"
$SiteCollectionTemplate = "STS#0" 
$SiteCollectionLanguage = 1033
$StaplingWeb = "project_no_"

for($i=0 ; $i -lt 50 ; $i++)
{
	$siteId = $i + 1
    $SiteUrl = $SiteCollectionUrl + "/"
    $SubSiteName = $StaplingWeb + $siteId
    $SiteUrl = $SiteUrl += $SubSiteName

    Write-Host "Creating Sub-Site -- " $SubSiteName
    New-SPWeb $SiteUrl -Template $SiteCollectionTemplate -Name $SubSiteName  -UseParentTopNav -Language $SiteCollectionLanguage
    Write-Host "Site -> " $SubSiteName " successfully created."
}

Remove-PsSnapin Microsoft.SharePoint.PowerShell