param(
[string]$account = $(throw "Provide the login creation to create the web application."), #Farm account used to create the web application
[string]$url = $(throw "Provide server url for the web application."), #Default url used to create the application
$port = $(throw "Provide a port number for the web application."), #A port number used for testing
$apppool = $(throw "Provide an name for the appool") #Appool name
)

$database = $apppool
$WebAppName = "SharePoint-$apppool" + $port    
$useSSL = $false

If ($url -like "https://*") {$useSSL = $true; $hostheader = $url -replace "https://",""}        
Else {$hostheader = $url -replace "http://",""}
$GetSPWebApplication = Get-SPWebApplication | Where-Object {$_.DisplayName -eq $WebAppName}
If ($GetSPWebApplication -eq $null)
{
	Write-Host -ForegroundColor DarkGreen "Initializing web application creation `"$WebAppName`""
	
	# Configure new web app to use Claims-based authentication
	$AuthProvider = new-SPAuthenticationProvider -UseWindowsIntegratedAuthentication -DisableKerberos
	
	$webApp = New-SPWebApplication -Name $WebAppName -ApplicationPoolAccount $account -ApplicationPool $apppool -AuthenticationProvider $AuthProvider -DatabaseName $database -HostHeader $hostheader -Url $url -Port $port -SecureSocketsLayer:$useSSL | Out-Null
	
	# Retreive created web application
	$webApp = Get-SPWebApplication $WebAppName
	$webApp.UseClaimsAuthentication = $True;
	$webApp.Update()
	
	Write-Host -ForegroundColor DarkGreen "`t Successfully created web application `"$WebAppName`""
}	
Else {Write-Host -ForegroundColor Red "Specified web application `"$WebAppName`" already provisioned."}