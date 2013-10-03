	cls
    $WebApp = Get-SPWebApplication http://sp2010riyaz:9050
		
	Write-Output "now adding the entries for sharing sessions between applications"
 
 	$configModM1 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification
	$configModM1.Path = "configuration/system.webServer/modules"
	$configModM1.Name  =  "add[@name='SharedSessionModule']"   
 	$configModM1.Sequence = 0
	$configModM1.Type = 0
	$configModM1.Owner = "OAMSharedSessionModule"
	$configModM1.Value = "<add name='SharedSessionModule' type='DirectEnergy.OAM.Modules.SharedSessionModule, DirectEnergy.OAM, Version=1.0.0.0, Culture=neutral, PublicKeyToken=b6a416a3e4d1c768' />"


	$configModR1 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification
	$configModR1.Path = "configuration/appSettings"
	$configModR1.Name  =  "add[@key='ApplicationName']"   
 	$configModR1.Sequence = 0
	$configModR1.Type = 0
	$configModR1.Owner = "OAMSharedSessionModule"
	$configModR1.Value = "<add key='ApplicationName' value='SharedWeb' />"

		
    # Add mods, update, and apply
	$WebApp.WebConfigModifications.Add( $configModM1 )
	$WebApp.WebConfigModifications.Add( $configModR1 )
		
        
    $WebApp.Update()
    $WebApp.Parent.ApplyWebConfigModifications()
  