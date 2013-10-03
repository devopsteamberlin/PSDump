$ErrorActionPreference = "Stop"
Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0
$url = "http://sp2010riyaz:65535"
$site = New-Object Microsoft.SharePoint.SPSite($url)
$loc = [System.Int32]::Parse(1033)
$templates = $site.GetWebTemplates($loc)
foreach($child in $templates){
	Write-Host $child.Name " " $child.Title
}
$site.Dispose()