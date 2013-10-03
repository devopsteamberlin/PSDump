
$siteUrl = "http://sp2010riyaz:9050/Accounts"

clear
 
$PSSnapin = Remove-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue | Out-Null
$PSSnapin = Add-PsSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue | Out-Null

$Web = Get-SPWeb -Identity $siteUrl
$SiteColl = $Web.Site 

[Microsoft.SharePoint.SPSecurity]::RunWithElevatedPrivileges(
{
	$lWeb = $SiteColl.OpenWeb([System.Guid]'3c6e770e-e4b0-4d76-9d89-fbc7033123a9');
	#{F7693524-B026-4A8D-8C36-A2A2E2809DB8}
	$lList = $lWeb.Lists[[System.Guid]'{F7693524-B026-4A8D-8C36-A2A2E2809DB8}'];
	$linternalName = 'Name'
	#$lField = $lList.Fields['Name']
	#$lvalue = $lList.Fields | where-object{$_.InternalName -eq 'Name'}
	
	$caml = '<Where>
                 <Eq>
                  <FieldRef Name="' + $linternalName +'"/>
                  <Value Type="Text">
                  {0}
                  </Value>
                 </Eq>
               </Where>' -f 'Postpaid'
	
		
	$query=new-object Microsoft.SharePoint.SPQuery
    $query.Query=$caml
	foreach($f in $lList.GetItems($query)){
		echo $f
	}
    $col=$lList.GetItems($query)[$linternalName]
	echo $col
	
	
	$va = $lList.GetItems($lvalue.InternalName) | Where-Object {$_ -eq 'PostPaid'}
	
	Write-Host -ForegroundColor DarkCyan $lvalue;	
});	
