Add-PSSnapin Microsoft.SharePoint.PowerShell –erroraction SilentlyContinue
## setup our properties 
$SiteUrl = "http://sp2010riyaz:65535/CPDMSITES/CPPRJ1" 
$ListName = "Project Information" 
$assembly = "CapitalPower.DM.Project, Version=1.0.0.0, Culture=neutral, PublicKeyToken=e97f8224afd0738b" 
$class = "CapitalPower.DM.ListInstances.ProjectInformationList.InformationChanged.ChangeHandler"

## function to add the receiver 
Function AddReceiver($type) 
{   
    Write-Host "    Adding receiver: $type – $assembly – $class" -nonewline 
    try { 
        $OpenList.EventReceivers.Add($type, $assembly, $class) 
		$OpenList.Update($true)
        Write-Host " – done" -foreground green   
    } 
    catch { 
        Write-Host " – error adding receiver : $_" -foreground red   
    } 
}

## open the web site 
Write-Host "Opening web ‘$SiteUrl’" -nonewline 
$OpenWeb = Get-SPWeb $SiteUrl -EA Stop 
Write-host " – done " -foreground green
## open the list 
Write-Host "Opening ‘$ListName’ list" -nonewline 
$OpenList = $OpenWeb.Lists[$ListName] 
if ($OpenList -eq $null) 
{ 
    Write-host " – can’t open list " -foreground red 
    return 
} 
else 
{ 
    Write-host " – done " -foreground green 
}
## remove any existing event receivers 
Write-Output "Removing existing event receivers:" 
$count = $OpenList.EventReceivers.Count 
if ($count -gt 0) 
{
    for( $x = $count -1; $x -gt -1; $x–-) 
    { 
        $Receiver = $OpenList.EventReceivers[$x] ; $t = $Receiver.Type ; $a = $Receiver.Assembly ; $c = $Receiver.Class 
        Write-Host "    [$x] – $t – $a – $c" -nonewline 
        $Receiver.Delete() 
        Write-Host " – done " -foreground green 
    }
	$OpenList.Update($true)
} 
else 
{ 
    Write-Host "    – no existing EventReceivers found." -foreground green 
}
## add new event receivers 
Write-Host "Adding new event receivers:" 
## add a new row for each type required to be registered 
AddReceiver("ItemAdded") 
AddReceiver("ItemUpdated")
AddReceiver("ItemDeleted")
Write-Host "-Execution Compeleted-" -foreground green