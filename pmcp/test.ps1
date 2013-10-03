$ErrorActionPreference = "Stop"

Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

#$ip = @( (Get- SPAuthenticationProvider "LiveID STS"), (New- SPAuthenticationProvider –ASPNetMembershipProvider "myMembershipProvider" –ASPNetRoleProvider "myRoleProvider"), (Get-SPAuthenticationProvider "NTLM")) )

#$ip = @((New-SPAuthenticationProvider –ASPNetMembershipProvider "FBA" –ASPNetRoleProvider "FBARole"), (Get-SPAuthenticationProvider "NTLM"))

$ip = @((Get- SPAuthenticationProvider "LiveID STS"), (New- SPAuthenticationProvider –ASPNetMembershipProvider "FBA" –ASPNetRoleProvider "FBARole"), (Get-SPAuthenticationProvider "NTLM")))
New–SPWebApplication http://contoso.com -AuthenticationProvider $ip


#new-spauthenticationprovider –aspnetmembershipprovider "FBA" –aspnetroleprovidername "FBARole"