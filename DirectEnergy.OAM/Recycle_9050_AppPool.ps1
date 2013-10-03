$appPoolName = "myaccount_directenergy_domainx_local"
echo "Recycling apppool - $appPoolName"
$appPool = get-wmiobject -namespace "root\MicrosoftIISv2" -class "IIsApplicationPool" | Where-Object {$_.Name -eq "W3SVC/APPPOOLS/$appPoolName"}
echo $appPool
$appPool.Recycle()