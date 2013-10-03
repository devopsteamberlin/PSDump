$ErrorActionPreference = "Stop"

Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

$SMTPSvr = 'ad-ex2003.domainx.local'
$FromAddr = 'noreply@domainx.local'
$ReplyAddr = 'noreply@domainx.local'
$Charset = 65001

$CAWebApp = Get-SPWebApplication -IncludeCentralAdministration | Where { $_.IsAdministrationWebApplication }
$CAWebApp.UpdateMailSettings($SMTPSvr, $FromAddr, $ReplyAddr, $Charset)