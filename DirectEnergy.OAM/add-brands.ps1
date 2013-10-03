Start-SPAssignment -Global

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

function Add-NewItem($listInstance, $domain, $brandName, $masterPageurl){
$newItem = $listInstance.Items.Add()
$newItem["Domain"] = $domain
$newItem["Brand Name"] = $brandName
$newItem["Master Page Url"] = $masterPageurl
$newItem.Update()
}

Setup-PowerShellEnviornment

$mylist = (Get-SPWeb -identity http://sp2010riyaz:9050 -AssignmentCollection $spAssignment).Lists["Brands"]
Add-NewItem -listInstance $mylist `
			-domain "deoam" `
			-brandName "Direct Energy" `
			-masterPageurl "/_catalogs/masterpage/DE_OAM_Base.master"

Add-NewItem -listInstance $mylist `
			-domain "deoam" `
			-brandName "Gateway" `
			-masterPageurl "/_catalogs/masterpage/DE_OAM_Base.master"
			
Add-NewItem -listInstance $mylist `
			-domain "deoam" `
			-brandName "First Choice Power" `
			-masterPageurl "/_catalogs/masterpage/DE_OAM_Base.master"


Stop-SPAssignment -Global