Start-SPAssignment -Global

# load framework deployment script
$DEPLOYMENTSCRIPT = (ls | where-object {$_.Name -eq "DeploySolutions.ps1"}).FullName
. $DEPLOYMENTSCRIPT

#Install the solutions with the configurations set in the config file.
Deploy-Solution Deploy.xml

Stop-SPAssignment -Global