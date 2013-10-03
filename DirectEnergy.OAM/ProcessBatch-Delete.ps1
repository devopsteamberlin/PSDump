Start-SPAssignment -Global

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

function Delete-ListItemsBatch($listTitleName, $siteUrl){

try{

	#Get hold of the SPWeb object
	[Microsoft.SharePoint.SPWeb] $spweb = Get-SPWeb -Identity $siteUrl;

	[Microsoft.SharePoint.SPList]$list = $spweb.Lists[$listTitleName];

	#We prepare a String.Format with a String.Format, this is why we have a {{0}} 
	[string] $command = [String]::Format('<Method><SetList Scope="Request">{0}</SetList><SetVar Name="ID">{{0}}</SetVar><SetVar Name="Cmd">Delete</SetVar><SetVar Name="owsfileref">{{1}}</SetVar></Method>', $list.ID);

	#We get everything but we limit the result to 100 rows 
	$q = New-Object Microsoft.SharePoint.SPQuery
	$q.RowLimit = 100;

	Write-Host -ForegroundColor Green "`tProcessign list: $listTitleName"
	$itemcount = $list.Items.Count;
	if($itemcount -gt 0){
		Write-Host -ForegroundColor Green "`t`tNumber of Items found: $itemcount"
	}
	else{
		Write-Host -ForegroundColor Magenta "`t`tNumber of Items found: $itemcount. Skipping item deletion..."
	}

	#While there's something left 
	while($list.Items.Count -gt 0)
	{
		#We get the results 
	    $items = $list.GetItems($q);
						
		#We get the results 
	    [Microsoft.SharePoint.SPListItemCollection] $items = $list.GetItems($q);

		$sbDelete = New-Object -Type System.Text.StringBuilder 
	    $sbDelete.Append('<?xml version="1.0" encoding="UTF-8"?><Batch>');
	    $ids = New-Object Guid[] $items.Count;
		
		if($items.Count -gt 0){
			for([int] $i=0;$i -lt $items.Count;$i++)
		    {
		     [Microsoft.SharePoint.SPListItem] $item = $items[$i];
		     $sbDelete.Append([string]::Format($command, $item.ID.ToString(), $item.File.ServerRelativeUrl));
		     $ids[$i] = $item.UniqueId;
		    }
		    $sbDelete.Append('</Batch>');

		    #We execute it 
		    $spweb.ProcessBatchData($sbDelete.ToString());
			
			# Wipeout the items from recycle bin as well.
			$deletedItems = $spweb.RecycleBin | ?{$_.ItemType -eq "ListItem"}; 
		
			if($deletedItems -ne $null){
				$deletedItems | % {$spweb.RecycleBin.Delete($_.Id)}
			}			
			
			#Finally update the list
	    	$list.Update();
			
			Write-Host -ForegroundColor Green "`t`t`tCompleted Deleting items..."
		}	
	}  
}
catch{
	throw $_;
}
finally{	
	$spweb.Dispose();
}
}

try {

	#Delete-ListItemsBatch -listTitleName "Brands" `
	#						-siteUrl "http://sp2010riyaz:9050"
							
	#Delete-ListItemsBatch -listTitleName "States" `
	#						-siteUrl "http://sp2010riyaz:9050"
							
	#Delete-ListItemsBatch -listTitleName "System Configuration" `
	#						-siteUrl "http://sp2010riyaz:9050"
							
	#Delete-ListItemsBatch -listTitleName "Account Sites" `
	#						-siteUrl "http://sp2010riyaz:9050/accounts"
	
	#Delete-ListItemsBatch -listTitleName "Top Navigation" `
	#						-siteUrl "http://sp2010riyaz:9050/accounts"
	
	#Delete-ListItemsBatch -listTitleName "Registration Configuration" `
	#						-siteUrl "http://sp2010riyaz:9050"							
	
	#Delete-ListItemsBatch -listTitleName "Banners" `
	#						-siteUrl "http://sp2010riyaz:9050/accounts"
	
	#Delete-ListItemsBatch -listTitleName "Convenient Features" `
	#						-siteUrl "http://sp2010riyaz:9050/accounts"
	
	Delete-ListItemsBatch -listTitleName "Site Configuration" `
							-siteUrl "http://sp2010riyaz:9050/accounts"										
							
	exit 0
} catch {
    write-host -f Red "Failed to provision list data. Error message: `"$_`""
	exit -1
}

Stop-SPAssignment -Global