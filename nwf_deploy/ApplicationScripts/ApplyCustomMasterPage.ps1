Set-ExecutionPolicy RemoteSigned

# Load SharePoint PS snap-in.
Add-Type -AssemblyName "Microsoft.SharePoint, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c"
$snapin = Get-PsSnapin Microsoft.SharePoint.PowerShell -ea SilentlyContinue

if ($snapin -eq $null) {
    Add-PsSnapin Microsoft.SharePoint.PowerShell
}

function ApplyCustomMasterPage($webUrl, $masterPageFileName){
	Write-Message "Applying custom master page for the site $webUrl..." "cyan"
	$web = Get-SPWeb $webUrl
	$web.CustomMasterUrl = "/contracts/_catalogs/masterpage/$masterPageFileName"
	$web.Update()
}

$0 = $myInvocation.MyCommand.Definition
$dp0 = [System.IO.Path]::GetDirectoryName($0)

$WebAppUrl = "http://sp2010riyaz:3877"
$siteUrl = "$WebAppUrl/contracts"

ApplyCustomMasterPage -webUrl $siteUrl -masterPageFileName "OPA_Settlement.master"

$webUrl = $siteUrl + "/process"
ApplyCustomMasterPage -webUrl $webUrl -masterPageFileName "OPA_Settlement.master"