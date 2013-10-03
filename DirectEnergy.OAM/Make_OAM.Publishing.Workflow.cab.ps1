# Written by Ingo Karstein (http://ikarstein.wordpress.com)
#   v0.1.0.0 / 2012-05-01

$destWSPfilename = "C:\mywork\sandbox\DirectEnergy.OAM\Workflows\DirectEnergy.OAM.Publishing.Workflow.cab"
$sourceSolutionDir = [System.IO.DirectoryInfo]"C:\mywork\sandbox\DirectEnergy.OAM\Workflows\DE-OAM_WF"

##################################

$a = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")
$ctor = $a.GetType("Microsoft.SharePoint.Utilities.Cab.CabinetInfo").GetConstructors("Instance, NonPublic")[0]

$cabInf = $ctor.Invoke($destWSPfilename );

$mi = $cabInf.GetType().GetMethods("NonPublic, Instance, DeclaredOnly")
$mi2 = $null
foreach( $m in $mi ) {
    if( $m.Name -eq "CompressDirectory" -and $m.GetParameters().Length -eq 4 ) {
        $mi2 = $m;
        break;
    };
}

$mi2.Invoke($cabInf, @( $sourceSolutionDir.FullName, $true, -1,$null ));