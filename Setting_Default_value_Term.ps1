$ErrorActionPreference = "Stop"
Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

$url = "http://sp2010riyaz:65535"
$web = Get-SPWeb $url
$taxonomySession = Get-SPTaxonomySession -Site $web.Site
$termStore = $taxonomySession.DefaultKeywordsTermStore;
$taxonomyField = $null

foreach($field in $web.Site.RootWeb.Fields){
	if($field.Id -eq "e22a2b5f-23b5-4799-a316-a73ab5f66bf3"){
	$taxonomyField = [Microsoft.SharePoint.Taxonomy.TaxonomyField]$field
	break
	}
}

$selectedGroup

foreach($group in $termStore.Groups){
	if($group.Name -eq "Capital Power Terms"){
	$selectedGroup = $group
	break
	}
}

$selectedTermSet

foreach($termset in $group.TermSets){
	if($termset.Name -eq "Operations and Maintenance Document Types"){
	$selectedTermSet = $termset
	break
	}
}



[Microsoft.SharePoint.Taxonomy.TaxonomyFieldValue] $defaultValue = New-Object Microsoft.SharePoint.Taxonomy.TaxonomyFieldValue -ArgumentList $taxonomyField
echo "---------------->"$taxonomyField.DefaultValue
echo $selectedTermSet.Terms[0].Labels[0].Term.Id.ToString()

 $defaultValue.PopulateFromLabelGuidPair($selectedTermSet.Terms[0].Labels[0].Term.Id.ToString());
                        $defaultValue.WssId = -1;

                       
                        $defaultValue.TermGuid = $defaultValue.TermGuid.ToLower();

                        $taxonomyField.DefaultValue = $defaultValue.ValidatedString;
						$taxonomyField.UserCreated = $false;
						$taxonomyField.Update($true)
					
						
						$url = "http://sp2010riyaz:65535"
$web1 = Get-SPWeb $url

						foreach($field2 in $web1.Site.RootWeb.Fields){
	if($field2.Id -eq "e22a2b5f-23b5-4799-a316-a73ab5f66bf3"){
	$taxonomyField2 = [Microsoft.SharePoint.Taxonomy.TaxonomyField]$field
	echo $taxonomyField2.DefaultValue
	echo $taxonomyField2.InternalName
	break
	}
}

