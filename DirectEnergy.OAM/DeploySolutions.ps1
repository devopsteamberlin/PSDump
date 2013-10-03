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
			
			$webAppElements | ForEach-Object {			
			
				# Retrive the features to deactivate
				$features = $_.Features.Feature
				
				[string]$featureActivationUrl = $_.Url
						
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
	Write-Host"Test123."
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
		
			$webAppElements | ForEach-Object {
			
			if ($_ -eq $null -or $_.Length -eq 0) {
				Write-Warning "The solution $solutionName contains web application resources but no web applications were specified to deploy to."
				return
			}		
			
			[string] $deployUrl = $_.Url
					
			Write-Host "Deploying solution $solutionName to $deployUrl ..."
			$solution | Install-SPSolution -GACDeployment:$gac -CASPolicies:$cas -WebApplication $_.Url -Confirm:$false -Force
			
			Stop-Service -Name $AdminServiceName
			Start-SPAdminJob -Verbose
			Start-Service -Name $AdminServiceName    

			#Block until we're sure the solution is deployed.
			do { Start-Sleep 2 } while (!((Get-SPSolution $solutionName).Deployed)) 
			
			# Retrive the features to activate
			$features = $_.Features.Feature
			
			[string]$featureActivationUrl = $_.Url

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
			$sites = $_.SiteCollections.SiteCollection
			$webUrl = $_.Url
			
			#Create Site Collection one at a time
			if ($sites -ne $null)
			{
				$sites | ForEach-Object {
					[string]$siteUrl = $webUrl + $_.Url
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
					New-SPSite $siteUrl -OwnerAlias "$siteOwner" –Language $siteLCID -Name "$siteName" -Template "$siteTemplate"

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
