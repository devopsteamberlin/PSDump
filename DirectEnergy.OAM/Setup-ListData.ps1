Start-SPAssignment -Global

$ApplicationScriptsFolder = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
$DataFolder = [System.IO.Path]::Combine($ApplicationScriptsFolder, "Data")
$LogsFolder = "$ApplicationScriptsFolder/Logs"
if(-not (Test-Path $LogsFolder)) {New-Item $LogsFolder -Type Directory | Out-Null}
$Log = "$LogsFolder/" + (Get-Date -format yyyy-MM-dd_HH.mm.ss) + ".log"

function Write-Message ($message, $foregroundColor, $writeToLog = $true) {
    if($message -ne $null) {
        Write-Host $message -foregroundcolor $foregroundColor
        
        if($writeToLog -eq $true) {
            $stamp = Get-Date -format "yyyy-MM-dd HH:mm:ss"
            $stampedMessage = $stamp + "  " + $message
            $stampedMessage | Out-File -FilePath $Log -Width 255 -Append -Force
        }
    }
}

function SetupListData($listDataFile){
	Write-Message "Loading list data file `"$listDataFile`"..." "cyan"
	$fso = Get-Item $listDataFile -ea SilentlyContinue
	if($fso -eq $null) {
		throw "List data file not found at path `"$listDataFile`""
	}
	[xml]$listDataMap = Get-Content $listDataFile	
	foreach($webAppNode in $listDataMap.ListData.WebApplications.WebApplication) {
				
		foreach($siteNode in $webAppNode.SiteCollections.SiteCollection){		
			$siteUrl = $null
			
			if($webAppNode.ManagedPath -ne [string]::Empty){$managedPath = "/" + $webAppNode.ManagedPath;}
			else{$managedPath = "";}
			
			if ($WebAppUrl -eq $null -or $WebAppUrl -eq ""){
				$siteUrl = 	$webAppNode.Url + $managedPath + $siteNode.Url
			}
			else{
				#Allowing to pass the web applicaiton url as parameter.
				$siteUrl = 	$WebAppUrl + $managedPath + $siteNode.Url
			}			
			
			Write-Message "`tProcessing`tSite: $siteUrl..." "cyan"
			
			foreach($listNode in $siteNode.Lists.List) {
				$listDisplayname = $listNode.DisplayName
				$listUrl = $listNode.url
				try{
					[string] $fieldname = [string]::Empty
					
					$web = Get-SPWeb $siteUrl -ErrorAction Stop
        			$list = $web.Lists.TryGetList($listDisplayname)
					
					Write-Message "`t`t`tList: $listUrl..." "cyan"
					
					if($list -ne $null){						
						foreach($listItem in $listNode.Data.Rows.Row){
							
							Write-Message "`t`t`tFields:" "cyan"
							Write-Message "`t`t`t--------" "cyan"
							
							$newItem = $list.Items.Add()
							foreach($fieldValue in $listItem.Field){
								[string]$fieldname = $fieldValue.Name
								
								if($list.BaseType -eq "DocumentLibrary" -and $fieldname.contains("UploadFilePath") -eq $true) {
									
									# Get value after '=' mark
									$fileRelPath = $fieldname.split("=")[1];
									
									# construct the full path
									$resourcePath = [System.IO.Path]::Combine($DataFolder, $fileRelPath)
																		
									#ensure the file is physically available.
									$file = Get-ChildItem $resourcePath
																		
									$fileStream = ([System.IO.FileInfo] (Get-Item $file.FullName)).OpenRead()
    								$contents = new-object byte[] $fileStream.Length
    								$fileStream.Read($contents, 0, [int]$fileStream.Length);
    								$fileStream.Close();
   									Write-Message "`t`t`tCopying $resourcePath to $listDisplayname in $siteUrl..." "Green"
    								$folder = $list.RootFolder
    								$spFile = $folder.Files.Add($folder.Url + "/" + $file.Name, $contents, $true)
    								$newItem = $spFile.Item									
								}
								else{						
									$field = $newItem.Fields | Where-Object {$_.InternalName -eq $fieldname}									
									if($field -ne $null){									
										$fieldValue = $fieldValue.InnerText										
										#$field.Type -eq [Microsoft.SharePoint.SPFieldType]::Integer										
										$newItem[$field.ID] = $fieldValue																				
										Write-Message "`t`t`t[$fieldname => $fieldValue]" "cyan"
									}
									else{
										Write-Message "`t`t`tField '$fieldname' was not found in list '$listDisplayname'. Skipping..." "Red"
									}
								}
		                    }
	                    	$newItem.Update()
						}
						Write-Message "`t`t`tItem Added Successfully." "Green"
						Write-Host ""
					}
				} catch {
					Write-Message "Error Occured, while processing: $listDisplayname. Original error: $_" "red"
				}	
			}
		}
	}
}

### Begin script execution here.
Write-Message  "`r`n***  Script for setting up list data on DirectEnergy.OAM sites ***`r`n" "cyan"

$AdminServiceName = "SPAdminV4"

#Ensure Microsoft.SharePoint.PowerShell is loaded
$snapin="Microsoft.SharePoint.PowerShell"

if (get-pssnapin $snapin -ea "silentlycontinue") {
	write-host -f Green "PSsnapin $snapin is loaded"
}
elseif (get-pssnapin $snapin -registered -ea "silentlycontinue") {
	write-host -f Green "PSsnapin $snapin is registered"
	Add-PSSnapin $snapin
	write-host -f Green "PSsnapin $snapin is loaded"
}
else {
	write-host -f orange "PSSnapin $snapin not found" -foregroundcolor Red
}

#if SPAdminV4 service is not started - start it
if( $(Get-Service $AdminServiceName).Status -eq "Stopped")
{
	#$IsAdminServiceWasRunning = $false
	Start-Service $AdminServiceName
}
	
#if SPAdminV4 service is not started - start it
if( $(Get-Service $AdminServiceName).Status -eq "Stopped")
{
	#$IsAdminServiceWasRunning = $false
	Start-Service $AdminServiceName
}

Write-Message "Log file name: $Log" "white" $false

#Elevated priveleges block to accommodate running scripts remotely on a server with UAC enabled.
[Microsoft.SharePoint.SPSecurity]::RunWithElevatedPrivileges( {	
	try {	
		SetupListData "$DataFolder/ListData.xml"
		Write-Message  "`r`n***  Script Operation Completed Successfully ***`r`n" "cyan"	
		exit 0
	} catch {
	    Write-Message "Failed to provision list data. Error message: `"$_`"" "red"
		exit -1
	}
})	#End of elevated privileges block.

Stop-SPAssignment -Global