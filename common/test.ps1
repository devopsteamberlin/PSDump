Add-PsSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

$cred = new-object System.Net.NetworkCredential("sheriffm","Donkey1","domainx")

if($cred -eq $null)
{
$cred = [System.Net.CredentialCache]::DefaultCredentials;
}

$session = New-PSSession -ConnectionUri 'http://navdevauthoring.pmcp.ca' -Credential $cred -Authentication Basic


$rootSiteUrl = "http://navdevauthoring.pmcp.ca"



$rootSite = New-Object Microsoft.SharePoint.SPSite($rootSiteUrl, $cred)

$spWebApp = $rootSite.WebApplication

foreach ($site in $spWebApp.Sites)
{
$site.Dispose()
}