Start-SPAssignment -Global

# load framework deployment script
$DEPLOYMENTSCRIPT = (ls | where-object {$_.Name -eq "DeploySolutions.ps1"}).FullName
. $DEPLOYMENTSCRIPT

$MASTERURL = "http://sp2010riyaz:9050"

#Install the solutions with the configurations set in the config file.
Deploy-Solution Deploy-Input.xml

# Create variations
Write-Host "Variations creation starting..."
Write-Host "Confirmations will be given for each site collection once the Variations are created."
Write-Host "..."
./CreateVariations.exe

# Activate Lookup Association Feature
#stsadm -o activatefeature -name "DirectEnergy.OAM_LookupAssociation" -Url $MASTERURL
#Enable-SPFeature "DirectEnergy.OAM_LookupAssociation" -Url $MASTERURL

#Elevated priveleges block to accommodate running scripts remotely on a server with UAC enabled.
[Microsoft.SharePoint.SPSecurity]::RunWithElevatedPrivileges( {	
	$web = Get-SPWeb $MASTERURL
	$web.AnonymousState = 2
	$web.update()
})	#End of elevated privileges block.

$IE=new-object -com internetexplorer.application
$IE.navigate2($MASTERURL)
$IE.visible=$true

Stop-SPAssignment -Global