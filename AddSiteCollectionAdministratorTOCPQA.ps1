function Add-SiteCollectionAdministrator {
<#
.SYNOPSIS
Use this PowerShell script to add an account as Site Collection Administrator to all sites in a Web Application.

.DESCRIPTION
This PowerShell script uses Set-SPSite to add an account as Site Collection Administrator to an entire SharePoint Web Application.

.EXAMPLE
Add-SiteCollectionAdministrator -WebAppUrl http://intranet -Account "DOMAIN\Administrator"

This example adds the account DOMAIN\Administrator as a Site Collection Administrator to each site collection in the http://intranet web application.

.NOTES
Use this PowerShell script to add an account as Site Collection Administrator to all sites in a Web Application.

.LINK
http://www.iccblogs.com/blogs/rdennis
 http://twitter.com/SharePointRyan
 
.INPUTS
None

.OUTPUTS
None
#>

## Input Parameters ##
[CmdletBinding()]
Param(
[string]$WebAppUrl=(Read-Host "Please enter a Web Application URL (Example: http://intranet)"),
[string]$Account=(Read-Host "Please enter an account (Example: DOMAIN\Administrator)")
)
## Add SharePoint Snap-in ##
Add-PSSnapin Microsoft.SharePoint.PowerShell -erroraction SilentlyContinue
### No need to modify these ###
$WebApp = Get-SPWebApplication $WebAppUrl
$AllSites = $WebApp | Get-SPSite -Limit ALL

############################# The Script - no need to modify this section #############################
## Start SP Assignment for proper disposal of variables and objects ##
Write-Host "Starting SP Assignment..." -ForegroundColor Green
Start-SPAssignment -Global
## Use a ForEach-Object loop and Set-SPSiteAdministration to set an entire web application ##
Write-Host "Adding $Account to $WebAppUrl as a Site Collection Administrator..." -ForegroundColor Yellow
$AllSites | ForEach-Object { Set-SPSite -SecondaryOwnerAlias $Account -Identity $_.url }
## End SP Assignment for proper disposal of variables and objects ##
Write-Host "Disposing of SP Objects.." -ForegroundColor Green
Stop-SPAssignment -Global
## Tell us it's done ##
Write-Host "Finished!" -ForegroundColor Green
}

# ------------- Project Center (Top Site Collection) -------------------------------------------
# Qadomain\sheriffm, qadomain\danushkak, Qadomain\victorr, Qadomain\catherines
Add-SiteCollectionAdministrator -WebAppUrl "http://capitalpower-sp:65535" -Account "qadomain\danushkak"
Add-SiteCollectionAdministrator -WebAppUrl "http://capitalpower-sp:65535" -Account "qadomain\victorr"
Add-SiteCollectionAdministrator -WebAppUrl "http://capitalpower-sp:65535" -Account "qadomain\catherines"

# ------------- Project Sample Site -------------------------------------------
# Qadomain\sheriffm, qadomain\danushkak, Qadomain\victorr, Qadomain\catherines
Add-SiteCollectionAdministrator -WebAppUrl "http://capitalpower-sp:65535/CPDMPROJS/CPPRJ1" -Account "qadomain\danushkak"
Add-SiteCollectionAdministrator -WebAppUrl "http://capitalpower-sp:65535/CPDMPROJS/CPPRJ1" -Account "qadomain\victorr"
Add-SiteCollectionAdministrator -WebAppUrl "http://capitalpower-sp:65535/CPDMPROJS/CPPRJ1" -Account "qadomain\catherines"

# ------------- Genesee Site -------------------------------------------
# Qadomain\sheriffm, qadomain\danushkak, Qadomain\victorr, Qadomain\catherines
Add-SiteCollectionAdministrator -WebAppUrl "http://capitalpower-sp:65535/CPDMSITES/CPGEN" -Account "qadomain\danushkak"
Add-SiteCollectionAdministrator -WebAppUrl "http://capitalpower-sp:65535/CPDMSITES/CPGEN" -Account "qadomain\victorr"
Add-SiteCollectionAdministrator -WebAppUrl "http://capitalpower-sp:65535/CPDMSITES/CPGEN" -Account "qadomain\catherines"

# ------------- CE Site -------------------------------------------
# Qadomain\sheriffm, qadomain\danushkak, Qadomain\victorr, Qadomain\catherines
Add-SiteCollectionAdministrator -WebAppUrl "http://capitalpower-sp:65535/CPDMSITES/CPENG" -Account "qadomain\danushkak"
Add-SiteCollectionAdministrator -WebAppUrl "http://capitalpower-sp:65535/CPDMSITES/CPENG" -Account "qadomain\victorr"
Add-SiteCollectionAdministrator -WebAppUrl "http://capitalpower-sp:65535/CPDMSITES/CPENG" -Account "qadomain\catherines"