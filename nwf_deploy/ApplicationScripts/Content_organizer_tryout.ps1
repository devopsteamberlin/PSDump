# Load SharePoint SnapIn   
if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null)   
 {   
     Add-PSSnapin Microsoft.SharePoint.PowerShell   
 }   
 # Load SharePoint Object Model   
 [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")    
 
$0 = $myInvocation.MyCommand.Definition
$dp0 = [System.IO.Path]::GetDirectoryName($0)

function ConfigureContentOrganizerSettings($webUrl, $isSendSite){
	
	$web = Get-SPWeb -identity $webUrl	
	
	$dropOffList = $web.Lists["Drop Off Library"]
	$dropOffList.OnQuickLaunch = $false
	$dropOffList.Update()		
		
	if($isSendSite -eq $true){	
		# Apply this only to sending site
		$stringTrue = [string]"True"
		if ($web.AllProperties.ContainsKey("_routerenablecrosssiterouting")){
			
			if ($web.GetProperty("_routerenablecrosssiterouting")){
				#already enabled
			}
			else{
				$web.AllProperties["_routerenablecrosssiterouting"] = $stringTrue
				$web.Update()
			}
		}
		else{
			$web.AddProperty("_routerenablecrosssiterouting", $stringTrue)
			$web.Update()
		}		
	}
	else{
		#may need to tick - Create subfolders after a target location has too many items
		#need to do some R&D
	}
}

function CreateContentOrganizerRuleOnSendSite($webUrl, $newRuleName, $appliedContentType, $contentTypeAliasOnTargetSite, $targetPath, $routingTargetLibrary){

		
	$web = Get-SPWeb -identity $webUrl
		
	$hiddenListName = "Content Organizer Rules"
	
	#create routing rule "Settlement Content Organizer Rule"    
    $rulelist = $web.Lists[$hiddenListName]

    if ($rulelist.items[$newRuleName])
    {
    	#Rule already exists
    }
    else
    {
	    [Microsoft.SharePoint.SPContentType]$ct = $web.Site.RootWeb.ContentTypes[$appliedContentType]
	    [Microsoft.Office.RecordsManagement.RecordsRepository.EcmDocumentRouterRule]$rule = New-Object Microsoft.Office.RecordsManagement.RecordsRepository.EcmDocumentRouterRule($web)
	    $rule.Aliases = $contentTypeAliasOnTargetSite
	    $rule.Name = $newRuleName	
	    $rule.ConditionsString = "<Conditions></Conditions>"
	    $rule.CustomRouter = ""
	    $rule.Description = ""
	    $rule.ContentTypeString = $ct.Name
		
		if ($routingTargetLibrary -ne $null){
			$rule.RouteToExternalLocation = $false
			$rule.TargetPath = $web.Lists[$routingTargetLibrary].RootFolder.ServerRelativeUrl
		}
		else{
			$rule.RouteToExternalLocation = $true
			$rule.TargetPath = $targetPath
		}		
	    
	    $rule.Priority = "5"	    
	    $rule.Enabled = $true
	    $rule.Update()
	}	
 }

function CreateSendToConnection($webApplication, $action, $explanation, $officialFileName, $officialFileUrl, $showOnSendToMenu){
	$webapp = Get-SPWebApplication $webApplication

    $officialFileHostTemp = $webapp.OfficialFileHosts | ? { 
                    $_.OfficialFileName -eq $officialFileName 
    }
	
	#Remove existing connections
	foreach($connection in $officialFileHostTemp){
		$webapp.OfficialFileHosts.Remove($connection)
		$webapp.Update()
	}	

    [Microsoft.SharePoint.SPOfficialFileHost] $officialFileHost = New-Object "Microsoft.SharePoint.SPOfficialFileHost"
    $officialFileHost.Action = [Enum]::Parse([Microsoft.SharePoint.SPOfficialFileAction], $action)
    $officialFileHost.Explanation = $explanation
    $officialFileHost.OfficialFileName = $officialFileName
	$settlementArchiveUrl = $webapp.Url.TrimEnd("/") + $officialFileUrl
    $officialFileHost.OfficialFileUrl = $settlementArchiveUrl
    $officialFileHost.ShowOnSendToMenu = [bool]::Parse($showOnSendToMenu)
    $webapp.OfficialFileHosts.Add($officialFileHost)
    $webapp.Update()

    $officialFileHostTemp = $null
}

$WebAppUrl = "http://sp2010riyaz:3877"
$ContentDbName = "OPA_Setlement_New_Db"
$siteUrl = "$WebAppUrl/ERSettlement"

$sendToConnectionName = "Settlement Approval Process Archiving Drop Target"

CreateSendToConnection 	-webApplication $WebAppUrl	`
						-action "Move" `
						-explanation "Moves the Settlement Approval Process DocumentSet to Record Center Library" `
						-officialFileName $sendToConnectionName	`
						-officialFileUrl "/ERSettlement/archive/_vti_bin/officialfile.asmx" `
						-showOnSendToMenu $true
  
#$webUrl = $siteUrl + "/approval"
#ConfigureContentOrganizerSettings -webUrl $webUrl -isSendSite $true

$webUrl = $siteUrl + "/archive"
#ConfigureContentOrganizerSettings -webUrl $webUrl -isSendSite $false

#$webUrl = $siteUrl + "/approval"
#CreateContentOrganizerRuleOnSendSite 	-webUrl $webUrl `
#										-newRuleName "Settlement Content Organizer Rule"  `
#										-appliedContentType "Settlement Approval Document Set" `
#										-contentTypeAliasOnTargetSite "" `
#										-targetPath $sendToConnectionName

	#CreateContentOrganizerRuleOnSendSite 	-webUrl $webUrl `
	#										-newRuleName "Drop Files to Record Center"  `
	#										-appliedContentType "Settlement Approval Document Set" `
	#										-contentTypeAliasOnTargetSite "" `
	#										-targetPath $null `
	#										-routingTargetLibrary "Settlement Approval Records Document Library"