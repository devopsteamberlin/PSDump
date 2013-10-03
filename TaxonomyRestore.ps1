### Initialize environment
Set-ExecutionPolicy RemoteSigned

# Load SharePoint PS snap-in.
Add-Type -AssemblyName "Microsoft.SharePoint, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c"
$snapin = Get-PsSnapin Microsoft.SharePoint.PowerShell -ea SilentlyContinue

if ($snapin -eq $null) {
    Add-PsSnapin Microsoft.SharePoint.PowerShell
}

##########################################################
###  loadXMLFile: checks and load the backup XML file  ###
##########################################################

function loadXMLFile ([string]$fPath) {
    if (Test-Path $fPath) {
        [xml]$xmlDoc = Get-Content $fPath
        $file = Get-ChildItem $fPath
        Write-Host "The backup file: ” $file.Name " has been loaded successfully."
    }
    else {
        Write-Host -ForegroundColor Red "ERROR: The specified file path does not exist!"
        Write-Host "Please run the script with valid file path or enter valid file path when prompted."
        Break
    }
    Return $xmlDoc
}

######################################################################################
###  restoreTermTree: restores terms in the root level and calls restoreChildTerm  ###
######################################################################################

function restoreTermTree ([int]$tsIndex, [int]$tIndex) {
    foreach ($label in $xmlData.TermStore.Group[0].TermSet[$tsIndex].Term[$tIndex].Label) {
        $labelLanguage = $label.GetAttribute("Language")
        if (($label.GetAttribute("IsDefaultForLanguage") -eq "True") -and ($labelLanguage -eq $defaultLanguage)) {
            $labelName = $label.InnerText
            [guid]$termId = $xmlData.TermStore.Group[0].TermSet[$tsIndex].Term[$tIndex].GetAttribute("Id")
            $term = $termSet.CreateTerm($labelName, $labelLanguage, $termId)
        }    
    }
    if ($xmlData.TermStore.Group[0].TermSet[$tsIndex].Term[$tIndex].GetAttribute("IsAvailableForTagging") -eq "False") {$term.IsAvailableForTagging = $False}
    $term.Owner = $xmlData.TermStore.Group[0].TermSet[$tsIndex].Term[$tIndex].GetAttribute("Owner")
    foreach ($label in $xmlData.TermStore.Group[0].TermSet[$tsIndex].Term[$tIndex].Label) {
        $labelLanguage = $label.GetAttribute("Language")
        $labelName = $label.InnerText
        $isDefaultLabel = $False
        if ($label.GetAttribute("IsDefaultForLanguage") -eq "True") {$isDefaultLabel = $True}
        if (!(($isDefaultLabel -eq $True) -and ($labelLanguage -eq $defaultLanguage))) {
            $dummyLabel = $term.CreateLabel($labelName, $labelLanguage, $isDefaultLabel) 
        }    
    }
    if ($xmlData.TermStore.Group[0].TermSet[$tsIndex].Term[$tIndex].Description) {
        foreach ($description in $xmlData.TermStore.Group[0].TermSet[$tsIndex].Term[$tIndex].Description) {
            $descriptionLanguage = $description.GetAttribute("Language")
            $descriptionText = $description.InnerText
            $term.SetDescription($descriptionText, $descriptionLanguage)
        }
    }    
    if ($xmlData.TermStore.Group[0].TermSet[$tsIndex].Term[$tIndex].GetAttribute("IsDeprecated") -eq "True") {$term.Deprecate($True)}
    Write-Host "The term " $term.Name " has been restored as root level item"
    $termStore.CommitAll()
#    $termId = $xmlData.TermStore.Group[0].TermSet[$tsIndex].Term[$tIndex].GetAttribute("Id")
    $childTermIds = $null
    $childTermIds = findChildTerms $tsIndex $termId.ToString()
    if ($childTermIds) {
        foreach ($childTermId in $childTermIds) {
            restoreChildTerm $childTermId $tsIndex $term   
        }
    }
}

######################################################################################
###  findChildTerms: looks for all child terms of a term and returns array of IDs  ###
######################################################################################

function findChildTerms ([int]$ftsIndex, [string]$tId) {
    [System.Collections.ArrayList]$ctArray = @() 
    foreach ($fTerm in $xmlData.TermStore.Group[0].TermSet[$ftsIndex].Term) {
        if ($fTerm.GetAttribute("ParentTermId") -eq $tId) {$ctArray.Add($fTerm.GetAttribute("Id"))}   
    } 
    Return $ctArray
}

###################################################################################################
###  restoreChildTerm: restores complete term items tree under particular root level term item  ###
###################################################################################################

function restoreChildTerm ([string]$chtId, [int]$chtsIndex, [Microsoft.SharePoint.Taxonomy.Term]$pTerm) {
    foreach ($chTerm in $xmlData.TermStore.Group[0].TermSet[$chtsIndex].Term) {
        if ($chTerm.GetAttribute("Id") -eq $chtId) {
            if ($chTerm.GetAttribute("IsReused") -eq "True") {
                [void]$reusedArray.Add([guid]$chTerm.GetAttribute("Id"))
                [void]$parentArray.Add($childTerm.Id)
            }
            else {
                foreach ($chLabel in $chTerm.Label) {
                    $chLabelLanguage = $chLabel.GetAttribute("Language")
                    if (($chLabel.GetAttribute("IsDefaultForLanguage") -eq "True") -and ($chLabelLanguage -eq $defaultLanguage)) {
                        $chLabelName = $chLabel.InnerText
                        $childTerm = $pTerm.CreateTerm($chLabelName, $chLabelLanguage, [guid]$chtId)
                    }    
                }
                if ($chTerm.GetAttribute("IsAvailableForTagging") -eq "False") {$childTerm.IsAvailableForTagging = $False}
                $childTerm.Owner = $chTerm.GetAttribute("Owner")
                foreach ($chLabel in $chTerm.Label) {
                    $chLabelLanguage = $chLabel.GetAttribute("Language")
                    $chLabelName = $chLabel.InnerText
                    $isDefaultLabel = $False
                    if ($chLabel.GetAttribute("IsDefaultForLanguage") -eq "True") {$isDefaultLabel = $True}
                    if (!(($isDefaultLabel -eq $True) -and ($chLabelLanguage -eq $defaultLanguage))) {
                        $dummyLabel = $childTerm.CreateLabel($chLabelName, $chLabelLanguage, $isDefaultLabel) 
                    }    
                }
                if ($chTerm.Description) {
                    foreach ($chDescription in $chTerm.Description) {
                        $chDescriptionLanguage = $chDescription.GetAttribute("Language")
                        $chDescriptionText = $chDescription.InnerText
                        $childTerm.SetDescription($chDescriptionText, $chDescriptionLanguage)
                    }
                }    
                if ($chTerm.GetAttribute("IsDeprecated") -eq "True") {$childTerm.Deprecate($True)}
                Write-Host "The term " $childTerm.Name " has been restored as child item"
                $termStore.CommitAll()
                $chTermId = $chTerm.GetAttribute("Id")
                $childTermIds = $null
                $childTermIds = findChildTerms $chtsIndex $chTermId
                if ($childTermIds) {
                    foreach ($childTermId in $childTermIds) {
                        restoreChildTerm $childTermId $chtsIndex $childTerm   
                    }
                }
            }        
        }   
    }  
}

############################################################
###  restoreReusedTerms: restores all reused term items  ###
############################################################

function restoreReusedTerms() {
    Write-Host "Restoring reused terms."
    $rCount = $reusedArray.Count
    for ($iReused = 0; $iReused -lt $rCount; $iReused+=1) {
        $rpTerm = $termStore.GetTerm($parentArray[$iReused])
        $sourceTerm = $termStore.GetTerm($reusedArray[$iReused])
        $reusedTerm = $rpTerm.ReuseTerm($sourceTerm, $False)
        $termStore.CommitAll()
        Write-Host "The reused term: " $reusedTerm.Name " has been restored."    
    }
}

function TaxonomyRestore($filePath, $hubSiteURL){ 

	$xmlData = loadXMLFile $filePath

	###  Initiate global Variables and ArrayLists  ###
	[System.Collections.ArrayList]$parentArray = @()
	[System.Collections.ArrayList]$reusedArray = @() 

	###  Creates a new taxonomy session  ###
	$hubSite = Get-SPSite $hubSiteURL
	$session = new-object Microsoft.SharePoint.Taxonomy.TaxonomySession($hubSite, $True)

	###  Gets term store object based on the name from backup file (might need to be rewritten to get it from sesssion!)  ###
	$termStoreName = $xmlData.TermStore.GetAttribute("Name")
	$termStore = $session.TermStores[$termStoreName]
	$defaultLanguage = $termStore.DefaultLanguage

	###  Creates a term group  ###   
	$groupName = $xmlData.TermStore.Group.GetAttribute("Name")
	$group = $termStore.CreateGroup($groupName)
	$group.Description = $xmlData.TermStore.Group[0].GetAttribute("Description")
	$termStore.CommitAll()
	Write-Host "The group: " $group.Name " has been restored."

	###  Walks through and restores all term sets in the term group ###
	$tsCount = $xmlData.TermStore.Group[0].TermSet.Count
	for ($i = 0; $i -lt $tsCount; $i+=1) {
	    $termSetName = $xmlData.TermStore.Group[0].TermSet[$i].GetAttribute("Name")
	    [guid]$termSetId = $xmlData.TermStore.Group[0].TermSet[$i].GetAttribute("Id")
	    $termSet = $group.CreateTermSet($termSetName, $termSetId)
	    if ($xmlData.TermStore.Group[0].TermSet[$i].GetAttribute("IsOpenForTermCreation") -eq "True") {$termSet.IsOpenForTermCreation = $True}
	    if ($xmlData.TermStore.Group[0].TermSet[$i].GetAttribute("IsAvailableForTagging") -eq "False") {$termSet.IsAvailableForTagging = $False}
	    if ($xmlData.TermStore.Group[0].TermSet[$i].GetAttribute("Contact")) {$termSet.Contact = $xmlData.TermStore.Group[0].TermSet[$i].GetAttribute("Contact")}
	    if ($xmlData.TermStore.Group[0].TermSet[$i].Stakeholders) {
	        foreach ($stakeholders in $xmlData.TermStore.Group[0].TermSet[$i].Stakeholders) {
	            $stakeholders = $stakeholders.Split()
	            foreach ($stakeholder in $stakeholders) {$termSet.AddStakeholder($stakeholder.Trim("i:0#.w|"))}
	        }    
	    }
	    $termSet.Description = $xmlData.TermStore.Group[0].TermSet[$i].GetAttribute("Description")
	    $termSet.Owner = $xmlData.TermStore.Group[0].TermSet[$i].GetAttribute("Owner")
	    $termStore.CommitAll()
	    Write-Host "The term set: " $termSet.Name " has been restored."

	###  Walks through and initiate restore of all terms in root level by calling retoreTermTree ###    
	    $tCount = $xmlData.TermStore.Group[0].TermSet[$i].Term.Count
	    for ($j = 0; $j -lt $tCount; $j+=1) {
	        $parentTermId = $xmlData.TermStore.Group[0].TermSet[$i].Term[$j].GetAttribute("ParentTermId")
	        if (!$parentTermId) {
	            restoreTermTree $i $j
	        }
	    }
	}
	restoreReusedTerms

	###  Commits all changes in the session and dispose the site object to free alocated memory  ###
	$termStore.CommitAll()
	$hubSite.Dispose()

}

TaxonomyRestore -filePath "C:\mywork\scm\CapitalPower.DocumentManagement\Dev\Main\CapitalPower.DM.Deployment\Application\MMSData\CapitalPowerTermStoreData.xml" -hubSiteURL "http://sp2010riyaz:65535/CPDMCNTHUB"