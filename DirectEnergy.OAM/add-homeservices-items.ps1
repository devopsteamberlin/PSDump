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

Setup-PowerShellEnviornment

$docLibrary = (Get-SPWeb -identity http://sp2010riyaz:9050/Accounts -AssignmentCollection $spAssignment).Lists["Home Services"]
$localFolderPath = "C:\mywork\ps\DirectEnergy.OAM\add-homeservices-items_resources"
[int] $i = 0

$files = ([System.IO.DirectoryInfo] (Get-Item $localFolderPath)).GetFiles() | ForEach-Object {
	
    $fileStream = ([System.IO.FileInfo] (Get-Item $_.FullName)).OpenRead()
    $contents = new-object byte[] $fileStream.Length
    $fileStream.Read($contents, 0, [int]$fileStream.Length);
    $fileStream.Close();
    write-host "Copying" $_.Name "to" $docLibrary.Title
    $folder = $docLibrary.RootFolder
    $spFile = $folder.Files.Add($folder.Url + "/" + $_.Name, $contents, $true)
    $spItem = $spFile.Item	
	
	$i++
	$spItem["HomeServiceTitle"] = "Alet text $i"
	$spItem["LinkUrl"] = "http://sp2010riyaz:9050/accounts/default$i.aspx#"	
	$spItem["OrderValue"] = ($i * 100)
	$spItem["Brand"] = "DirectEnergy"
	$spItem["SiteType"] = "PostPaid"
	$spItem.Update()
}


Stop-SPAssignment -Global