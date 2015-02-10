<#
Copyright 2014 ASOS.com Limited

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
#>


function Stop-DSCCore {

	<#

	.SYNOPSIS
		Stops the currently running DSC core

	.DESCRIPTION
		When developing DSC resources it can appear that the resources are being cached if they are run too quickly
		in succession.

		The reason for this is that the WMI Provider Host Process hosting the DSC engine is still running and it will use
		the resources therein.  This function will find the process id for the dsccore WMI process and stop it if it
		exists

		This is purely for developmental purposes.

	.LINK
		http://social.technet.microsoft.com/Forums/windowsserver/en-US/58352ed2-869a-45be-ad61-9019bb975cc7/desired-state-configuration-manager-caching-custom-resource-scripts?forum=winserverpowershell

	#>

	# Set log paraneters so that we have access to the help file
	Set-LogParameters -helpfile ("{0}\..\..\lib\POSHChef.resources" -f $PSScriptRoot)

	# Attempt to find the process id for the DSCcore
	$processid = _getDSCProcessId

	while (![String]::IsNullOrEmpty($processid)) {
		
		# attempt to stop the process
		Write-Log -EventId PC_INFO_0052 -extra $processid

		Get-Process -Id $processid | Stop-Process -Force

		# check the process no longer exists
		$processid = _getDSCProcessId
	}
	
	Write-Log -EventId PC_INFO_0051
	
}

function _getDSCProcessId() {
	return Get-WmiObject msft_providers | Where-Object {$_.provider -like 'dsccore'} | Select-Object -ExpandProperty HostProcessIdentifier 
}
