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

function Add-NewItem($listInstance, $title, $commodityCode, $commodityName){
$newItem = $listInstance.Items.Add()
$newItem["Title"] = $title
$newItem["CommodityCode"] = $commodityCode
$newItem["CommodityName"] = $commodityName
$newItem.Update()
}

Setup-PowerShellEnviornment

$mylist = (Get-SPWeb -identity http://sp2010riyaz:9050 -AssignmentCollection $spAssignment).Lists["Commodities"]
Add-NewItem -listInstance $mylist `
			-title "100" `
			-commodityCode "100" `
			-commodityName "Elec"

Add-NewItem -listInstance $mylist `
			-title "200" `
			-commodityCode "200" `
			-commodityName "Gas"
			
Add-NewItem -listInstance $mylist `
			-title "300" `
			-commodityCode "300" `
			-commodityName "Res"

Add-NewItem -listInstance $mylist `
			-title "400" `
			-commodityCode "400" `
			-commodityName "Com"

Add-NewItem -listInstance $mylist `
			-title "500" `
			-commodityCode "500" `
			-commodityName "C&I"
			
Stop-SPAssignment -Global