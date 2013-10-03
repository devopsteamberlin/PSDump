$AdminServiceName = "SPAdminV4"

#Load sharepoint snapins and start admin services if its stoped.
function Setup-PowerShellEnviornment()
{
	#Ensure Microsoft.SharePoint.PowerShell is loaded
	$snapin="Microsoft.SharePoint.PowerShell"
	
	if (get-pssnapin $snapin -ea "silentlycontinue") {
		write-host -f Green "PSsnapin $snapin is loaded"
	}
	elseif (get-pssnapin $snapin -registered -ea "silentlycontinue") {
		write-host -f Green "PSsnapin $snapin is registered"
		Add-PSSnapin $snapin
		write-host -f Green "PSsnapin $snapin is loaded"
	}
	else {
		write-host -f orange "PSSnapin $snapin not found" -foregroundcolor Red
	}
	
	#if SPAdminV4 service is not started - start it
	if( $(Get-Service $AdminServiceName).Status -eq "Stopped")
	{
		#$IsAdminServiceWasRunning = $false
		Start-Service $AdminServiceName
	}
}

#Read the configuration xml file and do the opperations accordingly.
function Deploy-Solution([string]$configFile)
{
	if([string]::IsNullOrEmpty($configFile))
	{
		return
	}
	
	[xml]$solutionConfig = Get-Content $configFile
	
	if($solutionConfig -eq $null)
	{
		return
	}
	
	$solutionConfig.Solutions.Solution | ForEach-Object {
	
		[string]$path = $_.Path
        [bool]$gac = [bool]::Parse($_.GACDeployment)
        [bool]$cas = [bool]::Parse($_.CASPolicies)
		[string]$operation = $_.Operation

		$webAppElements = $_.WebApplications.WebApplication
		
		[string]$solutionName = Split-Path -Path $path -Leaf
			
		if([string]::IsNullOrEmpty($solutionName)) {
			return
		}
		
		if( ([string]::Compare($_.Operation, "Uninstall")) -eq 0) {
			Uninstall-Solution $path $gac $cas
		}
			
		if( ([string]::Compare($_.Operation, "Install")) -eq 0) {
			Install-Solution $path $gac $cas
		}
		
		if( ([string]::Compare($_.Operation, "Reinstall")) -eq 0) {
			Uninstall-Solution $path $gac $cas
			Install-Solution $path $gac $cas
		}
		
		if( ([string]::Compare($_.Operation, "Restore")) -eq 0) {
			Uninstall-Solution $path $gac $cas
			Restore-Solution $path $gac $cas
		}
	}
}

#deactivate and uninstall any features and retract the solution and remove from solution store.
function Uninstall-Solution([string]$path, [bool]$gac, [bool]$cas)
{
	Write-Host "Uninstall starting"
	
    [string]$name = Split-Path -Path $path -Leaf
    $solution = Get-SPSolution $name -ErrorAction SilentlyContinue
    
    if ($solution -ne $null) {
        #Retract the solution
        if ($solution.Deployed) {
		
			$webAppElements = $_.WebApplications.WebApplication
			[string]$featureActivationUrl = $_.Url

			$webAppElements | ForEach-Object {
			
				# Retrive the features to deactivate
				$features = $webAppElements.Features.Feature
				
				[string]$featureActivationUrl = $webAppElements.Url
						
				#Deactivate features one by one
				if ($features -ne $null)
				{
					$features | ForEach-Object {
						[string]$featureToRemove = $_.Name
						[bool]$activate = [bool]::Parse($_.Activate)
					
						if($featureToRemove -ne $null){
					
							$feature = Get-SPFeature -limit all| ? {($_.displayname -eq  $featureToRemove)}
							$webApplication = Get-SPWebApplication $featureActivationUrl
					
							if($feature -ne $null) {
						
								$featureId = $(Get-SPFeature -limit all| ? {($_.displayname -eq  $featureToRemove)}).Id
								if( ($featureId -ne $null ) -and ($webApplication.Features | ? {$_.DefinitionId -eq $featureId})){
									Disable-SPFeature -Identity $featureToRemove -url $featureActivationUrl -Confirm:$false
									write-host "$featureToRemove deactivated in the scope $featureActivationUrl."
								}
							
								write-host "Uninstalling feature $featureToRemove."
								Uninstall-SPFeature $featureToRemove -Confirm:$false
								write-host "Sucsessfully Uninstalled feature $featureToRemove."
							}
						}
					}			
				}
			}
		
            Write-Host "Retracting solution $name..."
            if ($solution.ContainsWebApplicationResource) {
                $solution | Uninstall-SPSolution -AllWebApplications -Confirm:$false
            } else {
                $solution | Uninstall-SPSolution -Confirm:$false
            }
            
			Stop-Service -Name $AdminServiceName
            Start-SPAdminJob -Verbose
            Start-Service -Name $AdminServiceName    
        
            #Block until we're sure the solution is no longer deployed.
            do { Start-Sleep 2 } while ($solution.Deployed)
        }
        
        #Delete the solution
        Write-Host "Removing solution $name..."
        Remove-SPSolution –Identity $solution -Confirm:$false

		#Delete Site Collection one at a time
		if ($sites -ne $null)
		{
			$sites | ForEach-Object {
				[string]$siteUrl = $webAppElements.Url + $_.Url
				[string]$siteName = $_.Name
				[string]$siteTemplate = $_.Template
				[string]$siteOwner = $_.Owner
				[string]$siteLCID= $_.LCID
				[bool]$deleteExisting = [bool]::Parse($_.DeleteExisting)

				# check if site exists
				$site = Get-SPSite $siteUrl -ErrorVariable err -ErrorAction SilentlyContinue 

				if ($err)
				{
					Write-Warning "The site collection $siteUrl does not exist."
				}
				else
				{
					if ($deleteExisting) 
					{
						write-host "Deleting Site Collection $siteUrl."
						Remove-SPSite –Identity $siteUrl –GradualDelete –Confirm:$False
					}
				}

			}
		}
    }
	
	Write-Host "Uninstall Done"
}

function Restore-Solution([string]$path, [bool]$gac, [bool]$cas) {

	Write-Host "Restore starting"
	
	#Add the solution
	Write-Host "Adding solution $solutionName..."
	$solution = Add-SPSolution $path
	
	#Deploy the solution
	if (!$solution.ContainsWebApplicationResource) {
		Write-Host "Deploying solution $solutionName to the Farm..."
		$solution | Install-SPSolution -GACDeployment:$gac -CASPolicies:$cas -Confirm:$false -Force
	} 
	else {
		
		if ($webAppElements -eq $null -or $webAppElements.Length -eq 0) {
			Write-Warning "The solution $solutionName contains web application resources but no web applications were specified to deploy to."
			return
		}
		
		$webAppElements | ForEach-Object {
			Write-Host "Deploying solution $solutionName to $webAppElements.Url ..."
			$solution | Install-SPSolution -GACDeployment:$gac -CASPolicies:$cas -WebApplication $webAppElements.Url -Confirm:$false -Force
			
			Stop-Service -Name $AdminServiceName
			Start-SPAdminJob -Verbose
			Start-Service -Name $AdminServiceName    

			#Block until we're sure the solution is deployed.
			do { Start-Sleep 2 } while (!((Get-SPSolution $solutionName).Deployed)) 
			
			# Retrive the features to activate
			$features = $webAppElements.Features.Feature
			
			[string]$featureActivationUrl = $webAppElements.Url
			[bool]$recreateContentDB = [bool]::Parse($_.RecreateContentDB)
			[bool]$backupBeforeDelete = [bool]::Parse($_.BackupBeforeDelete)
			[string]$newContentDatabaseName = $_.NewContentDatabaseName
			[string]$backupFileLocation = $_.BackupFileLocation
			
			if($recreateContentDB)
			{
				$contentDB = Get-SPContentDatabase -WebApplication $webAppElements.Url
				if($contentDB -ne $null)
				{
					$contentDBName = $contentDB.Name
					
					if($backupBeforeDelete)
					{
						write-host "Performing Backup on Content Database : $contentDBName"
						Backup-SPFarm -Directory $backupFileLocation -BackupMethod Full -Item $contentDBName
						write-host -f Green "Backup Complete!"
					}
					
					write-host "Removing Content Database : $contentDBName"
					Remove-SPContentDatabase -identity $contentDB -Confirm:$false -Force:$true
					write-host -f Green "Content Database Removed!"
				}
				write-host "Creating new Content Database: $newContentDatabaseName"
				New-SPContentDatabase -Name $newContentDatabaseName -WebApplication $webAppElements.Url
				write-host -f Green "Database Creation Completed!"
			}

			#Activate features one by one
			if ($features -ne $null)
			{
				$features | ForEach-Object {
					[string]$featureToApply = $_.Name
					[bool]$activate = [bool]::Parse($_.Activate)
				
					if ($activate) {
						Enable-SPFeature -Identity $featureToApply -url $featureActivationUrl -Confirm:$false
						write-host "$featureToApply activated in the scope $featureActivationUrl."
					}
				}
			}

			# Retrieve the sites to create
			$sites = $webAppElements.SiteCollections.SiteCollection
			
			#Restore Site Collection one at a time
			if ($sites -ne $null)
			{
				$sites | ForEach-Object {
					[string]$siteUrl = $webAppElements.Url + $_.Url
					[string]$siteName = $_.Name
					[string]$siteTemplate = $_.Template
					[string]$siteOwner = $_.Owner
					[string]$siteLCID= $_.LCID
					[string]$siteBackup = $_.SiteBackup

					# check if site exists
					$site = Get-SPSite $siteUrl -ErrorVariable err -ErrorAction SilentlyContinue 

					if ($err)
					{

					}
					else
					{
						Write-Warning "The site collection $siteUrl already exists."

						if ($deleteExisting) 
						{
							write-host "Deleting Site Collection $siteUrl."
							Remove-SPSite –Identity $siteUrl –GradualDelete –Confirm:$False
						}
					}

					if ($siteBackup -ne $null -AND $siteBackup -ne "")
					{
						write-host "Restoring Site Collection on $siteUrl using site backup: $siteBackup ."
						Restore-SPSite -Identity $siteUrl -Path $siteBackup -force -Confirm:$False
						write-host -f Green "Restore Complete!"
						
						if($siteOwner -ne $null -AND $siteOwner -ne "")
						{
							write-host "Setting Site Collection Owner to $siteOwner"
							Set-SPSite -Identity $siteUrl -OwnerAlias $siteOwner
							write-host "Done!"
						}
					}

					# Retrieve the features to activate
					$siteFeatures = $_.Features.Feature
			
					[string]$featureActivationUrl = $siteUrl

					#Activate features one by one
					if ($siteFeatures -ne $null)
					{
						$siteFeatures | ForEach-Object {
							[string]$featureToApply = $_.Name
							[bool]$activate = [bool]::Parse($_.Activate)
				
							if ($activate) {
								Enable-SPFeature -Identity $featureToApply -url $featureActivationUrl -Confirm:$false
								write-host "$featureToApply activated in the scope $featureActivationUrl."
							}
						}
					}
				}
			}
		}
	}

	Write-Host "Restore Complete"
}

#Install the solution and deploy and activate any features specified in the config file.
function Install-Solution([string]$path, [bool]$gac, [bool]$cas) {
	Write-Host "Install starting"
	
	#Add the solution
	Write-Host "Adding solution $solutionName..."
	$solution = Add-SPSolution $path
	
	#Deploy the solution
	if (!$solution.ContainsWebApplicationResource) {
		Write-Host "Deploying solution $solutionName to the Farm..."
		$solution | Install-SPSolution -GACDeployment:$gac -CASPolicies:$cas -Confirm:$false -Force
	} 
	else {
		
		if ($webAppElements -eq $null -or $webAppElements.Length -eq 0) {
			Write-Warning "The solution $solutionName contains web application resources but no web applications were specified to deploy to."
			return
		}
		
		$webAppElements | ForEach-Object {
			Write-Host "Deploying solution $solutionName to $webAppElements.Url ..."
			$solution | Install-SPSolution -GACDeployment:$gac -CASPolicies:$cas -WebApplication $webAppElements.Url -Confirm:$false -Force
			
			Stop-Service -Name $AdminServiceName
			Start-SPAdminJob -Verbose
			Start-Service -Name $AdminServiceName    

			#Block until we're sure the solution is deployed.
			do { Start-Sleep 2 } while (!((Get-SPSolution $solutionName).Deployed)) 
			
			# Retrive the features to activate
			$features = $webAppElements.Features.Feature
			
			[string]$featureActivationUrl = $webAppElements.Url

			#Activate features one by one
			if ($features -ne $null)
			{
				$features | ForEach-Object {
					[string]$featureToApply = $_.Name
					[bool]$activate = [bool]::Parse($_.Activate)
				
					if ($activate) {
						Enable-SPFeature -Identity $featureToApply -url $featureActivationUrl -Confirm:$false
						write-host "$featureToApply activated in the scope $featureActivationUrl."
					}
				}
			}

			# Retrieve the sites to create
			$sites = $webAppElements.SiteCollections.SiteCollection
			
			#Create Site Collection one at a time
			if ($sites -ne $null)
			{
				$sites | ForEach-Object {
					[string]$siteUrl = $webAppElements.Url + $_.Url
					[string]$siteName = $_.Name
					[string]$siteTemplate = $_.Template
					[string]$siteOwner = $_.Owner
					[string]$siteLCID= $_.LCID
					[bool]$deleteExisting = [bool]::Parse($_.DeleteExisting)
					
					# check if site exists
					$site = Get-SPSite $siteUrl -ErrorVariable err -ErrorAction SilentlyContinue 

					if ($err)
					{

					}
					else
					{
						Write-Warning "The site collection $siteUrl already exists."

						if ($deleteExisting) 
						{
							write-host "Deleting Site Collection $siteUrl."
							Remove-SPSite –Identity $siteUrl –GradualDelete –Confirm:$False
						}
					}

					# create site collection
					if ($siteTemplate -ne $null -AND $siteTemplate -ne "" -AND $siteUrl -ne $null -AND $siteUrl -ne "" -AND $siteName -ne $null -AND $siteName -ne "" -AND $siteOwner -ne $null -AND $siteOwner -ne ""){
						write-host "Creating Site Collection on $siteUrl using Site Template: $siteTemplate ."
						New-SPSite $siteUrl -OwnerAlias "$siteOwner" –Language $siteLCID -Name "$siteName" -Template "$siteTemplate"
					}
					
					
					# Retrieve the features to activate
					$siteFeatures = $_.Features.Feature
			
					[string]$featureActivationUrl = $siteUrl

					#Activate features one by one
					if ($siteFeatures -ne $null)
					{
						$siteFeatures | ForEach-Object {
							[string]$featureToApply = $_.Name
							[bool]$activate = [bool]::Parse($_.Activate)
				
							if ($activate) {
								Enable-SPFeature -Identity $featureToApply -url $featureActivationUrl -Confirm:$false
								write-host "$featureToApply activated in the scope $featureActivationUrl."
							}
						}
					}
				}
			}
		}
	}

	Write-Host "Install Done"
}

#Setup the enviornment to run the deployment script.
Setup-PowerShellEnviornment
