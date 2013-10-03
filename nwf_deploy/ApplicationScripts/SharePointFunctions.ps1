###############################################################################
# Normalizes a URL by removing a trailing slash
###############################################################################
function Normalize-Url($url){
	$rootUrl = $null
	if($url.EndsWith("/") -eq $true) {
		$rootUrl = $url.Remove($url.Length - 1)
	} else {
		$rootUrl = $url
	}	
	return $rootUrl
}

###############################################################################
# Deploys a given solution.
###############################################################################
function Deploy-Solution($solutionPath, [string[]]$webAppUrls = $null) {  
    $packageFileName = [System.IO.Path]::GetFileName($solutionPath)
    if(-not (Test-Path -path $solutionPath -pathType leaf)) {
        throw "Solution package was not found at path `"$solutionPath`""
    }
    $solutions = @(Get-SPSolution | Where-Object { $_.Name -eq $packageFileName })
    if(-not $solutions.Count -eq 0) {
        Write-Message "Solution `"$packageFileName`" is already installed in the farm." "yellow"
        return
    }
    
    try {
        Write-Message "Adding solution `"$packageFileName`" to store..." "cyan"
        $solution = Add-SPSolution $solutionPath -ea Stop -confirm:$false                
		$deployToGac = $solution.ContainsGlobalAssembly
		$deployCasPolicy = $solution.ContainsCasPolicy
		Write-Message "Installing solution `"$packageFileName`" (deployToGac=$deployToGac, deployCasPolicy=$deployCasPolicy, webAppUrls: $webAppUrls)..." "cyan"

		if(($webAppUrls -eq $null) -and ($solution.ContainsWebApplicationResource -eq $false)) {
			$solution | Install-SPSolution -Force -GacDeployment:$deployToGac -CASPolicies:$deployCasPolicy -ea Stop -confirm:$false    
			WaitForSolution $solution "installing"
        } elseif (($webAppUrls -ne $null) -and ($solution.ContainsWebApplicationResource -eq $false)) {
			Write-Message "Solution `"$packageFileName`" does not contain web application-scoped resources. Ignoring provided URLs $webAppUrls..." "yellow"
			$solution | Install-SPSolution -Force -GacDeployment:$deployToGac -CASPolicies:$deployCasPolicy -ea Stop -confirm:$false    
			WaitForSolution $solution "installing"
        } elseif (($webAppUrls -ne $null) -and ($solution.ContainsWebApplicationResource -eq $true)) {
			foreach($webAppUrl in $webAppUrls){
				$solution | Install-SPSolution -Force -GacDeployment:$deployToGac -CASPolicies:$deployCasPolicy -ea Stop -confirm:$false -WebApplication $webAppUrl 
				WaitForSolution $solution "installing"
			}
		} else {
			throw "Solution `"$packageFileName`" contains web application-scoped resources but application URL(s) was not provided."
        }
    } catch {
        throw "Failed to deploy solution $packageFileName. Error message: `"$_`""
    }    
}

###############################################################################
# Installs an existing solution.
###############################################################################
function Install-Solution($solutionName, [string[]]$webAppUrls = $null){
    $solutions = @(Get-SPSolution | Where-Object { $_.Name -eq $solutionName })
    if($solutions.Count -lt 1) {
        Write-Message "Solution `"$solutionName`" was not found. No action taken." "yellow"
        return
    }
	$solution = $solutions[0]
	$deployToGac = $solution.ContainsGlobalAssembly
	$deployCasPolicy = $solution.ContainsCasPolicy
	Write-Message "Installing solution `"$solutionName`" (deployToGac=$deployToGac, deployCasPolicy=$deployCasPolicy, webAppUrls: $webAppUrls)..." "cyan"
	if(($solution.Deployed) -and ($solution.ContainsWebApplicationResource -eq $false)) {
        Write-Message "Solution `"$solutionName`" is already deployed. No action taken." "yellow"
		return
	}
	if(($webAppUrls -eq $null) -and ($solution.ContainsWebApplicationResource -eq $false)) {
		$solution | Install-SPSolution -Force -GacDeployment:$deployToGac -CASPolicies:$deployCasPolicy -ea Stop -confirm:$false    
		WaitForSolution $solution "installing"
    } elseif (($webAppUrls -ne $null) -and ($solution.ContainsWebApplicationResource -eq $false)) {
		Write-Message "Solution `"$packageFileName`" does not contain web application-scoped resources. Ignoring provided URLs $webAppUrls..." "yellow"
		$solution | Install-SPSolution -Force -GacDeployment:$deployToGac -CASPolicies:$deployCasPolicy -ea Stop -confirm:$false    
		WaitForSolution $solution "installing"
    } elseif (($webAppUrls -ne $null) -and ($solution.ContainsWebApplicationResource -eq $true)) {
		foreach($webAppUrl in $webAppUrls){
			$isDeployed = $false
			if($solution.Deployed){
				$webApp = Get-SPWebApplication $webAppUrl
				foreach($wa in $solution.DeployedWebApplications){
					if($webApp.Id -eq $wa.Id){
						$isDeployed = $true
						break
					}
				}
			}
			if($isDeployed){
		        Write-Message "Solution `"$solutionName`" is already deployed to URL $webAppUrl. Deployment to this URL is skipped." "yellow"
				continue
			}
			$solution | Install-SPSolution -Force -GacDeployment:$deployToGac -CASPolicies:$deployCasPolicy -ea Stop -confirm:$false -WebApplication $webAppUrl 
			WaitForSolution $solution "installing" $webApp
		}
	} else {
		throw "Solution `"$solutionName`" contains web application-scoped resources but application URL(s) was not provided."
    }
}

###############################################################################
# Waits for a solution to install or uninstall - private method.
###############################################################################
function WaitForSolution($solution, $action, $webApp = $null){
        $i = 0
        $attempts = $SolutionInstallRetryAttempts
        $sleepDelay = $SolutionInstallSleepDelay		
		$exitCondition = $null
		$messageVariable = $null
		if($action -eq "installing"){
			$exitCondition = '($solution.Deployed -eq $true)'
			$messageVariable = "installation"
			if($webApp -ne $null){
				$exitCondition = '((@($solution.DeployedWebApplications | ? {$_.Id -eq $webApp.Id})).Length -eq 1)'
			}
		}elseif( $action -eq "uninstalling"){
			$exitCondition = '($solution.Deployed -eq $false)'
			$messageVariable = "uninstall"
			if($webApp -ne $null){
				$exitCondition = '((@($solution.DeployedWebApplications | ? {$_.Id -eq $webApp.Id})).Length -eq 0)'
			}
		} else {
			throw "WaitForSolution: unknown action `"$action`""
		}
    
        while ($i -lt $attempts) {
			$exitConditionResult = Invoke-Expression $exitCondition
            if($exitConditionResult){
                Start-Sleep -Seconds $sleepDelay
                break
            }			
            $i++            
            if($i -lt $attempts) {
                Write-Message "Waiting for solution `"$($solution.Name)`" $messageVariable to complete. Check $i of $attempts. Checking again in $sleepDelay seconds..." "yellow"
                Start-Sleep -Seconds $sleepDelay
            } else {
                throw "Timed out waiting for solution $messageVariable to complete."
            }
        }
}

###############################################################################
# Removes a solution from the system.
###############################################################################
function Undeploy-Solution($packageFileName) {  
    $solution = $null
    try {
        $solution = Get-SPSolution -Identity $packageFileName -ea Stop
    } catch {
        Write-Message "Solution `"$packageFileName`" does not exist in the farm. No action taken." "yellow"
        return
    }
    
    if($solution.Deployed) {
        try {
            Write-Message "Uninstalling solution `"$packageFileName`"..." "cyan"
            if($solution.ContainsWebApplicationResource) {
				Uninstall-SPSolution $solution -AllWebApplications -ea Stop -confirm:$false
            } else {
                Uninstall-SPSolution $solution -ea Stop -confirm:$false
            }
			WaitForSolution $solution "uninstalling"
        } catch {
            throw "Failed to uninstall solution $packageFileName. Error message: `"$_`""
        }    
    }

    Write-Message "Removing solution `"$packageFileName`"..." "cyan"
    $i = 0
    $attempts = $SolutionInstallRetryAttempts
    $sleepDelay = $SolutionInstallSleepDelay
    while ($i -lt $attempts) {
        try {
                Remove-SPSolution -Identity $packageFileName -ea Stop -confirm:$false
        } catch {
            $solutions = @(Get-SPSolution | Where-Object { $_.Name -eq $packageFileName })    
            if($solutions.Count -eq 0) {
                break
            }
            $i++            
            if($i -lt $attempts) {
                Write-Message "Waiting for solution `"$packageFileName`" removal to complete. Check $i of $attempts. Checking again in $sleepDelay seconds..." "yellow"
                Start-Sleep -Seconds $sleepDelay
            } else {
                throw "Solution `"$packageFileName`" failed to remove on $i of $attempts."
            }
        }
    }	    
}

###############################################################################
# Uninstalls a solution but doesn't remove it from the store.
###############################################################################
function Uninstall-Solution ($solutionName, [string[]]$webAppUrls = $null){
    $solutions = @(Get-SPSolution | Where-Object { $_.Name -eq $solutionName })
    if($solutions.Count -lt 1) {
        Write-Message "Solution `"$solutionName`" was not found. No action taken." "yellow"
        return
    }
	$solution = $solutions[0]
	Write-Message "Uninstalling solution `"$solutionName`" (webAppUrls to uninstall from (empty means 'all'): $webAppUrls)..." "cyan"
	if((-not $solution.Deployed)) {
        Write-Message "Solution `"$solutionName`" is not deployed. Nothing to uninstall." "yellow"
		return
	}
	if($solution.ContainsWebApplicationResource -eq $false) {
		Uninstall-SPSolution $solution -ea Stop -confirm:$false    
		WaitForSolution $solution "uninstalling"
    } elseif (($webAppUrls -eq $null)) {
		Uninstall-SPSolution $solution -AllWebApplications -ea Stop -confirm:$false
		WaitForSolution $solution "uninstalling"
    } else {
		foreach($webAppUrl in $webAppUrls){
			$isDeployed = $false
			$webApp = Get-SPWebApplication $webAppUrl
			foreach($wa in $solution.DeployedWebApplications){
				if($webApp.Id -eq $wa.Id){
					$isDeployed = $true
					break
				}
			}
			if($isDeployed){
		        Write-Message "Uninstalling solution `"$solutionName`" from web application $webAppUrl..." "white"
				Uninstall-SPSolution $solution -WebApplication $webApp -ea Stop -confirm:$false
				WaitForSolution $solution "uninstalling" $webApp
			} else {
		        Write-Message "Solution `"$solutionName`" is not deployed to web application $webAppUrl" "yellow"
			}
		}
	}
}

###############################################################################
# Creates a new site collection (SPSite).
###############################################################################
function Create-SiteCollection($url, $name, $templateName, $contentDatabase) {
    Write-Message "Creating site collection at URL: `"$url`"..." "cyan"	
	$site = Get-SPSite | Where-Object {$_.Url -eq $url} -ea:SilentlyContinue
	if($site -ne $null) {
	    Write-Message "Site collection at URL `"$url`" already exists. Site collection creation skipped." "yellow"
		return
	}
	if(($url -eq [string]::Empty) -or ($url -eq $null)){
		throw "Cannot create site collection. URL cannot be empty."
	}

    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    
	try{
		$output = $null
		$contentDbName = "default"
		if($contentDatabase -ne $null) {
			$contentDbName = $contentDatabase.Name
			$output = New-SPSite $url -ContentDatabase $contentDatabase -owneralias "$($currentUser.Name)" -Name $name -Template $templateName -ea Stop | Out-String -Width 255
		} else {
			$output = New-SPSite $url -owneralias "$($currentUser.Name)" -Name $name -Template $templateName -ea Stop | Out-String -Width 255
		}
		Write-Message $output "white"
	}catch{
		$message = "Failed to create site collection at URL $url using template $templateName for owner $($currentUser.Name) and $contentDbName content database. Original error: $_"
		if($_ -like "*0x80070057*"){
			$message += "`r`nSome possible causes:`r`n`ta) system cannot resolve owner alias (are you disconnected from AD domain?);`r`n`tb) host portion of site collection URL does not match web application URL (are you using 'localhost'?)"
		}
		throw $message	
	}
}

###############################################################################
# Deletes a site collection.
###############################################################################
function Delete-SiteCollection($url) {
    Write-Message "Removing site collection at URL: `"$url`"..." "cyan"
	if(($url -eq [string]::Empty) -or ($url -eq $null)){
		throw "Cannot delete site collection. URL cannot be empty."
	}
	$site = Get-SPSite $url -ea:SilentlyContinue
	if($site -eq $null) {
	    Write-Message "Site collection at URL `"$url`" not found - nothing to delete." "yellow"
		return
	}
    Remove-SPSite -Identity "$url" -GradualDelete -Confirm:$False -ea Stop
    Write-Message "Site collection removal will complete asynchronously.`r`n" "cyan"
}

###############################################################################
# Creates a new web site (SPWeb).
###############################################################################
function Create-Web($url, $name, $templateName) {
    Write-Message "Creating web site at URL: `"$url`"..." "cyan"
	$web = Get-SPWeb $url -ea:SilentlyContinue
	if($web -ne $null) {
	    Write-Message "Web site at URL `"$url`" already exists. Web site creation skipped." "yellow"
		return
	}
	if(($url -eq [string]::Empty) -or ($url -eq $null)){
		throw "Cannot create web site. URL cannot be empty."
	}

    $output = New-SPWeb $url -name $name -template $templateName -ea Stop | Out-String -Width 255
    Write-Message $output "white"
}

###############################################################################
# Gets a managed path.
###############################################################################
function Get-ManagedPath($name, $webAppUrl, $isExplicit) {
    $paths = Get-SPManagedPath -WebApplication $webAppUrl
	$matches = $null
	if($isExplicit -eq $true){
    	$matches = @($paths | Where-Object {$_.Name -eq $name -and $_.PrefixType -eq "ExplicitInclusion"})
	} elseif($isExplicit -eq $false) {
    	$matches = @($paths | Where-Object {$_.Name -eq $name -and $_.PrefixType -eq "WildcardInclusion"})
	} else {
    	$matches = @($paths | Where-Object {$_.Name -eq $name})
	}
    $path = $null
    if($matches.Count -eq 1) {
        $path = $matches[0]	
    } else {
        if($matches.Count -eq 0) {
            $path = $null		
        } else {
            throw "More than one managed path match provided name: `"$name`"."
        }
    }
    $path
}

###############################################################################
# Creates a new managed path.
###############################################################################
function Create-ManagedPath($name, $webAppUrl, [bool]$isExplicit) {
    Write-Message "Creating managed path `"$name`" for web application `"$webAppUrl`" (Explicit=$isExplicit)..." "cyan"
    $path = Get-ManagedPath $name $webAppUrl

    if($path -ne $null) {
        Write-Message "$($path.PrefixType) Managed path `'$name`' already exists for web application `"$webAppUrl`"." "yellow"
    } else {
        $output = New-SPManagedPath $name -WebApplication $webAppUrl -Explicit:$isExplicit | Out-String -Width 255 -Stream
        $output | % { Write-Message $_ "white" }	
    }
}

###############################################################################
# Activates a feature.
###############################################################################
function Activate-Feature($featureName, $url, $abortOnError) {
    Write-Message "Activating feature $featureName at URL: $url ..." "cyan"
    $feature = $null
    
    try {
        $feature = Get-SPFeature -Identity $featureName -ea Stop
    } catch {
        throw "Feature `"$featureName`" was not found. Original error message: $_"
    }

    try {
        $output = Enable-SPFeature $feature -Url $url -confirm:$false -ea Stop | Out-String -Width 255 -Stream
        $output | % { Write-Message $_ "white" }
    } catch {
        if($_ -like "*already activated*") {
            Write-Message "Warning: Feature was not activated. Original message: $_" "yellow"
			return
        } else {
            if($abortOnError) {
                throw $_
            } else {
                Write-Message "Feature was not activated. Original error message: $_" "red"
				return
            }
        }
    }
}

###############################################################################
# De-Activates a feature.
###############################################################################
function Deactivate-Feature($featureName, $url, $abortOnError) {
    Write-Message "Deactivating feature $featureName at URL: $url ..." "cyan"
    $feature = $null
    
    try {
        $feature = Get-SPFeature -Identity $featureName -ea Stop
    } catch {
        throw "Feature `"$featureName`" was not found. Original error message: $_"
    }

    try {
        $output = Disable-SPFeature $feature -Url $url -confirm:$false -ea Stop | Out-String -Width 255 -Stream
        $output | % { Write-Message $_ "white" }
    } catch {
        if($_ -like "*deactivated*") {
            Write-Message "Warning: Feature was not deactivated. Original message: $_" "yellow"
			return
        } else {
            if($abortOnError) {
                throw $_
            } else {
                Write-Message "Feature was not deactivated. Original error message: $_" "red"
				return
            }
        }
    }
}

###############################################################################
# Restarts all SharePoint-related services.
###############################################################################
function Restart-AllServices() {
    Write-Message "Stopping SharePoint Administration Service..." "white"
    Stop-Service "SPAdminV4" | Out-Null
    Write-Message "Stopping SharePoint Timer Service..." "white"
    Stop-Service "SPTimerV4" | Out-Null

    Write-Message "Resetting IIS..." "white"
    Stop-Service "W3Svc" | Out-Null
    Stop-Service "IISAdmin" | Out-Null
    Start-Service "IISAdmin" | Out-Null
    Start-Service "W3Svc" | Out-Null

    iisreset | Out-Null
    $code = $LASTEXITCODE
    
    if($code -ne 0){
        Write-Message "Resetting IIS has failed." "red"
    }

    Write-Message "Starting SharePoint Timer Service..." "white"
    Start-Service "SPTimerV4" | Out-Null
    Write-Message "Executing admin jobs..." "white"
	Start-SPAdminJob -Verbose
    Write-Message "Starting SharePoint Admin Service..." "white"
    Start-Service "SPAdminV4" | Out-Null
}

###############################################################################
# Adds role definition given its name to principal's role definition binding.
###############################################################################
function Assign-RoleToPrincipal($roleName, $principal, $web) {	
	if($principal -eq $null) {
		throw "Argument error: Principal cannot be null."
	}
	Write-Message "Assigning role `"$roleName`" to principal `"$($principal.Name)`"..." "cyan"
	$roleDefinition = $web.RoleDefinitions[$roleName]
	if($roleDefinition -eq $null) {
		throw "Cannot find role definition named `"$rolename`" on web $($web.Url)."
	}
	$assignment = $null
	foreach($a in $web.RoleAssignments) {
		if ($a.Member.Name -eq $principal.Name) {
			$assignment = $a
			break
		}
	}
	if($assignment -eq $null) {
	    $assignment = New-Object Microsoft.SharePoint.SPRoleAssignment $principal
		$assignment.RoleDefinitionBindings.Add($roleDefinition)
		$web.RoleAssignments.Add($assignment)
	} else {
		foreach($b in $assignment.RoleDefinitionBindings) {
			if($b.Name -eq $roleName) {
				Write-Message "Role `"$roleName`" is already bound to principal `"$($principal.Name)`"." "yellow"
				return
			}
		}
		$assignment.RoleDefinitionBindings.Add($roleDefinition)
	}
	$principal.Update()
}

###############################################################################
# Gets a specific group.
###############################################################################
function Get-Group ($name, $web) {
    $group = $null
    try {
        $group = $web.SiteGroups["$name"];
    } catch {
        # Do nothing.
    }
    $group
}

###############################################################################
# Creates a SharePoint security group.
###############################################################################
function Create-Group($groupName, $web) {
    Write-Message "Creating group `'$groupName`' on web site `'$($web.Url)`'..." "cyan"		
    try {
        $group = Get-Group $groupName $web

        if($group -ne $null) {
            Write-Message "Group `'$groupName`' already exists on web site `'$($web.Url)`'." "yellow"		
        } else {
            $account = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
            $user = $web.Users["$account"]
            
            if($user -eq $null) {
                # Fall back to site collection owner. This occurs with site collections based on Enterprise Search template.
                $user = $web.Site.Owner
            }
            
            $web.SiteGroups.Add($groupName, $user, $user, "System-created group.")
            $group = Get-Group $groupName $web
        }
        $group
    } catch {
        throw "Failed to create group `"$groupName`" owned by `"$account`" on web site `"$($web.Url)`". Error message: `"$_`""
    }
}

###############################################################################
# Creates a managed metadata site column in a site collection.
###############################################################################
function Create-ManagedMetadataSiteColumn(
	$siteUrl, 
	$termStoreGroupName, 
	$termSetName, 
	$fieldName, 
	$fieldGroupName, 
	$required, 
	$allowMultiValues,
	[string]$defaultValue) {
	if($siteUrl -eq $null) {
		throw "Argument error: Site url cannot be null."
	}

    Write-Message "Creating managed metadata field `"$fieldName`" in site collection `"$siteUrl`"..." "cyan"
	$site = get-spsite -Identity $siteUrl	
	$spWeb = $site.OpenWeb()

	$session = get-sptaxonomysession -site $site
	$termstore = $session.termstores[0]
	if($termstore -eq $null){
		throw "Term store not found."
	}
	$termGroup = $termstore.groups[$termStoreGroupName]
	if($termGroup -eq $null){
		throw "Term store group named `"$termStoreGroupName`" not found."
	}
	$termSet = $termGroup.TermSets[$termSetName]
	if($termSet -eq $null){
		throw "Term set with name `"$termSetName`" not found."
	}
	if($spWeb.Fields.ContainsField($fieldName)) {
        Write-Message "Field with the name `"$fieldName`" already exists in site collection `"$siteurl`". Field creation skipped." "yellow"
		$site.Dispose()
		return
	}

	$field = $spWeb.Fields.CreateNewField("TaxonomyFieldType", $fieldName);
	$field.SSPId = $termstore.Id
	$field.TermsetId = $termSet.Id
	$field.AllowMultipleValues = $allowMultiValues
	$field.Group = $fieldGroupName
	$field.Required = $required	
	if(-not [string]::IsNullOrEmpty($defaultValue)) {
		$term = $null
		try{
			$term = $termSet.Terms["$defaultValue"]
		} catch {
			throw "Cannot find a term by a default label `'$defaultValue`' in term set `'$($termSet.Name)`'. Original error: $_"
		}
		$defaultTaxValue = New-Object "Microsoft.SharePoint.Taxonomy.TaxonomyFieldValue" -ArgumentList $field
		$defaultTaxValuePair = "$defaultValue|$($term.Id.ToString())"
		$defaultTaxValue.PopulateFromLabelGuidPair($defaultTaxValuePair)
		$defaultTaxValue.WssId = -1
		# Need the line below for compatibility with Office 2010.
		$defaultTaxValue.TermGuid = $defaultTaxValue.TermGuid.ToLower()		
		$field.DefaultValue = $defaultTaxValue.ValidatedString
	}
	$spWeb.Fields.Add($field)
	$spWeb.Update()
	$site.Dispose()
}

###############################################################################
# Adds a new content type to a site collection.
###############################################################################
function Add-NewContentType([string]$siteUrl, 
							[string]$parentContentTypeName, 
							[string]$newContentTypeName, 
							[string]$description, 
							[string]$fieldGroup, 
							[string[]] $columnsToAdd){
	Write-Message "Adding content type `"$newContentTypeName`"..." "cyan"
	$site = Get-SPSite $siteUrl
	if($site -eq $null) {
		throw "siteUrl `"$siteUrl`" does not point to a valid site."
	}  
  	$rootWeb = $site.RootWeb
	$fields = $rootWeb.Fields
	foreach($column in $columnsToAdd){
		if($fields.ContainsField($column) -ne $true){
			throw "Cannot create content type `"$newContentTypeName`": field `"$column`" is not found."
		}
	}
	$thisCT = $rootWeb.ContentTypes[$newContentTypeName]
	if($thisCT -ne $null){
		Write-Message "Content type `"$newContentTypeName`" already exists in site collection `"$siteUrl`"." "yellow"
		return
	}

  	$parentContentType = $rootWeb.ContentTypes[$parentContentTypeName]
  	$ct = New-Object Microsoft.SharePoint.SPContentType -ArgumentList @($parentContentType, 
																		$rootWeb.ContentTypes, 
																		$newContentTypeName)
	$ct.Description = $description
	$ct.Group = $fieldGroup
	$rootWeb.ContentTypes.Add($ct)    	
	foreach($column in $columnsToAdd){
		Write-Message "`tAdding field `"$column`" to content type `"$newContentTypeName`"..." "white"
	  	$field = $fields.GetField($column)
		$link = New-Object Microsoft.SharePoint.SPFieldLink -ArgumentList $field
		$ct.FieldLinks.Add($link)
	}
	$swallowedOutput = $ct.Update() 2>&1	
	$site.Dispose()
}

###############################################################################
# Creates a site column from field XML.
###############################################################################
function Create-SiteColumnFromXML($siteurl, $fieldXml) {
	if($siteurl -eq $null) {
		throw "Argument error: Site url cannot be null."
	}

	$site = get-spsite -Identity $siteurl	
	$spWeb = $site.OpenWeb()

	# See field XML on console
	Write-Message  $fieldXml "yellow"
	$spWeb.Fields.AddFieldAsXml($fieldXml)	
	$spWeb.update()
}

###############################################################################
# Writes a message to the output and to the log file.
###############################################################################
function Write-Message ($message, $foregroundColor, $writeToLog = $true) {
    if($message -ne $null) {
        Write-Host $message -foregroundcolor $foregroundColor
        
        if($writeToLog -eq $true) {
            $stamp = Get-Date -format "yyyy-MM-dd HH:mm:ss"
            $stampedMessage = $stamp + "  " + $message
            $stampedMessage | Out-File -FilePath $Log -Width 255 -Append -Force
        }
    }
}

###############################################################################
# Changes a title on a given list or a document library.
###############################################################################
function Rename-List ($listTitle, $newTitle, $webUrl) {
	Write-Message "Renaming list `"$listTitle`" to `"$newTitle`" on web $webUrl..." "cyan"
	$web = Get-SPWeb $webUrl
	if($web -eq $null){
		throw "No web found for URL $webUrl"
	}	
	$list = $web.Lists[$listTitle]
	if($list -eq $null){
		throw "No list with title `"$listTitle`" found on web $webUrl." 
	}
	$list.Title = $newTitle
	$list.Update()
}

###############################################################################
# Creates New List with Name and SPListTemplateType
###############################################################################
function Create-NewList($siteUrl, $spListTemplateType, $listTitle, $listUrl, $listDescription, $onQuickLaunch, $contentTypesEnabled = $true){

	if($siteurl -eq $null) {
		throw "Argument error: Site url cannot be null."
	}
	
	$spWeb = Get-SPWeb $siteUrl	

	if($spWeb -ne $null){
		#Get the list in this site
		$list = $spWeb.Lists[$listTitle]
		
		if ($list -eq $null){
			$spWeb.Lists.Add($listUrl, $listDescription, $spListTemplateType)
			$list = $spWeb.Lists[$listUrl]
			$list.Title = $listTitle
			$list.OnQuickLaunch = $onQuickLaunch
			$list.ContentTypesEnabled = $contentTypesEnabled
			$list.AllowDeletion = $true
			$list.Update()
			$spWeb.Dispose()			
			Write-Message "A list or document library with the title '$listTitle' has been provisioned successfully to the site '$spWeb'." "Green"
		}
		else
		{			
			Write-Message "A list or document library with the title '$listTitle' already exists in site '$spWeb'. Please choose another title." "DarkCyan"			
		}		
	}
}

###############################################################################
# Binds content types to a list
###############################################################################
function Bind-ContentTypesToList($webUrl, $listName, [string[]]$contentTypeNames){
	Write-Message "Binding content types `"$contentTypeNames`" to list `"$listName`" on site `"$webUrl`"..." "cyan"
	$web = Get-SPWeb $webUrl	
	if($web -eq $null) {
		$web.Dispose()
		throw "Web not found at URL `"$webUrl`""
	}	
	$list = $web.Lists[$listName]	
	if ($list -eq $null){
		$web.Dispose()
		throw "List `"$listName`" not found on the site `"$webUrl`"."	
	}
	$list.ContentTypesEnabled = $true
	$rootWeb = $web.Site.RootWeb
	foreach($contentTypeName in $contentTypeNames) {
		$ct = $rootWeb.AvailableContentTypes[$contentTypeName]
		if($ct -eq $null) {
			throw "Content type `"$contentTypeName`" not found."
		}		
		if($list.IsContentTypeAllowed($ct) -ne $true){
			Write-Message "List `"$listName`" on the site `"$webUrl`" is not compatible with content type `"$contentTypeName`". Binding was skipped." "yellow"
			continue
		} 
		$matchId = $list.ContentTypes.BestMatch($ct.Id)
		if($ct.Id.IsParentOf($matchId)){
			Write-Message "List `"$listName`" on the site `"$webUrl`" is already bound to `"$contentTypeName`" content type. Binding was skipped." "yellow"
			continue
		}		
		$list.ContentTypes.Add($ct)		
	}
	$swallowedOutput = $list.Update() 2>&1
	$web.Dispose()
	$rootWeb.Dispose()
}

###############################################################################
# Creates a new content database.
###############################################################################
function Create-NewContentDatabase($webAppUrl, $dbName){
	Write-Message "Creating new content database with name `"$dbName`"..." "cyan"
	$db = Get-SPContentDatabase $dbName	-ea:SilentlyContinue
	if($db -ne $null){
		Write-Message "Content database with name `"$dbName`" already exists." "yellow"
	} else {
		$db = New-SPContentDatabase -Name $dbName `
									-WebApplication $webAppUrl `
									-ea:Stop
	}
	return $db
}

###############################################################################
# Permanently deletes a content database.
###############################################################################
function Delete-ContentDatabase($dbName, [bool]$silently){
	Write-Message "Deleting content database named `"$dbName`"..." "cyan"
	$db = Get-SPContentDatabase $dbName -ea:SilentlyContinue
	if($db -eq $null){
		Write-Message "Content database with name `"$dbName`" does not exist." "yellow"
	} else {
		if($silently -eq $true){
			$db | Remove-SPContentDatabase -ea:Stop -Confirm:$false -Force			
		}else{
			$db | Remove-SPContentDatabase -ea:Stop -Confirm:$true
		}
	}
}

###############################################################################
# Exports a managed metadata store to a file.
###############################################################################
function Export-ManagedMetadataStore($filePath){
  Write-Message "Exporting managed metadata service application data to file `"$filePath`"..." "cyan"
	if($filePath -eq $null -or $filePath -eq "") {
		throw "Export file path is required."
	}
	$folderPath = [System.IO.Path]::GetDirectoryName($filePath)
	if([System.IO.Directory]::Exists($folderPath) -ne $true){
		Write-Message "A directory `"$folderPath`" does not exist. Creating..." "yellow"
		New-Item -Path $folderPath -type directory -ea:Stop | Out-Null
	}
	$mmsApp = Get-SPServiceApplication | ? {$_.TypeName -eq "Managed Metadata Service"}
	if($mmsApp -eq $null){
		throw "Cannot find a service application of type 'Managed Metadata Service'."
	}
	$mmsProxy = Get-SPServiceApplicationProxy | ? {$_.TypeName -eq "Managed Metadata Service Connection"}
	Export-SPMetadataWebServicePartitionData -Identity $mmsApp.Id -ServiceProxy $mmsProxy -Path $filePath -ea:Stop
}

###############################################################################
# Imports managed metadata store from a file, overwriting its data.
###############################################################################
function Import-ManagedMetadataStore($filePath){
 	Write-Message "Importing managed metadata service application data from file `"$filePath`"..." "cyan"
	if($filePath -eq $null -or $filePath -eq "") {
		throw "Import file path is required."
	}
	if([System.IO.File]::Exists($filePath) -ne $true){
		throw "A file not found at a path `"$filePath`"."
	}
	$mmsApp = Get-SPServiceApplication | ? {$_.TypeName -eq "Managed Metadata Service"}
	if($mmsApp -eq $null){
		throw "Cannot find a service application of type 'Managed Metadata Service'."
	}
	$mmsProxy = Get-SPServiceApplicationProxy | ? {$_.TypeName -eq "Managed Metadata Service Connection"}
  	try{
		Import-SPMetadataWebServicePartitionData 	-Identity $mmsApp.Id `
													-ServiceProxy $mmsProxy `
													-Path $filePath `
													-ea:Stop `
													-OverwriteExisting
	}catch{
		throw "$_. If having permissions issues, see http://blogs.msdn.com/b/taj/archive/2011/03/20/import-spmetadatawebservicepartitiondata-error-in-multi-server-deployment.aspx"
	}
}

###############################################################################
# Updates and returns back a collection of web.config modification objects.
###############################################################################
function Add-WebConfigChange($changes, $path, $name, $value) {
    
    if($changes -eq $null) {
        $changes = @()
    }
    
    $modification = New-Object -TypeName Microsoft.SharePoint.Administration.SPWebConfigModification `
        -ArgumentList $name, $path
    $modification.Sequence = 0;
    $modification.Owner = whoami
    $modification.Type = [Microsoft.SharePoint.Administration.SPWebConfigModification+SPWebConfigModificationType]::EnsureChildNode
    $modification.Value = $value
    
    $changes += $modification
    $changes
}

###############################################################################
# Applies configuration changes to admin or content web service application.
###############################################################################
function Apply-WebConfigChanges($changes, $isAdmin = $false){
    $service = $null
    if($isAdmin -eq $true) {
        $service = [Microsoft.SharePoint.Administration.SPWebService]::AdministrationService
    } else {
        $service = [Microsoft.SharePoint.Administration.SPWebService]::ContentService
    }
    $service.WebConfigModifications.Clear()
    $changes | ForEach-Object { $service.WebConfigModifications.Add($_) }
    $service.Update()
    $service.ApplyWebConfigModifications()
    $changes = $null
}
