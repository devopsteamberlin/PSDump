Set-ExecutionPolicy RemoteSigned

# Load SharePoint PS snap-in.
Add-Type -AssemblyName "Microsoft.SharePoint, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c"
$snapin = Get-PsSnapin Microsoft.SharePoint.PowerShell -ea SilentlyContinue

if ($snapin -eq $null) {
    Add-PsSnapin Microsoft.SharePoint.PowerShell
}

function Deactivate-Feature($featureName, $url, $abortOnError) {
    echo "Deactivating feature $featureName at URL: $url ..."
    $feature = $null
    
    try {
        $feature = Get-SPFeature -Identity $featureName -ea Stop
		$output = Disable-SPFeature $feature -Url $url -confirm:$false -ea continue | Out-String -Width 255 -Stream
		}
    catch [Net.WebException] {
    Write-Host $_.Exception.ToString()       
    }
	finally{
	}    
}

$0 = $myInvocation.MyCommand.Definition
$dp0 = [System.IO.Path]::GetDirectoryName($0)

$WebAppUrl = "http://sp2010riyaz:3877"
$ContentDbName = "OPA_Setlement_New_Db"
$siteUrl = "$WebAppUrl/contracts"

$webUrl = $siteUrl + "/approval"
echo  "Deactivating Nintex site-level features..."
Deactivate-Feature "NintexWorkflowWeb" $webUrl $true
Deactivate-Feature "NintexWorkflowEnterpriseWeb" $webUrl $true

$webUrl = $siteUrl + "/process"
echo  "Deactivating Nintex site-level features..."
Deactivate-Feature "NintexWorkflowWeb" $webUrl $true
Deactivate-Feature "NintexWorkflowEnterpriseWeb" $webUrl $true

Deactivate-Feature "NintexWorkflow" $siteUrl $true
Deactivate-Feature "NintexWorkflowWebParts" $siteUrl $true
Deactivate-Feature "NintexWorkflowEnterpriseWebParts" $siteUrl $true
echo  "Deactivating Nintex site-level features..."
Deactivate-Feature "NintexWorkflowWeb" $siteUrl $true
Deactivate-Feature "NintexWorkflowEnterpriseWeb" $siteUrl $true