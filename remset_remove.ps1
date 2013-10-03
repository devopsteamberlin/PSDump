 $ErrorActionPreference = "Stop"
Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0
 
 $siteURL = "http://sp2010riyaz:65535/CPDMCNTHUB"
    $site = new-object Microsoft.SharePoint.SPSite($siteURL)
	#Access the TermStore data
	[xml]$xmlDoc = Get-Content -Path "C:\mywork\scm\CapitalPower.DocumentManagement\Dev\Main\CapitalPower.DM.Deployment\Application\MMSData\CapitalPowerTermStoreData.xml" -Encoding UTF8
		
    $termStoreName = $xmlDoc.termstore
    if (($termStoreName -ne $null))
    {
        $taxonomySession = new-object Microsoft.SharePoint.Taxonomy.TaxonomySession($site)
        if (($termStoreName.Attributes -ne $null))
        {
            $spTermStore = $taxonomySession.TermStores[$termStoreName.name]
            $group = $xmlDoc.termstore.group

            $spGroup = $spTermStore.Groups[$group.name]
            $termSets = $group.termset
            if (($termSets -ne $null))
            {
                foreach ($termSet in $group.termset)
                {
                    if (($termSet.Attributes -ne $null))
                    {
						if($spGroup -ne $null){
	                        $spTermSet = $spGroup.TermSets[$termSet.name]
	                        if (($spTermSet -ne $null))
	                        {
	                            $spTermSet.Delete()
	                            $spTermStore.CommitAll()
	                        }
						}
                    }
                }
            }
        }
    }

