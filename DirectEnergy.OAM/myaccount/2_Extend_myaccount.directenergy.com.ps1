Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction 0

$winAp = new-SPAuthenticationProvider -UseWindowsIntegratedAuthentication -DisableKerberos

Get-SPWebApplication -Identity "http://sp2010riyaz:9050" | new-SPWebApplicationExtension -AuthenticationProvider $winAp -Name "myaccount.directenergy.com_internet" -URL http://myaccount.directenergy.com -Zone "Internet" -HostHeader "myaccount.directenergy.com" -Port 9060