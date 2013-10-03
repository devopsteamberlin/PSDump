$0 = $myInvocation.MyCommand.Definition
$dp0 = [System.IO.Path]::GetDirectoryName($0)

$WebAppUrl = "http://sp2010riyaz:3877"
$ContentDbName = "OPA_Setlement_New_Db"

. "$dp0\DeployApplication.ps1" -WebAppUrl $WebAppUrl -ContentDbName $ContentDbName