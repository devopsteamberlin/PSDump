############### Only for the purpose of developing in PowerGUI #####
$0 = $myInvocation.MyCommand.Definition
$dp0 = [System.IO.Path]::GetDirectoryName($0)
####################################################################

. $dp0\SharePointFunctions.ps1

. $dp0\ProvisionPermissions.ps1 -WebAppUrl "http://sp2010riyaz:3877"