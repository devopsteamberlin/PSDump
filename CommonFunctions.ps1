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
			WaitForSolutionToInstall $solution $packageFileName
        } elseif (($webAppUrls -ne $null) -and ($solution.ContainsWebApplicationResource -eq $false)) {
			Write-Message "Solution `"$packageFileName`" does not contain web application-scoped resources. Ignoring provided URLs $webAppUrls..." "yellow"
			$solution | Install-SPSolution -Force -GacDeployment:$deployToGac -CASPolicies:$deployCasPolicy -ea Stop -confirm:$false    
			WaitForSolutionToInstall $solution $packageFileName
        } elseif (($webAppUrls -ne $null) -and ($solution.ContainsWebApplicationResource -eq $true)) {
			foreach($webAppUrl in $webAppUrls){
				$solution | Install-SPSolution -Force -GacDeployment:$deployToGac -CASPolicies:$deployCasPolicy -ea Stop -confirm:$false -WebApplication $webAppUrl 
				WaitForSolutionToInstall $solution $packageFileName
			}
		} else {
			throw "Solution `"$packageFileName`" contains web application-scoped resources but application URL(s) was not provided."
        }
    } catch {
        throw "Failed to deploy solution $packageFileName. Error message: `"$_`""
    }    
}


###############################################################################
# Deploys a given solution.
#Update-SPSolution -Identity contoso_solution.wsp -LiteralPath c:\contoso_solution_v2.wsp -GACDeployment
###############################################################################
function Upgrade-Solution($solutionPath) {  

    $packageFileName = [System.IO.Path]::GetFileName($solutionPath)
    if(-not (Test-Path -path $solutionPath -pathType leaf)) {
        throw "Solution package was not found at path `"$solutionPath`""
    }
    $solutions = @(Get-SPSolution | Where-Object { $_.Name -eq $packageFileName })
    if($solutions.Count -eq 0) {
        Write-Message "Solution `"$packageFileName`" is not found in the farm." "yellow"
        return
    }
    
    try {
        Write-Message "Updating solution `"$packageFileName`" to store..." "cyan"
		Update-SPSolution -Identity $packageFileName -LiteralPath $solutionPath -GACDeployment
        
    } catch {
        throw "Failed to update solution $packageFileName. Error message: `"$_`""
    }    
}

###############################################################################
# Waits for a solution to install - private method, do not call directly.
###############################################################################
function WaitForSolutionToInstall($solution, $packageFileName){
        $i = 0
        $attempts = $SolutionInstallRetryAttempts
        $sleepDelay = $SolutionInstallSleepDelay
    
        while ($i -lt $attempts) {
            if($solution.Deployed){
                Start-Sleep -Seconds $sleepDelay
                break
            }			
            $i++            
            if($i -lt $attempts) {
                Write-Message "Waiting for solution `"$packageFileName`" installation to complete. Check $i of $attempts. Checking again in $sleepDelay seconds..." "yellow"
                Start-Sleep -Seconds $sleepDelay
            } else {
                throw $_                
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

            $i = 0
            $attempts = $SolutionInstallRetryAttempts
            $sleepDelay = $SolutionInstallSleepDelay
    
            while ($i -lt $attempts) {
                if(-not $solution.Deployed){
                    break
                    Start-Sleep -Seconds $sleepDelay
                }			
                $i++            
                if($i -lt $attempts) {
                    Write-Message "Waiting for solution `"$packageFileName`" uninstall to complete. Check $i of $attempts. Checking again in $sleepDelay seconds..." "yellow"
                    Start-Sleep -Seconds $sleepDelay
                } else {
                    Write-Message "Solution `"$packageFileName`" failed to uninstall on $i of $attempts." "red"
                    throw "Uninstall"                
                }
            }
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
# Creates a new site collection (SPSite).
###############################################################################
function Create-SiteCollection($url, $name, $templateName) {
    Write-Message "Creating site collection at URL: `"$url`"..." "cyan"
	$site = Get-SPSite $url -ea:SilentlyContinue
	if($site -ne $null) {
	    Write-Message "Site collection at URL `"$url`" already exists. Site collection creation skipped." "yellow"
		return
	}
	if(($url -eq [string]::Empty) -or ($url -eq $null)){
		throw "Cannot create site collection. URL cannot be empty."
	}

    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    
	try{
		$output = New-SPSite $url -owneralias "$($currentUser.Name)" -name $name -template $templateName -ea Stop | Out-String -Width 255
		Write-Message $output "white"
	}catch{
		$message = "Failed to create site collection at URL $url using template $templateName for owner $($currentUser.Name). Original error: $_"
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
function Get-ManagedPath($name, $webAppUrl) {
    $paths = Get-SPManagedPath -WebApplication $webAppUrl
    $matches = @($paths | Where-Object {$_.Name -eq $name})
    $path = $null

    if($matches.Count -eq 1) {
        $path = $matches[0]	
    } else {
        if($matches.Count -eq 0) {
            $path = $null		
        } else {
            throw "More than a single managed path match provided name: `"$name`"."
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
        Write-Message "Managed path `'$name`' already exists for web application `"$webAppUrl`"." "yellow"
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
        if($_ -like "*activated*") {
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
# Moves the web site to the new location.
###############################################################################
function Move-Site ($web, $moveToLocation, $writeToLog = $true) {
	Write-Message "moving $web to $moveToLocation" "cyan"		
	$w = Get-SPWeb $web 	
    $w.ServerRelativeUrl = $moveToLocation	
	$w.Update()
	Write-Message "Location Update Complete" "cyan"		
}

###############################################################################
# Sets the quick launch property on a list
###############################################################################
function Set-ListQuickLaunch($web, $listUrl, $quickLaunch)
{	
	Write-Message "setting quick launch property on list $listUrl" "cyan"
	$w = Get-SPWeb $web
	$spList = $w.GetList($listUrl)
	$spList.OnQuickLaunch =	$quickLaunch
	$spList.Update()
}

###############################################################################
# Sets the title of the list
###############################################################################
function Set-ListTitle($web, $listUrl, $listTitle)
{	
	Write-Message "setting quick launch property on list $listUrl" "cyan"
	$w = Get-SPWeb $web
	$spList = $w.GetList($listUrl)
	$spList.Title = $listTitle
	$spList.Update()
}

###############################################################################
# Change the title of the site
###############################################################################
function Set-WebTitle($web, $siteTitle)
{	
	Write-Message "Setting the title of the site $web" "cyan"
	$w = Get-SPWeb $web
	$w.Title = $siteTitle
	$w.Update()	
}

###############################################################################
# Upgrades the site scoped feature
###############################################################################
function Upgrade-Feature($site, $featureId)
{	
	Write-Message "Upgrading feature $featureId on site $site" "cyan"
	
	$site = Get-SPSite $site
	$id = [System.GUID]($featureId)
	$ftrCol = $site.QueryFeatures($id, "true")
	foreach($ftr in $ftrCol)
	{		
		$ftr.Upgrade("true")
		Write-Message "Feature $featureId upgraded on site $site" "cyan"
	}		
}

###############################################################################
# Sets the properties of a particular field
###############################################################################
function Set-FieldLinkReadOnly($web, $contentType, $fieldName, $readOnly, $showInDisplayForm, $fieldDisplayName)
{
	Write-Message "Setting field properties for ContentType: $contentType; Field: $fieldName" "cyan"
	
	$w = [Microsoft.SharePoint.SPWeb](Get-SPWeb $web)
	$dummyCount = $w.ContentTypes.Count
	
	$contentTypeToUpdate = [Microsoft.SharePoint.SPContentType]($w.ContentTypes[$contentType])
	$dummyCount = $contentTypeToUpdate.FieldLinks.Count
	
	$fieldToModify = [Microsoft.SharePoint.SPFieldLink]($contentTypeToUpdate.FieldLinks[$fieldName])
	
	$fieldToModify.ReadOnly = $readOnly	
	$fieldToModify.ShowInDisplayForm = $showInDisplayForm
	if ($fieldDisplayName -ne $null)
	{
		$fieldToModify.DisplayName = $fieldDisplayName
	}
	$contentTypeToUpdate.Update()
	$w.Update()
}

###############################################################################
# Deletes the list
###############################################################################
function Delete-List($web, $listUrl)
{
	Write-Message "Deleting list $listUrl" "cyan"
	$w = [Microsoft.SharePoint.SPWeb](Get-SPWeb $web)
	$listToDelete = $w.GetList($listUrl)
	$listToDelete.Delete();
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
function Export-ManagedMetadataStore($filePath, $mmsServiceApplicationName){
  Write-Message "Exporting managed metadata service application data to file `"$filePath`"..." "cyan"
	if($filePath -eq $null -or $filePath -eq "") {
		throw "Export file path is required."
	}
	if($mmsServiceApplicationName -eq $null -or $filePath -eq "") {
		throw "Name of metadata service application is required."
	}
	$folderPath = [System.IO.Path]::GetDirectoryName($filePath)
	if([System.IO.Directory]::Exists($folderPath) -ne $true){
		Write-Message "A directory `"$folderPath`" does not exist. Creating..." "yellow"
		New-Item -Path $folderPath -type directory -ea:Stop | Out-Null
	}
	$mmsApp = Get-SPServiceApplication | ? `
		{$_.TypeName -eq "Managed Metadata Service" -and $_.DisplayName -eq $mmsServiceApplicationName}
	if($mmsApp -eq $null){
		throw "Cannot find a service application of type 'Managed Metadata Service' with display name `'$mmsServiceApplicationName`'."
	}

	$mmsProxy = Get-SPServiceApplicationProxy | ? `
		{$_.TypeName -eq "Managed Metadata Service Connection" -and $_.DisplayName -eq $mmsServiceApplicationName}
	if($mmsProxy -eq $null){
		throw "Cannot find a service application proxy of type 'Managed Metadata Service Connection' with display name `'$mmsServiceApplicationName`'."
	}
	Export-SPMetadataWebServicePartitionData -Identity $mmsApp.Id -ServiceProxy $mmsProxy -Path $filePath -ea:Stop
}

###############################################################################
# Imports managed metadata store from a file, overwriting its data.
###############################################################################
function Import-ManagedMetadataStore($filePath, $mmsServiceApplicationName){
 	Write-Message "Importing managed metadata service application data from file `"$filePath`"..." "cyan"
	if($filePath -eq $null -or $filePath -eq "") {
		throw "Import file path is required."
	}
	if($mmsServiceApplicationName -eq $null -or $filePath -eq "") {
		throw "Name of metadata service application is required."
	}
	if([System.IO.File]::Exists($filePath) -ne $true){
		throw "A file not found at a path `"$filePath`"."
	}
	$mmsApp = Get-SPServiceApplication | ? `
		{$_.TypeName -eq "Managed Metadata Service" -and $_.DisplayName -eq $mmsServiceApplicationName}
	if($mmsApp -eq $null){
		throw "Cannot find a service application of type 'Managed Metadata Service' with display name `'$mmsServiceApplicationName`'."
	}

	$mmsProxy = Get-SPServiceApplicationProxy | ? `
		{$_.TypeName -eq "Managed Metadata Service Connection" -and $_.DisplayName -eq $mmsServiceApplicationName}
	if($mmsProxy -eq $null){
		throw "Cannot find a service application proxy of type 'Managed Metadata Service Connection' with display name `'$mmsServiceApplicationName`'."
	}
  	try{
		Import-SPMetadataWebServicePartitionData 	-Identity $mmsApp.Id `
													-ServiceProxy $mmsProxy `
													-Path $filePath `
													-ea:Stop `
													-OverwriteExisting
	}catch{
		throw ("$_. If having permissions issues, check that service account " + `
		"of the MMS application has bulkadmin role in SQL server. For more info see " + `
		"http://blogs.msdn.com/b/taj/archive/2011/03/20/import-spmetadatawebservicepartitiondata-error-in-multi-server-deployment.aspx")
	}
}