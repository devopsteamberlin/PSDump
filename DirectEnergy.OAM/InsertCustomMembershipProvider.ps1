	cls
    $WebApp = Get-SPWebApplication http://sp2010riyaz:9050
		
	Write-Output "now adding the membership provider entry"
 
 	$configModM1 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification
	$configModM1.Path = "configuration/system.web/membership/providers"
	$configModM1.Name  =  "add[@name='OAMMembershipProvider']"   
 	$configModM1.Sequence = 0
	$configModM1.Type = 0
	$configModM1.Owner = "OAMMemberhsip"
	$configModM1.Value = "<add name='OAMMembershipProvider' type='DirectEnergy.Authentication.Provider.OAMMembershipProvider, DirectEnergy.Authentication, Version=1.0.0.0, Culture=neutral, PublicKeyToken=b6a416a3e4d1c768' authenticationServiceUrl='http://localhost:8080/OamUserAuthenticationProviderService.svc' />"


	$configModR1 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification
	$configModR1.Path = "configuration/system.web/roleManager/providers"
	$configModR1.Name  =  "add[@name='OAMRoleProvider']"   
 	$configModR1.Sequence = 0
	$configModR1.Type = 0
	$configModR1.Owner = "OAMMemberhsip"
	$configModR1.Value = "<add name='OAMRoleProvider' type='DirectEnergy.Authentication.Provider.OAMRoleProvider, DirectEnergy.Authentication, Version=1.0.0.0, Culture=neutral, PublicKeyToken=b6a416a3e4d1c768' authenticationServiceUrl='http://localhost:8080/OamUserAuthenticationProviderService.svc'  />"

		
    # Add mods, update, and apply
	$WebApp.WebConfigModifications.Add( $configModM1 )
	$WebApp.WebConfigModifications.Add( $configModR1 )
		
        
    $WebApp.Update()
    $WebApp.Parent.ApplyWebConfigModifications()
  