Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction 0

$winAp = new-SPAuthenticationProvider -UseWindowsIntegratedAuthentication -DisableKerberos

Get-SPWebApplication -Identity "http://sp2010riyaz:9080" | new-SPWebApplicationExtension -AuthenticationProvider $winAp -Name "oamadmin.directenergy.com_intranet" -URL http://oamadmin.directenergy.com -Zone "Intranet" -HostHeader "oamadmin.directenergy.com" -Port 9090