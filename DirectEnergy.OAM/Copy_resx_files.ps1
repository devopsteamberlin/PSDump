
$sourceDir = "C:\mywork\scm\DirectEnergy.OAM\Development\R1\DirectEnergy.OAM\Elements\Resources"

$format = "*.resx"

$dst_dir_14_Hive = "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\14\Resources"
$dst_dir_9050_App_Global_Resource = "C:\inetpub\wwwroot\wss\VirtualDirectories\sp2010riyaz9050\App_GlobalResources"

echo "Copying to 14 hive resource..."
Get-ChildItem -Path $sourceDir -Filter $format -Recurse | Copy-Item -Destination $dst_dir_14_Hive -Force

echo "Copying to application global resource..."
Get-ChildItem -Path $sourceDir -Filter $format -Recurse | Copy-Item -Destination $dst_dir_9050_App_Global_Resource -Force

$appPoolName = "myaccount_directenergy_domainx_local"
echo "Recycling apppool - $appPoolName"
$appPool = get-wmiobject -namespace "root\MicrosoftIISv2" -class "IIsApplicationPool" | Where-Object {$_.Name -eq "W3SVC/APPPOOLS/$appPoolName"}
echo $appPool
$appPool.Recycle()