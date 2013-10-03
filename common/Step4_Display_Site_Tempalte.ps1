Add-PsSnapin Microsoft.SharePoint.PowerShell

## SharePoint DLL 
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint") 

  $site = Get-SPSite "http://sp2010riyaz:3866"
  
  foreach ($web in $site.AllWebs) { 
       $web | Select-Object -Property Title,Url,WebTemplate 
   }
   $site.Dispose()
   
   Remove-PsSnapin Microsoft.SharePoint.PowerShell