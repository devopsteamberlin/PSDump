function EnsureSessionStateIsEnabled(){
	Write-Message "OPALOC: Turning on session state in content web applications..." "green"
	Enable-SPSessionStateService -DefaultProvision	
	Write-Message "OPALOC: Completed." "green"
}

function ImportManagedMetadata(){
	Write-Message "OPALOC: Importing term store..." "green"
	Import-ManagedMetadataStore "$DataFolder\InitialTermStore.cab"	
}
