Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction 0

$webUrl = "http://sp2010riyaz:9050/Accounts"
$listName = "Banners"
$columnsToRemove = @("Brand", "SiteType")

$web = Get-SPWeb -identity $webUrl
$list = $web.Lists[$listName]

if($list.Title -eq $listName){
	write-host "Processsing list "$list.Title
	$i=0
	foreach($coumnName in $columnsToRemove){
		$column = $list.Fields[$coumnName]
		if ($column.Type -eq [Microsoft.SharePoint.SPFieldType]::Lookup){
			write-host "Processsing field "$column.Title
			$column.ReadOnlyField = $false
			$column.Update()
			$list.Fields.Delete($column)		
		}
		
		$NewColXml = "<Field Type='Text' DisplayName=`'" + $columnsToRemove[$i] + "`' Required='FALSE' MaxLength='255' StaticName=`'" + $columnsToRemove[$i] + "`' Name=`'" + $columnsToRemove[$i] + "`' />"
		$list.Fields.AddFieldAsXml($NewColXml,$true,[Microsoft.SharePoint.SPAddFieldOptions]::AddFieldToDefaultView)
		
		$i++			
	}
	
	$list.Update
}

$web.Dispose