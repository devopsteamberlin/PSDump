$DeployDir="C:\Projects\JGNMySite\JGN.MySites\Development\Source\JGN.MySite\bin\Debug\"
$stsadm = "$env:programfiles\Common Files\Microsoft Shared\Web Server Extensions\12\BIN\STSADM.EXE"
$IntranetURL="http://sp2010riyaz:5056"
$MySiteURL="http://sp2010riyaz:5056/my/"
$PersonalSiteURL="http://sp2010riyaz:5056/personal/"
$SiteOwner= "domainx\sp2010installer"

function DeActivateFeature($featureId, $siteUrl){

	$sResult = &stsadm -o deactivatefeature -id $featureId -url $siteUrl -force
	if(!($sResult -like "*Operation completed successfully*")){ 
  		throw "Deactivation of feature for '$siteUrl' failed!"		
 	} 
 	else{
  		Write-Host -ForegroundColor "blue" -BackgroundColor "white" "Deactivation of feature '$featureId' for '$websiteurl' was successful! `n $sResult" 
 	}		
}

function ActivateFeature($featureId, $siteUrl){

	$sResult = &stsadm -o activatefeature -id $featureId -url $siteUrl -force
	if(!($sResult -like "*Operation completed successfully*")){ 
  		throw "Activation of feature for '$siteUrl' failed!"
 	} 
 	else{
  		Write-Host -ForegroundColor "green" -BackgroundColor "white" "Activation of feature '$featureId' for '$websiteurl' was successful! `n $sResult" 
 	}		
}

function ReApplyBrandingChanges($siteUrl){

Write-Host "Initializing branding assignments" -ForegroundColor Green

## Reference to SharePoint DLL 
[System.Reflection.Assembly]::Load("Microsoft.SharePoint, Version=12.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c") 
[System.Reflection.Assembly]::Load("Microsoft.SharePoint.Portal, Version=12.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c")

$WebApplication = [Microsoft.SharePoint.Administration.Spwebapplication]::Lookup($PersonalSiteURL)

foreach($site in $WebApplication.Sites)
{
	$url = [string]$site.Url
		
	if($url.Contains($PersonalSiteURL)){
		Write-Host "Processing site: $url" -ForegroundColor Green
		$websiteurl= $web.url		
		
		#Deactivate old feature activation (JGN.MySite.MasterPageBranding)
		DeActivateFeature -featureId "b1266ae4-c007-430f-9ce6-dfc0e5027891" -siteUrl $websiteurl 		
 
 		#Re-Activate (JGN.MySite.MasterPageBranding)
 		ActivateFeature -featureId "b1266ae4-c007-430f-9ce6-dfc0e5027891" -siteUrl $websiteurl 	
		
		#Re-Apply Masterpage
		$siteMaster = New-Object System.Uri($websiteurl + "/_catalogs/masterpage/" + "JGN_v4.master");		
		$web = $site.OpenWeb()
		$web.AllowUnsafeUpdates = $true		
		$web.CustomMasterUrl = $siteMaster.AbsolutePath
		$web.MasterUrl = $siteMaster.AbsolutePath
		$web.Update()
		$web.AllowUnsafeUpdates = $false		
	}
}
$spsite.Dispose()
}

#region Script Start & Input Check
Write-Host  "`r`n***  Application deployment script for JGN.MySite  ***`r`n" -ForegroundColor cyan

if(($PersonalSiteURL -eq [string]::Empty) -or ($PersonalSiteURL -eq $null)) {
    Write-Host "Missing parameter value." -ForegroundColor red
	exit -1
}

try{
	ReApplyBrandingChanges $PersonalSiteURL
	exit 0
} catch {
    Write-Host "Failed to provision application changes. Error message: `"$_`"" -ForegroundColor red
	exit -1
}
#endregion