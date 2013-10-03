Start-SPAssignment -Global
$account = "domainx\sp2010installer"    
$apppool = "CBCF Portal App Pool"
$database = "WSS_Content_CBCF_Development"
$url = "http://sp2010riyaz"
$port = 10000
$WebAppName = "SharePoint - CBCF " + $port    
$useSSL = $false
If ($url -like "https://*") {$useSSL = $true; $hostheader = $url -replace "https://",""}        
Else {$hostheader = $url -replace "http://",""}
$GetSPWebApplication = Get-SPWebApplication | Where-Object {$_.DisplayName -eq $WebAppName}
If ($GetSPWebApplication -eq $null)
{
	Write-Host -ForegroundColor White " - Creating Web App `"$WebAppName`""
	
	# Configure new web app to use Claims-based authentication
	$AuthProvider = New-SPAuthenticationProvider -UseWindowsIntegratedAuthentication
	New-SPWebApplication -Name $WebAppName -ApplicationPoolAccount $account -ApplicationPool $apppool -DatabaseName $database -HostHeader $hostheader -Url $url -Port $port -SecureSocketsLayer:$useSSL -AuthenticationProvider $AuthProvider | Out-Null
	[bool]$ClaimsHotfixRequired = $true
	Write-Host -ForegroundColor Yellow " - Web Applications using Claims authentication require an update"
	Write-Host -ForegroundColor Yellow " - Apply the http://go.microsoft.com/fwlink/?LinkID=184705 update after setup."   		
}	
Else {Write-Host -ForegroundColor White " - Web app `"$WebAppName`" already provisioned."}

Stop-SPAssignment -Global