$DeployDir="C:\mywork\scm\PMCP.Internet\PMCP.Internet\PMCP.Internet.SharePoint\bin\Debug\"
$IntranetURL="http://sp2010riyaz:4040/"
$SiteOwner= "Domainx\sp2010installer"

$Solutions=@("PMCP.Internet.SharePoint.wsp")
$SiteFeatures=@()
$WebFeatures=@()
$Properties=@{}
$SiteTemplate="PMCPRoot#0"
$SiteName="Home"

$snapin = Get-PSSnapin | Where-Object {$_.Name -eq 'Microsoft.SharePoint.Powershell'}
if ($snapin -eq $null) 
{
Write-Host "Loading SharePoint Powershell Snap-in"
Add-PSSnapin "Microsoft.SharePoint.Powershell"
}


ECHO "Adding Solutions .."
ECHO ""
foreach($solution in $Solutions)
{
	ECHO "Adding soltuion: $Solution"
	Add-SPSolution $DeployDir$Solution
}

ECHO "Installing Solutions .."
ECHO ""
foreach($solution in $Solutions)
{
	ECHO "Installing soltuion: $Solution"	
	Install-SPSolution –Identity $Solution -GACDeployment -ErrorAction SilentlyContinue -Force
	Install-SPSolution –Identity $Solution -GACDeployment -WebApplication $IntranetURL -Force -ErrorAction SilentlyContinue	
}


ECHO "Waiting for solutions to be deployed ..."
SLEEP 30

$solutionsStatusOk=0

ECHO "Checking if all solutions are deployed successfully .."
ECHO ""

$numberOfSolutions = $Solutions.count
for ($i=1; $i -le 20; $i++)
{
	$solutionsStatusOk=0
	foreach($solution in $Solutions)
	{
		$sol=Get-SPSolution $solution -ErrorAction SilentlyContinue
		If ($sol.Deployed -eq $true)
		{
			ECHO "Solution $solution is deployed successfully .." 			
			$solutionsStatusOk = $solutionsStatusOk + 1
		}
	}

	ECHO "So far $solutionsStatusOk solutions out of $numberOfSolutions are deployed successfully.."
		
	if ($solutionsStatusOk -ge $numberOfSolutions)
	{
		ECHO "All solutions are deployed successfully.."
		ECHO ""
		BREAK
	}
	else
	{
		ECHO "$solutionsStatusOk out of $numberOfSolutions are deployed successfully. Waiting $i of 20 .."		
		SLEEP 20
	}
}

ECHO ""

if($solutionsStatusOk -lt $numberOfSolutions){
ECHO "An Error occured can not continue with deployment, please check errors with solutions deployment"
exit
}


