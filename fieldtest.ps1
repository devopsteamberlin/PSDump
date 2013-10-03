# Load SharePoint PS snap-in.
$snapin = Get-PsSnapin Microsoft.SharePoint.PowerShell -ea SilentlyContinue
if ($snapin -eq $null) {
    Add-PsSnapin Microsoft.SharePoint.PowerShell
}

#—————————————————————————-
# Delete Field
#—————————————————————————-
function DeleteField([string]$siteUrl, [string]$fieldName) {
    Write-Host "Start removing field:" $fieldName -ForegroundColor DarkGreen
    $site = Get-SPSite $siteUrl
    $web = $site.RootWeb
	$web.AllowUnsafeUpdates = $true
	
    #Delete field from all content types
    foreach($ct in $web.ContentTypes) {
        $fieldInUse = $ct.FieldLinks | Where {$_.Name -eq $fieldName }
        if($fieldInUse) {
            Write-Host "Remove field from CType:" $ct.Name -ForegroundColor DarkGreen
            $ct.FieldLinks.Delete($fieldName)
            $ct.Update()
        }
    }

    #Delete column from all lists in all sites of a site collection
    $site | Get-SPWeb -Limit all | ForEach-Object {
       #Specify list which contains the column
        $numberOfLists = $_.Lists.Count
        for($i=0; $i -lt $_.Lists.Count ; $i++) {
            $list = $_.Lists[$i]
            #Specify column to be deleted
            if($list.Fields.ContainsFieldWithStaticName($fieldName)) {
                $fieldInList = $list.Fields.GetFieldByInternalName($fieldName)

                if($fieldInList) {
                    Write-Host "Delete column from " $list.Title " list on:" $_.URL -ForegroundColor DarkGreen

                 #Allow column to be deleted
                 $fieldInList.AllowDeletion = $true
                 #Delete the column
                 $fieldInList.Delete()
                 #Update the list
                 $list.Update()
                }
            }
        }
    }

    # Remove the field itself
    if($web.Fields.ContainsFieldWithStaticName($fieldName)) {
        Write-Host "Remove field:" $fieldName -ForegroundColor DarkGreen
		$f = $web.Fields[$fieldName]
		echo $f.Title
        #$web.Fields.Delete($fieldName)
    }

	$web.AllowUnsafeUpdates = $false
    $web.Dispose()
    $site.Dispose()
}

$rootUrl = "http://sp2010riyaz:65535"
$hubSiteUrl = $rootUrl + "/CPDMCNTHUB"

DeleteField $hubSiteUrl "EngineeringDocumentTypePC"
DeleteField $hubSiteUrl "LegalDocumentTypePC"
DeleteField $hubSiteUrl "HandSDocumentTypePC"


$hubSite = new-object Microsoft.SharePoint.SPSite($hubSiteUrl)

$hubSite.AllowUnsafeUpdates = $true;
$field = $hubSite.rootweb.Fields[[GUID]"{8477834a-774f-4e42-a617-636687a3acb4}"]
if($field -ne $null){
	$field.Title = "Document Type"
	$field.Update
}
$hubSite.AllowUnsafeUpdates = $false;