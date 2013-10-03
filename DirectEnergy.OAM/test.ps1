
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

function Deploy-Solution([string]$configFile, [string] $accountSiteUrl, [string] $adminSiteUrl)
{
if($accountSiteUrl -ne [string]::Empty -and $adminSiteUrl -ne [string]::Empty){
			$webAppElements = @($accountSiteUrl, $adminSiteUrl)
		}
		else{		
			$webAppElements = $_.WebApplications.WebApplication
		}
		
		$webAppElements | ForEach-Object {
			[System.Windows.Forms.MessageBox]::Show($_)
		}
}

# WebApplication Url in Deploy-Input.xml will be overriden by the values set here.
$ACCOUNTS_WEB_APPLICATION_URL = "http://sp2010riyaz:9050"
$ADMIN_WEB_APPLICATION_URL = "http://sp2010riyaz:9080"

Deploy-Solution -configFile Deploy-Input.xml -accountSiteUrl $ACCOUNTS_WEB_APPLICATION_URL -adminSiteUrl $ADMIN_WEB_APPLICATION_URL