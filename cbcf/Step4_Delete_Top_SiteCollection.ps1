$IntranetURL="http://sp2010riyaz:10000/"

$snapin = Get-PSSnapin | Where-Object {$_.Name -eq 'Microsoft.SharePoint.Powershell'}
if ($snapin -eq $null) 
{
Write-Host "Loading SharePoint Powershell Snap-in"
Add-PSSnapin "Microsoft.SharePoint.Powershell"
}
ECHO "Removing Portal Site Collection"
Remove-SPSite –Identity $IntranetURL -Confirm:$false
ECHO "Site Deleted"
