Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction 0

$strSiteURL = "http://hodsdev.hydroone.com"
$SiteOwner= "domainx\sp2010installer"

#Set-SPSite -Identity $strSiteURL -SecondaryOwnerAlias $SiteOwner


function Undo-CheckedOutFilesInSPWeb([Microsoft.SharePoint.SPWeb]$web, [string]$comment, [string]$destination, [string]$filter)
 {
     # Check this is a publishing web
     if ([Microsoft.SharePoint.Publishing.PublishingWeb]::IsPublishingWeb($web) -eq $true)
     {
         # just a quick loop to space out dashes
         for($c = 0; $c -lt $destination.length; $c++)
         {
             $dshspcr += "-"
         }
 
        # provide some feedback
         ""
         "Checking " + $destination + "..."
         "---------" + $dshspcr + "---"
         ""
 
        # do some stuff
         $list = $web.Lists[$destination]            # Load library we want to check
		 
		 [Object[]]$files = $list.get_items()		 
		 foreach($file in $files){
		 	if ($file.DisplayName -eq "ho_common"){
				UndoCheckOut-File $file
		 	}
			
			if ($file.DisplayName -eq "ho_masterpage_styles"){
				UndoCheckOut-File $file
		 	}			
			
			if ($file.DisplayName -eq "HODS"){
				UndoCheckOut-File $file
		 	}
			
			if ($file.DisplayName -eq "search"){
				UndoCheckOut-File $file
		 	}
			
			if ($file.DisplayName -eq "search2"){
				UndoCheckOut-File $file
		 	}	
			
			if ($file.DisplayName -eq "HODSfaq - Working Copy"){
				UndoCheckOut-File $file
		 	}	
			
			if ($file.DisplayName -eq "Two Column Even"){
				UndoCheckOut-File $file
		 	}	
			
			
			if ($file.DisplayName -eq "Two Column Left"){
				UndoCheckOut-File $file
		 	}	
			
			if ($file.DisplayName -eq "Two Column Right"){
				UndoCheckOut-File $file
		 	}	

		 }
		 
         $web.Dispose()
     }
 
}

function UndoCheckOut-File ([Microsoft.SharePoint.SPListItem]$pubFile) {
    "Processing " + $pubFile.Name
    $listitemfile = $pubFile.File 
 	$listitemfile.UndoCheckOut()    
 }
 
$url = "http://sp2010riyaz:7117"    # Site collection
$comment = "System Approval"        # Publishing comment
$lib = "Style Library"              # Library to publish
$dfilter = "*"                      # Default file filter
 
 # Create site object
 $site = new-object Microsoft.SharePoint.SPSite($url)
 #$site.rootweb | foreach {Undo-CheckedOutFilesInSPWeb $_ $comment "Style Library" $dfilter}
 $site.rootweb | foreach {Undo-CheckedOutFilesInSPWeb $_ $comment "Master Page Gallery" $dfilter}