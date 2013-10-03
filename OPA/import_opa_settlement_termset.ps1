$metadataApp= Get-SpServiceApplication | ? {$_.TypeName -eq "Managed Metadata Service"}
$mmsAppId = $metadataApp.Id
$mmsproxy = Get-SPServiceApplicationProxy | ?{$_.TypeName -eq "Managed Metadata Service Connection"} 
Import-SPMetadataWebServicePartitionData -Identity $mmsAppId -ServiceProxy $mmsproxy -Path "C:\backups\MetadataExport_OPA_2012-04-24.bak" -OverwriteExisting
