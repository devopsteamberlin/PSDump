Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction 0

$winAp = new-SPAuthenticationProvider -UseWindowsIntegratedAuthentication -DisableKerberos

Get-SPWebApplication -Identity "http://sp2010riyaz:7117" | new-SPWebApplicationExtension -AuthenticationProvider $winAp -Name "hodsdev_intranet" -URL http://hodsdev.hydroone.com -Zone "Intranet" -HostHeader "hodsdev.hydroone.com" -Port 80