$Operation="Reinstall"
$Path="C:\mywork\scm\DirectEnergy.OAM\Development\R1\DirectEnergy.OAM\Deployment\DirectEnergy.OAM.Publishing.Workflow.wsp"
$CASPolicies=$false	#Just kept for future
$GACDeployment=$false #Just kept for future
$siteUrl="http://sp2010riyaz:11374"
$featureActiveSites = ("http://sp2010riyaz:11374")
$FeatureName="DE-OAM_WFListInstances" 
$FeatureActivate=$true

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
}

#deactivate and uninstall any features and retract the solution and remove from solution store.
function Uninstall-Solution([string]$siteUrl, [string]$path, [bool]$gac, [bool]$cas)
{
	Write-Host "Uninstall starting"

    [string]$name = Split-Path -Path $path -Leaf
    $solution = Get-SPUserSolution $name -Site $SiteUrl -ErrorAction SilentlyContinue
    	
    if ($solution -ne $null) {	
        #Retract the solution
        if ($solution.Status -eq "Activated") {
		
			foreach($website in $featureActiveSites){
			
				$feature = Get-SPFeature -Identity  $FeatureName -Site $website -Sandboxed				
				$web = Get-SPWeb $siteUrl
		
				if($feature -ne $null) {			
					$feature = $(Get-SPFeature -Identity  $FeatureName -Site $website -Sandboxed)
										
					$featureId = $(Get-SPFeature -Identity  $FeatureName -Site $website -Sandboxed).Id
					if($featureId -ne $null -and $feature.Status -eq "Online" ){
						Disable-SPFeature -Identity $FeatureName -url $website -Confirm:$false
						write-host "$FeatureName deactivated in the scope $webScopeUrl."
					}					
				}				
			}			
		
            Write-Host "Retracting solution $name..."            
            $solution | Uninstall-SPUserSolution -Site $siteUrl -Confirm:$false
        
            #Block until we're sure the solution is no longer deployed.
            do { Start-Sleep 2 } while ((Get-SPUserSolution -Identity $name -Site $siteUrl).Status -eq "Activated")
			
			#Delete the solution
        	Write-Host "Removing solution $name..."
        	Remove-SPUserSolution –Identity $name -Site $siteUrl -Confirm:$false
        }
    }
	
	Write-Host "Uninstall Done"
}

#Install the solution and deploy and activate any features specified in the config file.
function Install-Solution([string]$siteUrl, [string]$path, [bool]$gac, [bool]$cas) {

	Write-Host "Install starting"
	
	[string]$name = Split-Path -Path $path -Leaf
	
	#Add the solution
	Write-Host "Adding solution $name..."
	$solution = Add-SPUserSolution -LiteralPath $path -Site $siteUrl
	
	#Deploy the solution
	Write-Host "Deploying solution $name to $siteUrl ..."
	$solution | Install-SPUserSolution -Identity $name -Site $siteUrl -Confirm:$false
			
	#Block until we're sure the solution is deployed.
	do { Start-Sleep 2 } while (!((Get-SPUserSolution -Identity $name -Site $siteUrl).Status -eq "Activated")) 	
	
	foreach($website in $featureActiveSites){	
		[string]$featureIdentity = $FeatureName
		[bool]$activate = [bool]::Parse($FeatureActivate)
		
		if ($activate) {			
			Enable-SPFeature -Identity $featureIdentity -Url $website -Confirm:$false
			write-host "$featureIdentity activated in the scope $website."
		}	
	}
	Write-Host "Install Done"
}

#Setup the enviornment to run the deployment script.
Setup-PowerShellEnviornment

if( ([string]::Compare($Operation, "Uninstall")) -eq 0) {
	Uninstall-Solution $siteUrl $Path $GACDeployment $CASPolicies
}
	
if( ([string]::Compare($Operation, "Install")) -eq 0) {
	Install-Solution $siteUrl $path $GACDeployment $CASPolicies
}

if( ([string]::Compare($Operation, "Reinstall")) -eq 0) {
	Uninstall-Solution $siteUrl $path $GACDeployment $CASPolicies
	Install-Solution $siteUrl $path $GACDeployment $CASPolicies			
}