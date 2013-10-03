param ([string]$WebAppUrl)

### Initialize environment
. .\Init.ps1

function ProvisionPermissions($permissionMapPath){
	Write-Message "Loading permission map file `"$permissionMapPath`"..." "cyan"
	$fso = Get-Item $permissionMapPath -ea SilentlyContinue
	if($fso -eq $null) {
		throw "Permission map file not found at path `"$permissionMapPath`""
	}
	[xml]$permissionMap = Get-Content $permissionMapPath	
	foreach($webAppNode in $permissionMap.PermissionMap.WebApplications.WebApplication) {
		Write-Message "Provisioning permissions for web application at URL: $($webAppNode.Url)..." "cyan"
		foreach($siteNode in $webAppNode.SiteCollections.SiteCollection){
		
			$siteUrl = $null
			if ($WebAppUrl -eq $null -or $WebAppUrl -eq ""){
				$siteUrl = 	$webAppNode.Url + "/" + $webAppNode.ManagedPath + $siteNode.Url
			}
			else{
				#Allowing to pass the web applicaiton url as parameter.
				$siteUrl = 	$WebAppUrl + "/" + $webAppNode.ManagedPath + $siteNode.Url
			}
			
			Write-Message "`tProcessing site collection at URL: $siteUrl..." "cyan"
			$rootWeb = Get-SPWeb $siteUrl -ea Stop
			foreach($groupNode in $siteNode.Groups.Group) {
				$groupName = $groupNode.Name
				$groupNotes = $groupNode.Notes
				$roleToPrincipal = "EmptyMask"
				if($groupNode.RoleToPrincipal -ne $null -and $groupNode.RoleToPrincipal -ne ""){
					$roleToPrincipal = $groupNode.RoleToPrincipal
				}
				
				try {
				
					if ($roleToPrincipal -ne "EmptyMask"){
						Write-Message "`tAdding group `"$groupNotes`" (RoleToPrincipal=$roleToPrincipal) to site collection..." "cyan"
					}
					
					if($roleToPrincipal -ne $null -and $roleToPrincipal -ne "EmptyMask"){
					
						$group = Create-Group $groupName $rootWeb					
						 
						#Defined in SharePointFunctions.ps1
						Assign-RoleToPrincipal	-roleName $roleToPrincipal `
												-principal $group `
												-web $rootWeb					
					}					
				} catch {
					Write-Message "`tFailed to create group `"$groupNotes`". Original error: $_" "red"
				}				
					if($groupNode.UniqueRoleAssignments -ne $null -and $groupNode.UniqueRoleAssignments.AssignedToElement -ne $null){
						foreach($uniqueRoleAssignment in $groupNode.UniqueRoleAssignments.AssignedToElement) {
							$elementName = $uniqueRoleAssignment.Name							
							$elementType = $uniqueRoleAssignment.Type
							$oldRoleToPrincipal = $uniqueRoleAssignment.OldRoleToPrincipal
							$newRoleToPrincipal = $uniqueRoleAssignment.NewRoleToPrincipal
							
							Write-Message "`tSetting unique permissions to `"$elementName`" from its parent..." "cyan"
							
							if ($elementType -eq "List"){
								if ($newRoleToPrincipal -ne $null -and $newRoleToPrincipal -ne ""){
									#Add the role, before removing role as single role containment drops the group
									Add-SPPermissionToListGroup		-url $rootWeb.Url `
																	-ListName $elementName `
																	-GroupName $groupName `
																	-PermissionLevel $newRoleToPrincipal															
								}
								
								#Remove the previuos role
								Remove-SPPermisssionFromListGroup 	-url $rootWeb.Url `
																	-ListName $elementName `
																	-GroupName $groupName `
																	-PermissionLevel $oldRoleToPrincipal																			
							}
							if ($elementType -eq "Site"){
								if ($newRoleToPrincipal -ne $null -and $newRoleToPrincipal -ne ""){
									#Add the role, before removing role as single role containment drops the group
									Add-SPPermissionToWebGroup		-url $rootWeb.Url `
																	-GroupName $groupName `
																	-PermissionLevel $newRoleToPrincipal
																	
									Remove-SPPermisssionFromWebGroup 	-url $rootWeb.Url `
																		-ListName $elementName `
																		-GroupName $groupName `
																		-PermissionLevel $oldRoleToPrincipal
								}
							}
						}
					}				
				}				
			$rootWeb.Dispose()
		}
	}
}

function Add-SPPermissionToWebGroup  
{
	param ($Url, $GroupName, $PermissionLevel)  
 	$web = Get-SPWeb -Identity $Url  
	
	if ($web -ne $null)  
 	{  
  		if ($web.HasUniqueRoleAssignments -eq $False)  
  		{  
   			$web.BreakRoleInheritance($True)  
  		}  
  		 
	   if ($web.SiteGroups[$GroupName] -ne $null)  
	   {  
			$group = $web.SiteGroups[$GroupName]  
			$roleAssignment = new-object Microsoft.SharePoint.SPRoleAssignment($group)  
			$roleDefinition = $web.RoleDefinitions[$PermissionLevel];  
			$roleAssignment.RoleDefinitionBindings.Add($roleDefinition);  
			$web.RoleAssignments.Add($roleAssignment)  
			$web.Update();		    
	   }  
	   else  
	   {  
	    	Write-Host "Group $GroupName does not exist." -foregroundcolor Red  
	   }
 	}  
 	$web.Dispose()
}

function Remove-SPPermisssionFromWebGroup  
{
	param ($Url, $GroupName, $PermissionLevel)  
    $web = Get-SPWeb -Identity $Url  
    
	if ($web.HasUniqueRoleAssignments -eq $False)  
	{  
		$web.BreakRoleInheritance($True)  
	}
	
	if ($web.SiteGroups[$GroupName] -ne $null)  
	{
		$group = $web.SiteGroups[$GroupName]
		$roleAssign = $web.RoleAssignments.GetAssignmentByPrincipal($group);
		$roleDefinition = $web.RoleDefinitions[$PermissionLevel];
		$roleAssign.RoleDefinitionBindings.Remove($roleDefinition);
		$roleAssign.Update();
		$web.Update();			
	}
	else
	{  
		Write-Message "`tFailed to find group `"$GroupName`". Original error: $_" "red"
	}
    
    $web.Dispose()
}

function Add-SPPermissionToListGroup  
{
	param ($Url, $ListName, $GroupName, $PermissionLevel)  
 	$web = Get-SPWeb -Identity $Url  
		
 	$list = $web.Lists.TryGetList($ListName)  

	if ($list -ne $null)  
 	{  
  		if ($list.HasUniqueRoleAssignments -eq $False)  
  		{  
   			$list.BreakRoleInheritance($True)  
  		}  
  		 
	   if ($web.SiteGroups[$GroupName] -ne $null)  
	   {  
			$group = $web.SiteGroups[$GroupName]  
			$roleAssignment = new-object Microsoft.SharePoint.SPRoleAssignment($group)  
			$roleDefinition = $web.RoleDefinitions[$PermissionLevel];  
			$roleAssignment.RoleDefinitionBindings.Add($roleDefinition);  
			$list.RoleAssignments.Add($roleAssignment)  
			$list.Update();		    
	   }  
	   else  
	   {  
	    	Write-Host "Group $GroupName does not exist." -foregroundcolor Red  
	   }
 	}  
 	$web.Dispose()
}

function Remove-SPPermisssionFromListGroup  
{
	param ($Url, $ListName, $GroupName, $PermissionLevel)  
    $web = Get-SPWeb -Identity $Url  
    $list = $web.Lists.TryGetList($ListName)  
    if ($list -ne $null)  
    {
		if ($list.HasUniqueRoleAssignments -eq $False)  
		{  
			$list.BreakRoleInheritance($True)  
		}
		
		if ($web.SiteGroups[$GroupName] -ne $null)  
		{
			$group = $web.SiteGroups[$GroupName]
			$roleAssign = $list.RoleAssignments.GetAssignmentByPrincipal($group);
			$roleDefinition = $web.RoleDefinitions[$PermissionLevel];
			$roleAssign.RoleDefinitionBindings.Remove($roleDefinition);
			$roleAssign.Update();
			$list.Update();			
		}
		else
		{  
			Write-Message "`tFailed to find group `"$GroupName`". Original error: $_" "red"
		}
    }
    else  
    {  
      Write-Message "`tFailed to find list `"$ListName`". Original error: $_" "red"
    }      
    $web.Dispose()
}

### Begin script execution here.
Write-Message  "`r`n***  Script for provisioning permissions on OPA.Settlement.Portal sites ***`r`n" "cyan"
Write-Message "Log file name: $Log" "white" $false
try {
	ProvisionPermissions "$ApplicationScriptsFolder\EnvironmentSpecific\PermissionMap.xml"
	exit 0
} catch {
    Write-Message "Failed to provision permissions. Error message: `"$_`"" "red"
	exit -1
}