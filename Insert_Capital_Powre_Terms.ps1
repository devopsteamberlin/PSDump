
$MetadataFilePath = "C:\mywork\scm\CapitalPower.DocumentManagement\Dev\Main\CapitalPower.DM.Deployment\Application\MMSData\CapitalPowerTermStoreData.xml"
$TaxonomySiteUrl = "http://sp2010riyaz:65535/CPDMCNTHUB"

$ErrorActionPreference = "Stop"
Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

if($MetadataFilePath -eq $null -or $MetadataFilePath -eq "") {
	Write-Host("An argument '-MetadataFilePath <path>' is required.") -foregroundcolor red
	exit -1
}

if($TaxonomySiteUrl -eq $null -or $TaxonomySiteUrl -eq "") {
	Write-Host("An argument '-TaxonomySiteUrl <url>' is required.") -foregroundcolor red
	exit -1
}

try{

  #Elevated priveleges block to accommodate running scripts remotely on a server with UAC enabled.
  [Microsoft.SharePoint.SPSecurity]::RunWithElevatedPrivileges( {
	
  $folderPath = [System.IO.Path]::GetDirectoryName($MetadataFilePath)
 
  if([System.IO.Directory]::Exists($folderPath) -ne $true){
	Write-Host("A directory at a path `"$folderPath`" does not exist.") -foregroundcolor red
	exit -1
  }  
 
	#Access the TermStore data
	[xml]$TermStoreData = Get-Content -Path $MetadataFilePath -Encoding UTF8

	$mmsApp = Get-SPServiceApplication | ? {$_.TypeName -eq $TermStoreData.termstore.name}
	 if($mmsApp -eq $null){
		Write-Host("Cannot find a service application of type '$TermStoreData.termstore.name'.") -foregroundcolor red
		exit -1
	 }
  
  	$site = Get-SPSite $TaxonomySiteUrl
	$session = new-object Microsoft.SharePoint.Taxonomy.TaxonomySession($site)
	$termstore = $session.TermStores[$TermStoreData.termstore.name]
	
	foreach($datagroup in $TermStoreData.termstore.group){
		## create the group
		if ($termstore.Groups[$datagroup.name] -eq $null)
		{
			$group = $termstore.CreateGroup($datagroup.name);
			Write-Host -ForegroundColor Cyan "Added group "$datagroup.name			
		}
		else{
			$group = $termstore.Groups[$datagroup.name];
			Write-Host -ForegroundColor Cyan "Found group "$datagroup.name			
		}
		
		foreach($datatermSet in $datagroup.termset){
			## create the termset			
			if($group.TermSets.Count -eq 0 -or $group.TermSets[$datatermSet.name] -eq $null){				
				$termset = $group.CreateTermSet($datatermSet.name)
				$termset.Description = $datatermSet.description
				Write-Host -ForegroundColor Cyan "Added termset "$datatermSet.name
			}
						
			# Term Level-1
			foreach($termL1 in $datatermSet.term){				
				## create the termset
				if($termL1 -ne $null -and $termset.Terms[$termL1.name] -eq $null){				
					$NewTermL1 = $termset.CreateTerm($termL1.name, 1033)
					if($termL1.Synonym -ne $null -and $termL1.Synonym -ne [string]::Empty)
					{
						$NewTermL1.CreateLabel($termL1.Synonym, 1033, $false)
					}
					Write-Host -ForegroundColor Cyan "Added term "$termL1.name				
				}
				
				# Term Level-2
				foreach($termL2 in $termL1.term){					
					## create the termset
					if($termL2 -ne $null -and $termset.Terms[$termL2.name] -eq $null){				
						$NewTermL2 = $NewTermL1.CreateTerm($termL2.name, 1033)
						if($termL2.Synonym -ne $null -and $termL2.Synonym -ne [string]::Empty)
						{
							$NewTermL2.CreateLabel($termL2.Synonym, 1033, $false)
						}
						Write-Host -ForegroundColor Cyan "Added term "$termL2.name				
					}
					
					# Term Level-3
					foreach($termL3 in $termL2.term){					
						## create the termset
						if($termL3 -ne $null -and $termset.Terms[$termL3.name] -eq $null){				
							$NewTermL3 = $NewTermL2.CreateTerm($termL3.name, 1033)
							if($termL3.Synonym -ne $null -and $termL3.Synonym -ne [string]::Empty)
							{
								$NewTermL3.CreateLabel($termL3.Synonym, 1033, $false)
							}
							Write-Host -ForegroundColor Cyan "Added term "$termL3.name				
						}
					}
				}				
			}
		}
	}
	
	$termstore.CommitAll()
	
  })
  
} catch {
	Write-Host("Cannot continue. An error occurred: $_") -foregroundcolor red
}