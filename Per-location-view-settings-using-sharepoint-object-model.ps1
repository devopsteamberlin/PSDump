# Load SharePoint PS snap-in.
Add-Type -AssemblyName "Microsoft.SharePoint, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c"
$snapin = Get-PsSnapin Microsoft.SharePoint.PowerShell -ea SilentlyContinue

if ($snapin -eq $null) {
    Add-PsSnapin Microsoft.SharePoint.PowerShell
}

#See: http://technet.microsoft.com/en-us/library/microsoft.office.documentmanagement.metadatanavigation.metadatanavigationsettings.aspx
# http://blogs.msdn.com/b/navdeepm/archive/2010/07/24/per-location-view-settings-using-sharepoint-object-model.aspx?Redirected=true

$web=get-spweb "http://sp2010riyaz:65535/CPDMSITES/CPGEN"
$lists=$web.lists
$list=$lists["Administration and Plant Management"]
$list = $web.lists["Administration and Plant Management"]
$Folders=$list.Folders

$ViewSet="All Documents,d"
$ViewArr=$ViewSet.split(",")

$WipeFolderDefaults=$true;  # This is optional

foreach($lv in $list.Views){
Write-Host $lv.Title
}
$Views=$list.Views 
$RF=$List.RootFolder
#$x.get_Properties()
[xml] $x=$RF.Properties["client_MOSS_MetadataNavigationSettings"]

if ($WipeFolderDefaults)
{
                try #if it fails, it is because the node just isn't there, which might mean no folders defined, which is fine.
                {
                                $x.MetadataNavigationSettings.NavigationHierarchies.FolderHierarchy.removeall()  
                }
                catch
                {
                                write-host "nothing to wipe, we are good to go!"
                }
}

$FolderCount=$Folders.count;
$NavHierNode = $x.MetadataNavigationSettings.NavigationHierarchies
$ViewSettingsNode = $NavHierNode.SelectSingleNode("FolderHierarchy") #grabs it as XMLNode, instead of string, if empty node 
for ($i=0; $i -lt $FolderCount; $i++)
{
                $Folder=$Folders[$i]
                switch ($Folder.ContentType.name)
                {
                                "Mines"            { $DefaultViewName= "d"}
                                #"Claim Folder"                   { $DefaultViewName= "Claim View"}
                                #"Policy Folder"                  { $DefaultViewName= "UW View"}
                                #"Loss Control Folder"            { $DefaultViewName= "LC View"}
                                default                                                                                 { $DefaultViewName= "All Documents"}
                }

                $View=$Views[$DefaultViewName];
                if ($View -eq $null)
                {
                                Write-Host "View ($($DefaultViewName) not found, falling back to All Documents"
                                $DefaultViewName= "All Documents"; # logic assumes this is always there
                                $View=$Views[$DefaultViewName];
                }

                $FolderGuid=$Folder.UniqueId
                $FolderID= $Folder.id
                $FolderURL= $Folder.Url;

                $NewFolderNode=$X.CreateElement("ViewSettings");
                $NewFolderNode.SetAttribute("UniqueNodeId",$FolderGuid);
                $NewFolderNode.SetAttribute("FolderId",$FolderID);

                $NewViewNode=$X.CreateElement("View");
                $NewViewNode.SetAttribute("ViewId",$View.id);
                $NewViewNode.SetAttribute("CachedName",$View.Title);
                $NewViewNode.SetAttribute("Index","0");  #0 forces view to be default
                $NewViewNode.SetAttribute("CachedUrl",$View.Url);
                $NewFolderNode.AppendChild($NewViewNode);
                $Index=1; # we want in increment index for each view for sequence
                foreach ($ViewName in $ViewArr)
                {
                                $View=$Views[$DefaultViewName];
                                if ($View -eq $null)
                                {
                                                Write-Host "View ($($DefaultViewName) not found, secondary view, skipping" #never do a continue within foreach!
                                }
                                elseif ($ViewName -ne $DefaultViewName) #make sure to skip adding the default view as a secondary view
                                {
                                                $View=$Views[$ViewName];

                                                $NewViewNode=$X.CreateElement("View");
                                                $NewViewNode.SetAttribute("ViewId",$View.id);
                                                $NewViewNode.SetAttribute("CachedName",$View.Title);
                                                $NewViewNode.SetAttribute("Index",$Index.tostring());  #0 forces view to be default
                                                $NewViewNode.SetAttribute("CachedUrl",$View.Url);
                                                $NewFolderNode.AppendChild($NewViewNode);
                                                $Index++; #view sequence numbering
                                }
                }

                $ViewSettingsNode.AppendChild($NewFolderNode)  

                }

#$x.InnerXml > "L:\PowerShell\Per Location Views\2a.xml"

$RF.Properties["client_MOSS_MetadataNavigationSettings"]=$x.InnerXml.ToString();
$RF.Update()
$list.Update() #both property and List update are required
 