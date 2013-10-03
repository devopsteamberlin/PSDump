# Load SharePoint SnapIn   
if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null)   
 {   
     Add-PSSnapin Microsoft.SharePoint.PowerShell   
 }   
 # Load SharePoint Object Model   
 [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")    
 
 ###############################################################################
# Writes a message to the output and to the log file.
###############################################################################
function Write-Message ($message, $foregroundColor, $writeToLog = $true) {
    if($message -ne $null) {
        Write-Host $message -foregroundcolor $foregroundColor
    }
}

###############################################################################
# Adds a new content type to a site collection.
###############################################################################
function Add-NewContentType([string]$siteUrl, 
							[string]$parentContentTypeName, 
							[string]$newContentTypeName, 
							[string]$description, 
							[string]$fieldGroup, 
							[string[]] $columnsToAdd,
							[string[]] $allowedContentTypes){
	Write-Message "Adding content type `"$newContentTypeName`"..." "cyan"
	$site = Get-SPSite $siteUrl
	if($site -eq $null) {
		throw "siteUrl `"$siteUrl`" does not point to a valid site."
	}  
  	$rootWeb = $site.RootWeb
	$fields = $rootWeb.Fields
	foreach($column in $columnsToAdd){
		if($fields.ContainsField($column) -ne $true){
			throw "Cannot create content type `"$newContentTypeName`": field `"$column`" is not found."
		}
	}
	$thisCT = $rootWeb.ContentTypes[$newContentTypeName]
	if($thisCT -ne $null){
		Write-Message "Content type `"$newContentTypeName`" already exists in site collection `"$siteUrl`"." "yellow"
		return
	}
	
	$parentContentType = $rootWeb.ContentTypes[$parentContentTypeName]
  	$ct = New-Object Microsoft.SharePoint.SPContentType -ArgumentList @($parentContentType, 
																		$rootWeb.ContentTypes, 
																		$newContentTypeName)
	$ct.Description = $description
	$ct.Group = $fieldGroup
	$rootWeb.ContentTypes.Add($ct)    	
	foreach($column in $columnsToAdd){
		Write-Message "`tAdding field `"$column`" to content type `"$newContentTypeName`"..." "white"
	  	$field = $fields.GetField($column)
		$link = New-Object Microsoft.SharePoint.SPFieldLink -ArgumentList $field
		$ct.FieldLinks.Add($link)
	}
		
	$swallowedOutput = $ct.Update() 2>&1			
	$site.Dispose()
}

 function SetAllowedContentTypesOnDocumentSet($siteUrl, $appliedToContentTypeName, $allowedContentTypeNames, [array]$sharedFields = $null){
	Write-Message "Setting content types for documentset `"$appliedToContentTypeName`"..." "cyan"
	$site = Get-SPSite $siteUrl
	if($site -eq $null) {
		throw "siteUrl `"$siteUrl`" does not point to a valid site."
	}  
  	$rootWeb = $site.RootWeb
	
	$appliedToContentType = $rootWeb.ContentTypes[$appliedToContentTypeName]		
	if($appliedToContentType -eq $null){
		Write-Message "Content type `"$appliedToContentTypeName`" does not exists in site collection `"$siteUrl`"." "Red"
		return
	}	
	$dst = [Microsoft.Office.DocumentManagement.DocumentSets.DocumentSetTemplate]::GetDocumentSetTemplate($appliedToContentType)
		
	foreach($allowedContentTypeName in $allowedContentTypeNames){
	
		$thisCT = $rootWeb.ContentTypes[$allowedContentTypeName]
		
		if($thisCT -eq $null){
			Write-Message "Content type `"$allowedContentTypeName`" does not exists in site collection `"$siteUrl`"." "Red"
		return
		}
		
		$dst.AllowedContentTypes.Add($thisCT.Id)
		
		if ($sharedFields -ne $null -and $sharedFields.count -gt 0){
			foreach($sharedField in $sharedFields){
				#add a shareable property
				$dst.SharedFields.Add($appliedToContentType.Fields[$sharedField])
			}		
		}
	}	
	
	$dst.Update($true)
	$appliedToContentType.Update()
	$rootWeb.Dispose()
 }
	
 function CreateContentTypes($siteUrl){
	Write-Message  "Creating content types..." "cyan"
	$fieldGroupName = "Ontario Power Authority"

	Add-NewContentType	-siteUrl $siteUrl `
						-parentContentType "Document" `
						-newContentTypeName "Settlement Documentx" `
						-description "Settlement documentx" `
						-fieldGroup $fieldGroupName `
						-columnsToAdd @(
							'CES Inputs Proxy', 
							'Contracts', 
							'Cost and Production Database', 
							'Forecasting', 
							'Report', 
							'Classification', 
							'Summary', 
							'Supplier Name', 
							'Supplier Settlement', 
							'Settlement Date', 
							'Supplier Inputs', 
							'Type of Change')
							
	Add-NewContentType	-siteUrl $siteUrl `
						-parentContentType "Document Set" `
						-newContentTypeName "Settlement Approval Document Setx" `
						-description "Settlement approval document setx" `
						-fieldGroup $fieldGroupName `
						-columnsToAdd @('Settlement Date')
					
	Add-NewContentType	-siteUrl $siteUrl `
						-parentContentType "Document Set" `
						-newContentTypeName "Settlement System Document Setx" `
						-description "Settlement system document setx" `
						-fieldGroup $fieldGroupName `
						-columnsToAdd @()
}

 ###############################################################################
# Binds content types to a list
###############################################################################
function Bind-ContentTypesToList($webUrl, $listName, [string[]]$contentTypeNames){
	Write-Message "Binding content types `"$contentTypeNames`" to list `"$listName`" on site `"$webUrl`"..." "cyan"
	$web = Get-SPWeb $webUrl	
	if($web -eq $null) {
		$web.Dispose()
		throw "Web not found at URL `"$webUrl`""
	}	
	$list = $web.Lists[$listName]	
	if ($list -eq $null){
		$web.Dispose()
		throw "List `"$listName`" not found on the site `"$webUrl`"."	
	}
	$list.ContentTypesEnabled = $true
	$rootWeb = $web.Site.RootWeb
	foreach($contentTypeName in $contentTypeNames) {
		$ct = $rootWeb.AvailableContentTypes[$contentTypeName]
		if($ct -eq $null) {
			throw "Content type `"$contentTypeName`" not found."
		}		
		if($list.IsContentTypeAllowed($ct) -ne $true){
			Write-Message "List `"$listName`" on the site `"$webUrl`" is not compatible with content type `"$contentTypeName`". Binding was skipped." "yellow"
			continue
		} 
		$matchId = $list.ContentTypes.BestMatch($ct.Id)
		if($ct.Id.IsParentOf($matchId)){
			Write-Message "List `"$listName`" on the site `"$webUrl`" is already bound to `"$contentTypeName`" content type. Binding was skipped." "yellow"
			continue
		}		
		$list.ContentTypes.Add($ct)		
	}
	$swallowedOutput = $list.Update() 2>&1
	$web.Dispose()
	$rootWeb.Dispose()
}

 #CreateContentTypes -siteUrl "http://sp2010riyaz:3877/Contracts"
 
 SetAllowedContentTypesOnDocumentSet 	-siteUrl "http://sp2010riyaz:3877/Contracts" `
 										-appliedToContentTypeName "Settlement Approval Document Set" `
										-allowedContentTypeNames "Settlement Document" `
										-sharedFields "Settlement Date"
 
 # Makesure that the library - Settlement Approval Process Libraryx is present.
 #Bind-ContentTypesToList -webUrl "http://sp2010riyaz:3877/Contracts/Approval" `
#							-listName "Settlement Approval Process Libraryx" `
#							-contentTypeNames "Settlement Approval Document Setx"	

function testArray([array]$sharedFields = $null){
	if ($sharedFields -ne $null -and $sharedFields.count -gt 0){
		foreach($sharedField in $sharedFields){
			#add a shareable property
			Write-Host $sharedField			
		}		
	}
}

#testArray listOfSharedFields -sharedFields @('test')

