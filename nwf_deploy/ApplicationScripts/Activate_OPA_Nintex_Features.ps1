Set-ExecutionPolicy RemoteSigned

# Load SharePoint PS snap-in.
Add-Type -AssemblyName "Microsoft.SharePoint, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c"
$snapin = Get-PsSnapin Microsoft.SharePoint.PowerShell -ea SilentlyContinue

if ($snapin -eq $null) {
    Add-PsSnapin Microsoft.SharePoint.PowerShell
}

###############################################################################
# Activates a feature.
###############################################################################
function Activate-Feature($featureName, $url, $abortOnError) {
   
    $feature = $null

try{
        $feature = Get-SPFeature -Identity $featureName -ea Stop

        $output = Enable-SPFeature $feature -Url $url -confirm:$false -ea Stop | Out-String -Width 255 -Stream
		}
		catch{
		echo "error"
		}
		finally{
		}
    
}

$0 = $myInvocation.MyCommand.Definition
$dp0 = [System.IO.Path]::GetDirectoryName($0)

$WebAppUrl = "http://sp2010riyaz:3877"
$ContentDbName = "OPA_Setlement_New_Db"
$siteUrl = "$WebAppUrl/contracts"

Activate-Feature "NintexWorkflow" $siteUrl $true
Activate-Feature "NintexWorkflowWebParts" $siteUrl $true
Activate-Feature "NintexWorkflowEnterpriseWebParts" $siteUrl $true
echo  "Activating Nintex site-level features..."
Activate-Feature "NintexWorkflowWeb" $siteUrl $true
Activate-Feature "NintexWorkflowEnterpriseWeb" $siteUrl $true

$webUrl = $siteUrl + "/process"
echo  "Activating Nintex site-level features..."
Activate-Feature "NintexWorkflowWeb" $webUrl $true
Activate-Feature "NintexWorkflowEnterpriseWeb" $webUrl $true

$webUrl = $siteUrl + "/approval"
echo  "Activating Nintex site-level features..."
Activate-Feature "NintexWorkflowWeb" $webUrl $true
Activate-Feature "NintexWorkflowEnterpriseWeb" $webUrl $true
