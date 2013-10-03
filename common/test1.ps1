############################################################################
#WarmUp2.ps1 - Enumerates all web sites in web applications in a 2010
# SharePoint farm and opens each in a browser.
#Notes:
#-"get-webpage" function borrowed from:
# http://kirkhofer.wordpress.com/2008/10/18/sharepoint-warm-up-script/
#
#Assumptions:
#-Running on machine with WSS/MOSS 2010 installed
############################################################################

Add-PsSnapin Microsoft.SharePoint.PowerShell
$extrasitelistfile = 'c:\Tools\Warmup\warmup-extrasites.txt'

function get-webpage([string]$url,[System.Net.NetworkCredential]$cred=$null)
{
$wc = new-object net.webclient
if($cred -eq $null)
{
$cred = [System.Net.CredentialCache]::DefaultCredentials;
}
$wc.credentials = $cred;
return $wc.DownloadString($url);
}

#This passes in the default credentials needed. If you need specific
#stuff you can use something else to elevate basically the permissions.
#Or run this task as a user that has a Policy above all the Web
#Applications with the correct permissions

$cred = [System.Net.CredentialCache]::DefaultCredentials;
#$cred = new-object System.Net.NetworkCredential("username","password","machinename")

$apps = get-spwebapplication -includecentraladministration
foreach ($app in $apps) {
$sites = get-spsite -webapplication $app.url
foreach ($site in $sites) {
write-host $site.Url;
$html=get-webpage -url $site.Url -cred $cred;
}
}
# Warm up other sites specified in warmup-extrasites.txt file (such as SSRS)

if (test-path $extrasitelistfile) {
$extrasites = get-content $extrasitelistfile
foreach ($site in $extrasites) {
write-host $site;
$html=get-webpage -url $site -cred $cred;
}
}
