$ErrorActionPreference = "Stop"

Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

$WebApp = "http://sp2010riyaz:4040"
$xName = "SharePoint - sp2010riyaz(40)"
$xHostHeader = "www.navdevrs.pmcp.ca"
$xPort = 40
$xZone = "Internet"
$xUrl = "http://www.navdevrs.pmcp.ca/"

Write-Host "Start extending the web application ($WebApp)..." -ForegroundColor Yellow

Get-SPWebApplication -Identity $WebApp | New-SPWebApplicationExtension `
–Name $xName `
-HostHeader $hostHeader `
-Port $xPort `
-Zone $xZone `
-URL $xUrl `
-AllowAnonymous:$true

Write-Host "Finished!" -ForegroundColor Green