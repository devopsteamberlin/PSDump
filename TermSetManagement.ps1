### Initialize environment
Set-ExecutionPolicy RemoteSigned

# Load SharePoint PS snap-in.
Add-Type -AssemblyName "Microsoft.SharePoint, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c"
$snapin = Get-PsSnapin Microsoft.SharePoint.PowerShell -ea SilentlyContinue

if ($snapin -eq $null) {
    Add-PsSnapin Microsoft.SharePoint.PowerShell
}

$rootUrl = "http://sp2010riyaz:65535"

###############################################################################
# Writes a message to the output and to the log file.
###############################################################################
function Write-Message ($message, $foregroundColor, $writeToLog = $true) {
    if($message -ne $null) {
        Write-Host $message -foregroundcolor $foregroundColor
        
        #if($writeToLog -eq $true) {
            #$stamp = Get-Date -format "yyyy-MM-dd HH:mm:ss"
            #$stampedMessage = $stamp + "  " + $message
            #$stampedMessage | Out-File -FilePath $Log -Width 255 -Append -Force
        #}
    }
}

function Remove-TermOnTermSet([string]$termSet, [string]$term2Remove){
	$hubSiteUrl = $rootUrl + "/CPDMCNTHUB"
	$hubSite = new-object Microsoft.SharePoint.SPSite($hubSiteUrl)
	$taxonomySession = new-object Microsoft.SharePoint.Taxonomy.TaxonomySession($hubSite)
	
	if ($taxonomySession.DefaultKeywordsTermStore -ne $null)
    {
	  # Get the default metadata service application
      $spTermStore = $taxonomySession.DefaultKeywordsTermStore;
	}
	
	$taxonomyGroup = $spTermStore.Groups["Document and Records Management"]
	
	$spTermSet = $taxonomyGroup.TermSets[$termSet]	
	if ($spTermSet -ne $null){
		$term2Del = $spTermSet.Terms[$term2Remove]
		if ($term2Del -ne $null){
			$term2Del.Delete()
			$spTermStore.CommitAll()
			Write-Message "`tDeleted term [`"$term2Remove`"] successfully." -ForegroundColor Green
		}
		else{
			Write-Message "`tCould not find the term [`"$term2Remove`"]." -ForegroundColor Yellow
		}
	}
	else{
		Write-Message "`tTerm set [`"$termSet`"] does not exisits." -ForegroundColor Red
	}
}

function Create-TermOnTermSet([string]$termSet, [string]$terms2Add){
	
	$hubSiteUrl = $rootUrl + "/CPDMCNTHUB"
	$hubSite = new-object Microsoft.SharePoint.SPSite($hubSiteUrl)
	$taxonomySession = new-object Microsoft.SharePoint.Taxonomy.TaxonomySession($hubSite)
	
	if ($taxonomySession.DefaultKeywordsTermStore -ne $null)
    {
	  # Get the default metadata service application
      $spTermStore = $taxonomySession.DefaultKeywordsTermStore;
	}
	
	$taxonomyGroup = $spTermStore.Groups["Document and Records Management"]	
	$spTermSet = $taxonomyGroup.TermSets[$termSet]
	
	if ($spTermSet -ne $null){
		try{
			$termAlreadyPresent = $spTermSet.Terms[$terms2Add]
			if ($termAlreadyPresent -eq $null){
				$spTermSet.CreateTerm($terms2Add, 1033)
				$spTermStore.CommitAll();
				Write-Message "`tCreated term [`"$terms2Add`"] successfully." -ForegroundColor Green
			}
			else{
				Write-Message "`tTerm [`"$terms2Add`"] already exists." -ForegroundColor Yellow
			}
		}
		catch{
			Write-Message "Cannot continue. An error occurred: $_" "red"
			exit -1
		}		
	}
	else{
		Write-Message "`tTerm set [`"$termSet`"] does not exisits." -ForegroundColor Red
	}	
}

function Create-TermSet([Microsoft.SharePoint.Taxonomy.TermStore]$termStore, [string]$termSet){
	
	$hubSiteUrl = $rootUrl + "/CPDMCNTHUB"
	$hubSite = new-object Microsoft.SharePoint.SPSite($hubSiteUrl)
	$taxonomySession = new-object Microsoft.SharePoint.Taxonomy.TaxonomySession($hubSite)
	
	if ($taxonomySession.DefaultKeywordsTermStore -ne $null)
    {
	  # Get the default metadata service application
      $spTermStore = $taxonomySession.DefaultKeywordsTermStore;
	}
	
	$taxonomyGroup = $spTermStore.Groups["Document and Records Management"]	
	$spTermSet = $taxonomyGroup.TermSets[$termSet]
	
	if ($spTermSet -eq $null){
		try{
			$spTermSet = $taxonomyGroup.CreateTermSet($termSet)			
			$spTermStore.CommitAll();
			Write-Message "`tCreated term set [`"$termSet`"] successfully." -ForegroundColor Green
		}
		catch{
			Write-Message "Cannot continue. An error occurred: $_" "red"
			exit -1
		}		
	}
	else{
		Write-Message "`tTerm set [`"$termSet`"] already exisits." -ForegroundColor Yellow
	}	
}

# TermStore Update
Write-Message "Configuring managed metadata service application data..." "cyan"

	try{
		#Elevated priveleges block to accommodate running scripts remotely on a server with UAC enabled.
		[Microsoft.SharePoint.SPSecurity]::RunWithElevatedPrivileges({	
		
			$hubSiteUrl = $rootUrl + "/CPDMCNTHUB"
			$hubSite = new-object Microsoft.SharePoint.SPSite($hubSiteUrl)
			$taxonomySession = new-object Microsoft.SharePoint.Taxonomy.TaxonomySession($hubSite)
			if ($taxonomySession.DefaultKeywordsTermStore -ne $null)
		    {
			  # Get the default metadata service application
		      $spTermStore = $taxonomySession.DefaultKeywordsTermStore;	
			  
			  # Bug 67526 fix ------------------------------------------------------			  
			  Remove-TermOnTermSet -termSet "Project Controls Support" -term2Remove "SF-3 02-12 Lessons Learned Template"
			  Create-TermOnTermSet -termSet "Project Controls Support" -terms2Add "SF-3.02-12 Lessons Learned Template"
			  			  
			  # Bug 67516 fix ------------------------------------------------------
			  Remove-TermOnTermSet -termSet "Departmental Management Document Type" -term2Remove "APfR Ratings Spreadsheet"
			  Create-TermOnTermSet -termSet "Departmental Management Document Type" -terms2Add "Departmental Management Document Type"
			  			  
			  # Bug 67493 fix ------------------------------------------------------			  
			  Create-TermOnTermSet -termStore $spTermStore -termSet "Pre-Project Information Document Type" -terms2Add "Pre-Project Information Document"
			  
			  # Bug 67516 fix ------------------------------------------------------
			  Create-TermOnTermSet -termSet "Administration Document Type" -terms2Add "Construction GL Strings"
			  Create-TermOnTermSet -termSet "Administration Document Type" -terms2Add "Engineering GL Strings"
			  Create-TermOnTermSet -termSet "Administration Document Type" -terms2Add "Office Supply List"
			  #
			  Remove-TermOnTermSet -termSet "Project Close" -term2Remove "PM-8.01 Acceptance by Operations Process Map"
			  Remove-TermOnTermSet -termSet "Project Close" -term2Remove "PM-8.01 Acceptance by Operations"
			  Remove-TermOnTermSet -termSet "Project Close" -term2Remove "PM-8.02 Close Contracts Process Map"
			  Remove-TermOnTermSet -termSet "Project Close" -term2Remove "PM-8.02 Close Contracts"
			  Remove-TermOnTermSet -termSet "Project Close" -term2Remove "PM-8.03 Financial Close Process Map"
			  Remove-TermOnTermSet -termSet "Project Close" -term2Remove "PM-8.03 Financial Close"
			  Remove-TermOnTermSet -termSet "Project Close" -term2Remove "PM-8.04 Close Technical Records Process Map"
			  Remove-TermOnTermSet -termSet "Project Close" -term2Remove "PM-8.04 Close Technical Records"
			  Remove-TermOnTermSet -termSet "Project Close" -term2Remove "PM-8.05 Close Project Team Process Map"
			  Remove-TermOnTermSet -termSet "Project Close" -term2Remove "PM-8.05 Close Project Team"
			  Remove-TermOnTermSet -termSet "Project Close" -term2Remove "PM-8.06 Post Implementation First Review Process Map"
			  Remove-TermOnTermSet -termSet "Project Close" -term2Remove "PM-8.06 Post Implementation First Review"
			  Remove-TermOnTermSet -termSet "Project Close" -term2Remove "PM-8.07 Post Implementation Second Review Process Map"
			  Remove-TermOnTermSet -termSet "Project Close" -term2Remove "PM-8.07 Post Implementation Second Review"
			  
			  Create-TermOnTermSet -termSet "Project Close" -terms2Add "SF-8.01-01 Internal Commercial Operations Date Notice"
			  Create-TermOnTermSet -termSet "Project Close" -terms2Add "SF-8.02-01 Temporary Acceptance Certificate"
			  Create-TermOnTermSet -termSet "Project Close" -terms2Add "SF-8.02-02 Temporary Acceptance Certificate Log"
			  Create-TermOnTermSet -termSet "Project Close" -terms2Add "SF-8.02-03 Final Acceptance Certificate"
			  Create-TermOnTermSet -termSet "Project Close" -terms2Add "SF-8.03-01 Initial and Final Cost Breakdown and Asset Lives Form"
			  Create-TermOnTermSet -termSet "Project Close" -terms2Add "SF-8.04-01 Close Records Document Checklist"
			  Create-TermOnTermSet -termSet "Project Close" -terms2Add "SF-8.04-02 Close Records Activity Checklist"
			  Create-TermOnTermSet -termSet "Project Close" -terms2Add "SF-8.04-03 Equipment Warranty Expiry Form"
			  Create-TermOnTermSet -termSet "Project Close" -terms2Add "SF-8.06.01 Post Implementation Review Report Template"
			  Create-TermOnTermSet -termSet "Project Close" -terms2Add "SF-8.06.02 Post Implementation Review Attachment Template"
			  Create-TermOnTermSet -termSet "Project Close" -terms2Add "SF-8.06.03 Post Implementation Review RACI"
			  Create-TermOnTermSet -termSet "Project Close" -terms2Add "SF-8.06.04 Lessons Learned and Recommendations Summary Template"		  
			  #
			  Remove-TermOnTermSet -termSet "Engineering Project Forms" -term2Remove "Construction Change Request_Approval Template"
			  			  
			  Create-TermOnTermSet -termSet "Engineering Project Forms" -terms2Add "Construction Change Request and Approval Template"
			  #			  
			  Remove-TermOnTermSet -termSet "Drafting Document Type" -term2Remove "Floor Plan and Elevations"
			  Remove-TermOnTermSet -termSet "Drafting Document Type" -term2Remove "Site Layouts"			  
			  Remove-TermOnTermSet -termSet "Drafting Document Type" -term2Remove "IT"			  
			  Remove-TermOnTermSet -termSet "Drafting Document Type" -term2Remove "Drafting Completed APfRs"
			  Remove-TermOnTermSet -termSet "Drafting Document Type" -term2Remove "Document Control Completed APfRs"			  
						  
			  Create-TermOnTermSet -termSet "Drafting Document Type" -terms2Add "Drafting KPIs"			  
			  Create-TermOnTermSet -termSet "Drafting Document Type" -terms2Add "Drafting Standards"
			  Create-TermOnTermSet -termSet "Drafting Document Type" -terms2Add "IT Outstanding Issues"			  
			  Create-TermOnTermSet -termSet "Drafting Document Type" -terms2Add "Maintenance Contract"
			  #
			  Create-TermSet -termSet "Project Management Document Type - CE"
			  
			  Create-TermOnTermSet -termSet "Project Management Document Type - CE" -terms2Add "Engineering Work Hours"
			  Create-TermOnTermSet -termSet "Project Management Document Type - CE" -terms2Add "GL Codes"
			  Create-TermOnTermSet -termSet "Project Management Document Type - CE" -terms2Add "Request for Proposal Reviews"
			  Create-TermOnTermSet -termSet "Project Management Document Type - CE" -terms2Add "Project Lists"
			  Create-TermOnTermSet -termSet "Project Management Document Type - CE" -terms2Add "Project Schedule"
			  Create-TermOnTermSet -termSet "Project Management Document Type - CE" -terms2Add "Project Reports"
			  Create-TermOnTermSet -termSet "Project Management Document Type - CE" -terms2Add "Section Reports"
			  Create-TermOnTermSet -termSet "Project Management Document Type - CE" -terms2Add "Oracle Projects Initiatives"
			  Create-TermOnTermSet -termSet "Project Management Document Type - CE" -terms2Add "Value Engineering"
			  Create-TermOnTermSet -termSet "Project Management Document Type - CE" -terms2Add "Engineering Service Agreements"
			  Create-TermOnTermSet -termSet "Project Management Document Type - CE" -terms2Add "Contractor Hours Spreadsheet"
			  Create-TermOnTermSet -termSet "Project Management Document Type - CE" -terms2Add "Monthly Contractor Hours Tracker"
			  Create-TermOnTermSet -termSet "Project Management Document Type - CE" -terms2Add "Shared Cost Spreadsheet"
			  Create-TermOnTermSet -termSet "Project Management Document Type - CE" -terms2Add "Monthly Project Controls and Forecasting Report"
			  Create-TermOnTermSet -termSet "Project Management Document Type - CE" -terms2Add "Project Cost Report"
			  Create-TermOnTermSet -termSet "Project Management Document Type - CE" -terms2Add "Monthly Cost Report from Leads"
			  Create-TermOnTermSet -termSet "Project Management Document Type - CE" -terms2Add "Project Management Periodic"
			  Create-TermOnTermSet -termSet "Project Management Document Type - CE" -terms2Add "Analysis View"
			  Create-TermOnTermSet -termSet "Project Management Document Type - CE" -terms2Add "Portfolio Forecasts Status"
			  Create-TermOnTermSet -termSet "Project Management Document Type - CE" -terms2Add "Monthly Forecasts"
			  Create-TermOnTermSet -termSet "Project Management Document Type - CE" -terms2Add "Business Intelligence Data"		  
			}		
		})
	} 
	catch 
	{
		Write-Message "Cannot continue. An error occurred: $_" "red"
		exit -1
	}
