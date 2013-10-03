Start-SPAssignment -Global
$account = "domainx\sp2010installer"    
$apppool = "DE_OAM_Gateway"
$database = "DE_OAM_Gateway"
$url = "http://sp2010riyaz"
$port = 9053
$WebAppName = "SharePoint - DE_OAM_Gateway " + $port    
$useSSL = $false
If ($url -like "https://*") {$useSSL = $true; $hostheader = $url -replace "https://",""}        
Else {$hostheader = $url -replace "http://",""}
$GetSPWebApplication = Get-SPWebApplication | Where-Object {$_.DisplayName -eq $WebAppName}
If ($GetSPWebApplication -eq $null)
{
	Write-Host -ForegroundColor White " - Creating Web App `"$WebAppName`""
	
	# Configure new web app to use Claims-based authentication
	$AuthProvider = New-SPAuthenticationProvider -UseWindowsIntegratedAuthentication
	$anoAp = new-SPAuthenticationProvider -AllowAnonymous
	$oamProv = new-SPAuthenticationProvider -ASPNETMembershipProvider "OAMMemberhsip" -ASPNETRoleProviderName "OAMRoleProvider"

	New-SPWebApplication -Name $WebAppName -ApplicationPoolAccount $account -ApplicationPool $apppool -DatabaseName $database -HostHeader $hostheader -Url $url -Port $port -SecureSocketsLayer:$useSSL -AuthenticationProvider $AuthProvider, $anoAp, $oamProv | Out-Null
	[bool]$ClaimsHotfixRequired = $true
	Write-Host -ForegroundColor Green " - Web Applications using Claims authentication require an update"
	Write-Host -ForegroundColor Green " - Apply the http://go.microsoft.com/fwlink/?LinkID=184705 update after setup."   		
}	
Else {Write-Host -ForegroundColor Red " - Web app `"$WebAppName`" already provisioned."}

Stop-SPAssignment -Global