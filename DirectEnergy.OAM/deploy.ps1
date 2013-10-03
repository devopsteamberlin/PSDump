Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

function Get-ScriptDirectory 
{ 
	Split-Path $script:MyInvocation.MyCommand.Path
} 

function InsertWcfServiceEndpoints($WebApp){

	Write-Host "Inserting DE OAM WCF Service End Points.... on web application - "$WebApp.DisplayName
	
	#Adding the bindings section
	$configSectionBindings = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification
	$configSectionBindings.Path = "configuration/system.serviceModel"
	$configSectionBindings.Name = "bindings"
	$configSectionBindings.Sequence = 0
	$configSectionBindings.Type = 2
	$configSectionBindings.Value = "bindings"
	$configSectionBindings.Owner="OAMWCF"

	$configSectionhttpBindings = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification
	$configSectionhttpBindings.Path = "configuration/system.serviceModel/bindings"
	$configSectionhttpBindings.Name = "basicHttpBinding"
	$configSectionhttpBindings.Sequence = 0
	$configSectionhttpBindings.Type = 2
	$configSectionhttpBindings.Value = "basicHttpBinding"
	$configSectionhttpBindings.Owner="OAMWCF"

	$configModB1 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification
	$configModB1.Path = "configuration/system.serviceModel/bindings/basicHttpBinding"
	$configModB1.Sequence = 1
	$configModB1.Type = 0
	$configModB1.Name = "binding[@name='BasicHttpBinding_IOAMAuthenticationProviderService']"
	$configModB1.Owner = "OAMWCF"
	$configModB1.Value = "<binding name='BasicHttpBinding_IOAMAuthenticationProviderService' closeTimeout='00:01:00' openTimeout='00:01:00' receiveTimeout='00:10:00' sendTimeout='00:01:00' allowCookies='false' bypassProxyOnLocal='false' hostNameComparisonMode='StrongWildcard' maxBufferSize='65536' maxBufferPoolSize='524288' maxReceivedMessageSize='65536' messageEncoding='Text' textEncoding='utf-8' transferMode='Buffered' useDefaultWebProxy='true'><readerQuotas maxDepth='32' maxStringContentLength='8192' maxArrayLength='16384' maxBytesPerRead='4096' maxNameTableCharCount='16384' /><security mode='None'><transport clientCredentialType='None' proxyCredentialType='None' realm='' /><message clientCredentialType='UserName' algorithmSuite='Default' /></security> </binding>"

	$configModB2 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification
	$configModB2.Path = "configuration/system.serviceModel/bindings/basicHttpBinding"
	$configModB2.Sequence = 2
	$configModB2.Type = 0
	$configModB2.Name = "binding[@name='BasicHttpBinding_IOAMAuthenticationProviderService1']"
	$configModB2.Owner = "OAMWCF"
	$configModB2.Value = "<binding name='BasicHttpBinding_IOAMAuthenticationProviderService1' closeTimeout='00:01:00' openTimeout='00:01:00' receiveTimeout='00:10:00' sendTimeout='00:01:00' allowCookies='false' bypassProxyOnLocal='false' hostNameComparisonMode='StrongWildcard' maxBufferSize='65536' maxBufferPoolSize='524288' maxReceivedMessageSize='65536' messageEncoding='Text' textEncoding='utf-8' transferMode='Buffered' useDefaultWebProxy='true'> <readerQuotas maxDepth='32' maxStringContentLength='8192' maxArrayLength='16384' maxBytesPerRead='4096' maxNameTableCharCount='16384' /><security mode='None'><transport clientCredentialType='None' proxyCredentialType='None' realm='' /><message clientCredentialType='UserName' algorithmSuite='Default' /></security></binding>"

	$configModB3 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification
	$configModB3.Path = "configuration/system.serviceModel/bindings/basicHttpBinding"
	$configModB3.Sequence = 2
	$configModB3.Type = 0
	$configModB3.Name = "binding[@name='BasicHttpBinding_IOAMService']"
	$configModB3.Owner = "OAMWCF"
	$configModB3.Value = "<binding name='BasicHttpBinding_IOAMService' closeTimeout='00:01:00' openTimeout='00:01:00' receiveTimeout='00:10:00' sendTimeout='00:01:00' allowCookies='false' bypassProxyOnLocal='false' hostNameComparisonMode='StrongWildcard' maxBufferSize='1310720' maxBufferPoolSize='524288' maxReceivedMessageSize='1310720' messageEncoding='Text' textEncoding='utf-8' transferMode='Buffered' useDefaultWebProxy='true'><readerQuotas maxDepth='32' maxStringContentLength='8192' maxArrayLength='16384' maxBytesPerRead='4096' maxNameTableCharCount='16384' /><security mode='None'><transport clientCredentialType='None' proxyCredentialType='None' realm='' /><message clientCredentialType='UserName' algorithmSuite='Default' /></security></binding>"


	#Adding the client section
	$configSectionClient = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification
	$configSectionClient.Path = "configuration/system.serviceModel"
	$configSectionClient.Name = "client"
	$configSectionClient.Sequence = 0
	$configSectionClient.Type = 2
	$configSectionClient.Value = "client"

	$configModC1 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification
	$configModC1.Path = "configuration/system.serviceModel/client"
	$configModC1.Name  =  "endpoint[@name='BasicHttpBinding_IOAMAuthenticationProviderService']"   
	$configModC1.Sequence = 1
	$configModC1.Type = 0
	$configModC1.Owner = "OAMWCF"
	$configModC1.Value = "<endpoint address='http://localhost:8080/OamUserAuthenticationProviderService.svc' binding='basicHttpBinding' bindingConfiguration='BasicHttpBinding_IOAMAuthenticationProviderService' contract='OAMUserAuthenticationService.IOAMAuthenticationProviderService' name='BasicHttpBinding_IOAMAuthenticationProviderService' />"

	$configModC2 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification
	$configModC2.Path = "configuration/system.serviceModel/client"
	$configModC2.Name  =  "endpoint[@name='BasicHttpBinding_IOAMAuthenticationProviderService1']"  
	$configModC2.Sequence = 2
	$configModC2.Type = 0
	$configModC2.Owner = "OAMWCF"
	$configModC2.Value = "<endpoint address='http://localhost:8080/OamAdminAuthenticationProviderService.svc' binding='basicHttpBinding' bindingConfiguration='BasicHttpBinding_IOAMAuthenticationProviderService1'  contract='OAMAdminAuthenticationService.IOAMAuthenticationProviderService' name='BasicHttpBinding_IOAMAuthenticationProviderService1' />"


	$configModC3 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification
	$configModC3.Path = "configuration/system.serviceModel/client"
	$configModC3.Name  =  "endpoint[@name='BasicHttpBinding_IOAMService']"
	$configModC3.Sequence = 3
	$configModC3.Type = 0
	$configModC3.Owner = "OAMWCF"
	$configModC3.Value = "<endpoint address='http://localhost:8080/OamService.svc' binding='basicHttpBinding' bindingConfiguration='BasicHttpBinding_IOAMService' contract='OAMService.IOAMService' name='BasicHttpBinding_IOAMService' />"


	# Add mods, update, and apply
	$WebApp.WebConfigModifications.Add($configSectionBindings )
	$WebApp.WebConfigModifications.Add($configSectionhttpBindings)
	$WebApp.WebConfigModifications.Add( $configModB1 )
	$WebApp.WebConfigModifications.Add( $configModB2 )
	$WebApp.WebConfigModifications.Add( $configModB3 )

	$WebApp.WebConfigModifications.Add( $configSectionClient )
	$WebApp.WebConfigModifications.Add( $configModC1 )
	$WebApp.WebConfigModifications.Add( $configModC2 )
	$WebApp.WebConfigModifications.Add( $configModC3 )

	$WebApp.Update()
	$WebApp.Parent.ApplyWebConfigModifications()
	
	Write-Host "Successfully completed, Inserting DE OAM WCF Service End Points.... on web application - "$WebApp.DisplayName
}

function ConfigureAdditionalAuthenticationProviders($WebApp){

Write-Host "Configuring additional authentication providers.... on web application - "$WebApp.DisplayName

$configModM1 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification
$configModM1.Path = "configuration/system.web/membership/providers"
$configModM1.Name  =  "add[@name='OAMMembershipProvider']"   
$configModM1.Sequence = 0
$configModM1.Type = 0
$configModM1.Owner = "OAMMemberhsip"
$configModM1.Value = "<add name='OAMMembershipProvider' type='DirectEnergy.Authentication.Provider.OAMMembershipProvider, DirectEnergy.Authentication, Version=1.0.0.0, Culture=neutral, PublicKeyToken=b6a416a3e4d1c768' authenticationServiceUrl='http://localhost:8080/OamUserAuthenticationProviderService.svc' />"


$configModR1 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification
$configModR1.Path = "configuration/system.web/roleManager/providers"
$configModR1.Name  =  "add[@name='OAMRoleProvider']"   
$configModR1.Sequence = 0
$configModR1.Type = 0
$configModR1.Owner = "OAMMemberhsip"
$configModR1.Value = "<add name='OAMRoleProvider' type='DirectEnergy.Authentication.Provider.OAMRoleProvider, DirectEnergy.Authentication, Version=1.0.0.0, Culture=neutral, PublicKeyToken=b6a416a3e4d1c768' authenticationServiceUrl='http://localhost:8080/OamUserAuthenticationProviderService.svc'  />"

	
# Add mods, update, and apply
$WebApp.WebConfigModifications.Add( $configModM1 )
$WebApp.WebConfigModifications.Add( $configModR1 )
	
    
$WebApp.Update()
$WebApp.Parent.ApplyWebConfigModifications()

Write-Host "Successfully configured additional authentication providers.... on web application - "$WebApp.DisplayName

}

function ConfigureAnonymousPlusCustomAuthenticationProvider($WebApp){

Write-Host "Begin executing - ConfigureAnonymousPlusCustomAuthenticationProvider.... on web application - "$WebApp.DisplayName

#Set additional Authentication Providers
$anoAp = new-SPAuthenticationProvider -AllowAnonymous
$oamProv = new-SPAuthenticationProvider -ASPNETMembershipProvider "OAMMembershipProvider" -ASPNETRoleProviderName "OAMRoleProvider"

Set-SPWebApplication -AuthenticationProvider $anoAp, $oamProv -Identity $webApp -Zone "Default"

Write-Host "Successfully executed - ConfigureAnonymousPlusCustomAuthenticationProvider.... on web application - "$WebApp.DisplayName

}

function SetupSharedSession($WebApp){

	Write-Host "Begin executing - SetupSharedSession.... on web application - "$WebApp.DisplayName
		
	Write-Output "now adding the entries for sharing sessions between applications"
 
 	$configModM1 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification
	$configModM1.Path = "configuration/system.webServer/modules"
	$configModM1.Name  =  "add[@name='SharedSessionModule']"   
 	$configModM1.Sequence = 0
	$configModM1.Type = 0
	$configModM1.Owner = "OAMSharedSessionModule"
	$configModM1.Value = "<add name='SharedSessionModule' type='DirectEnergy.OAM.Modules.SharedSessionModule, DirectEnergy.OAM, Version=1.0.0.0, Culture=neutral, PublicKeyToken=b6a416a3e4d1c768' />"


	$configModR1 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification
	$configModR1.Path = "configuration/appSettings"
	$configModR1.Name  =  "add[@key='ApplicationName']"   
 	$configModR1.Sequence = 0
	$configModR1.Type = 0
	$configModR1.Owner = "OAMSharedSessionModule"
	$configModR1.Value = "<add key='ApplicationName' value='SharedWeb' />"

		
    # Add mods, update, and apply
	$WebApp.WebConfigModifications.Add( $configModM1 )
	$WebApp.WebConfigModifications.Add( $configModR1 )
		
        
    $WebApp.Update()
    $WebApp.Parent.ApplyWebConfigModifications()
	
	Write-Host "Successfully executed - SetupSharedSession.... on web application - "$WebApp.DisplayName

}

Start-SPAssignment -Global

# Account Sites
# Load up our 1_SPWebApplication_9050.ps1 functions 
#$myaccount_SPWebApplication = Join-Path (Get-ScriptDirectory) "\New_WebClaim.ps1";
#. $myaccount_SPWebApplication -account "domainx\sp2010installer" -url "http://sp2010riyaz" -port "9050" -apppool "DE_OAM_Brand1"

#Admin Web Application
#. $myaccount_SPWebApplication -account "domainx\sp2010installer" -url "http://sp2010riyaz" -port "9080" -apppool "DE_OAM_Admin"

InsertWcfServiceEndpoints -WebApp (Get-SPWebApplication "http://sp2010riyaz:9050")
#InsertWcfServiceEndpoints -WebApp (Get-SPWebApplication "http://sp2010riyaz:9080")

ConfigureAdditionalAuthenticationProviders -WebApp (Get-SPWebApplication "http://sp2010riyaz:9050")
#ConfigureAdditionalAuthenticationProviders -WebApp (Get-SPWebApplication "http://sp2010riyaz:9080")

ConfigureAnonymousPlusCustomAuthenticationProvider -WebApp (Get-SPWebApplication "http://sp2010riyaz:9050")
#ConfigureAnonymousPlusCustomAuthenticationProvider -WebApp (Get-SPWebApplication "http://sp2010riyaz:9080")

SetupSharedSession -WebApp (Get-SPWebApplication "http://sp2010riyaz:9050")
#SetupSharedSession -WebApp (Get-SPWebApplication "http://sp2010riyaz:9080")

Stop-SPAssignment -Global