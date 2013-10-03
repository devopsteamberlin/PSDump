### Initialize environment
Set-ExecutionPolicy RemoteSigned

# Load SharePoint PS snap-in.
Add-Type -AssemblyName "Microsoft.SharePoint, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c"
$snapin = Get-PsSnapin Microsoft.SharePoint.PowerShell -ea SilentlyContinue

if ($snapin -eq $null) {
    Add-PsSnapin Microsoft.SharePoint.PowerShell
}

$rootUrl = "http://sp2010riyaz:65535"

function AddNew-ProjectManagementDocumentsCE()
{

$hubSiteUrl = $rootUrl + "/CPDMCNTHUB"
$hubSite = new-object Microsoft.SharePoint.SPSite($hubSiteUrl)
$spWeb = $hubSite.RootWeb
	
$newSiteColumnXML = "<Field ID='{AE32D6A1-3E13-4246-9738-1013EE74C5FC}'
           Type='TaxonomyFieldType'
           DisplayName='Document Type'
           ShowField='Term1033'
           Required='FALSE'
           EnforceUniqueValues='FALSE'
		   Mult='FALSE'
           Group='Capital Power Site Columns'
           StaticName='ProjectManagementDocumentsCE'
           Name='ProjectManagementDocumentsCE'>
    <Customization>
      <ArrayOfProperty>
        <Property>
          <Name>TextField</Name>
          <Value xmlns:q6='http://www.w3.org/2001/XMLSchema' p4:type='q6:string' xmlns:p4='http://www.w3.org/2001/XMLSchema-instance'>{6D7D3040-2B73-463A-A62D-67A9ADF4ACE9}</Value>
        </Property>
      </ArrayOfProperty>
    </Customization>
  </Field>"
  
  $spWeb.AllowUnsafeUpdates = 1;
  $spWeb.Fields.AddFieldAsXml($newSiteColumnXML,$true,[Microsoft.SharePoint.SPAddFieldOptions]::AddFieldToDefaultView);
  $spWeb.AllowUnsafeUpdates = 0;
 }
 
 AddNew-ProjectManagementDocumentsCE