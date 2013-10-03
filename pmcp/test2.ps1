#######
#
#	edit-spadmins
#
#	Adds or removes site administrators from all site collections in a given web application
#
#	TODO: Check userinput and handle errors gracefully
#
#######
.SPFunctions.ps1
####################################################################################
#
#	Main script
#
####################################################################################
# Preamble
cls;
write-host "###################################################################################
 
This application adds or removes users from all site collections in
the given Web Application.
 
Here is a list of all Web Applications on the farm" -foregroundcolor yellow;
 
# List the GUIDs of all web apps on this farm
Get-SPWebApplications | ft name, id;
 
write-host "Please copy the GUID for the web application you wish to use by selecting then
clicking the right mouse button."  -foregroundcolor yellow;
 
write-host "
Note that the Central Admin site collection has no name,
but does have a GUID!  Don't select this one by accident!
" -foregroundcolor red;
 
Write-Host "You can paste the GUID by clicking the Right mouse button again" -ForegroundColor yellow;
# Prompt user for GUID to use
$guid = Read-Host -Prompt "GUID";
$guid = $guid.Trim();
 
# Check GUID for correct format
Write-Host "Checking GUID";
switch(Check-GUID($guid)){
	"False" { Write-Host "Error: Invalid GUID.  Exiting..." -ForegroundColor red; return;}
}
 
# Get the specified web app
$webapp = Get-SPWebApp($guid);
 
# Check that webapp has been got and if not inform user
Write-Host "The following Web App will be affected: " $webapp.name;
 
# List out the site collections (and their admins) that will be changed and prompt to continue
Write-Host "The following site collections will be affected" -ForegroundColor yellow;
foreach ($site in $webapp.Sites){
	Write-Host $site.url;
	$web = $site.openweb();
	$web.SiteAdministrators | ft LoginName;
}
 
$continue = Read-Host -Prompt "Continue? (y|n)&gt;";
switch($continue){
	"y" {break;}
	default {Write-Host "Exiting..." -ForegroundColor red; return;}
}
 
# Is this operataion adding or removing users from Site Collection Administrators
Write-Host "Are you adding or removing users from Site Collection Administrators?" -ForegroundColor yellow;
$operation = Read-Host -Prompt "(add|remove)";
 
switch($operation){
	"add" {
		#Write-Host "The adding functionality has not been written yet" -ForegroundColor red; return;
		Write-Host "Please give a comma delimited list of usernames in format CAIDusername
		e.g. DOMAINuser1,DOMAINuser2,DOMAINuser3 etc." -ForegroundColor yellow;
		$usernames = Read-Host -Prompt "Users";
		#Split the list on the commas
		$username_array = $usernames.Split(",");
 
		$time = Measure-Command {
			foreach ($site in $webapp.Sites){
				foreach ($user in $username_array){
					$domain_username = $user.Split("");
					$email = $domain_username[1] + "@christian-aid.org";
					$command = "stsadm -o adduser -url " + $site.url + " -userlogin $user -useremail $email -Role `"Full Control`" -username $user -siteadmin";
					Write-Host $command;
					Invoke-Expression $command;
					$count_users++;
				}
				$count_sites++;
			}
		}
		Write-Host $count_users "Admin Accounts added to" $count_sites "in" $time.TotalSeconds "seconds." -ForegroundColor yellow;
	}
	"remove" {
		$count_users = 0;
		# Which user(s) do we want to remove from the Site Collection Administrators list?
		# Collect a comma delimited list of usernames in format CAIDusername
		Write-Host "Please give a comma delimited list of users to remove from the site collection administrators
		e.g. DOMAINuser1,DOMAINuser2,DOMAINuser3" -ForegroundColor yellow;
		$usernames = Read-Host -Prompt "Users";
		#Split the list on the commas
		$username_array = $usernames.Split(",");
		$time = Measure-Command {
			foreach ($site in $webapp.Sites){
				$web = $site.openweb();
				$admins = $web.SiteAdministrators;
				foreach ($user in $admins){
					# Check to see whether the user name is in the $username-array
					if ($username_array -contains $user.LoginName){
						$user.IsSiteAdmin = $FALSE;
						$user.Update();
						Write-Host "Removed " $user.LoginName " from Site Administrators on " $web.URL;
						$count_users++
					}
				}
				$count_sites++
			}
		}
		Write-Host $count_users "Admin Accounts removed from" $count_sites "in" $time.TotalSeconds "seconds." -ForegroundColor yellow;
	}
	default {Write-Host "You must type add or remove!  Exiting..." -ForegroundColor red; return;}
}
##############################      End of script     #############################