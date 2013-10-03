### Load SharePoint SnapIn   
if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null)   
 {   
     Add-PSSnapin Microsoft.SharePoint.PowerShell   
 }   
 ### Load SharePoint Object Model   
 [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")   
 
 function CreateRootDocumentSetOnLibrary($webUrl, $listName, $documentSetContentTypeName, $documentSetDescription, $documentSetTitle){
 
 $web = Get-SPWeb $webUrl 
 $list = $web.Lists[$listName]
 
 # Get Document Set Content Type from list   
 $cType = $list.ContentTypes[$documentSetContentTypeName]   
   
 # Create Document Set Properties Hashtable   
 [Hashtable]$docsetProperties = @{"DocumentSetDescription"=$documentSetDescription}
  
 ### Create new Document Set   
 $newDocumentSet = [Microsoft.Office.DocumentManagement.DocumentSets.DocumentSet]::Create($list.RootFolder,$documentSetTitle,$cType.Id,$docsetProperties)   
 
 $web.Dispose() 
 }
 
 CreateRootDocumentSetOnLibrary -webUrl "http://sp2010riyaz:9000/Contracts/process" `
 								-listName "Settlement Process Library" `
								-documentSetContentTypeName "Settlement System Document Set" `
								-documentSetDescription "Settlement System" `
								-documentSetTitle "Settlement System"