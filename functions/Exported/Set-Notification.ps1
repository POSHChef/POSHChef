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


function Set-Notification {

	<#

	.SYNOPSIS
		Adds the named services to the notifications file for restart

	.DESCRIPTION
		Many resources have the ability to notify services of a restart
		This cmdlet allows the resource to simply update this file without having to work out the location itself

	#>

	[CmdletBinding()]
	param (

		[Parameter(Mandatory=$true)]
		[AllowEmptyString()]
		[AllowNull()]
		[string[]]
		# Array of services that need to be notified of a restart
		$Notifies,

		[string]
		# Path to the services notifications file
		$NotifiesServicePath,

		[string]
		# Set the basedir for where POSHChef should store configuration files, keys
		# logs, cache and generated mof file
		$basedir = "C:\POSHChef",

		[string]
		# Path to the configuration file to use
		# If left blank the default 'knife.psd1' will be used
		$config = [String]::Empty
	)
	
	# Get the module information
	$moduleinfo = Get-Module -Name POSHChef

	# Patch the $PSBoundParameters to contain the default values
	# if they have not been explicitly set
	foreach ($param in @("basedir")) {
		if (!$PSBoundParameters.ContainsKey($param)) {
			$PSBoundParameters.$param = (Get-Variable -Name $param).Value
		}
	}
	
	Set-LogParameters -targets @{logProvider="devnull"; verbosity="info";}

	# Initialize the sesion and configure global variables
	# Pass the module information so that it can be added to the session configuration
	Initialize-Session -Parameters $PSBoundParameters -moduleinfo $moduleinfo
	
	# Read the configuration file
	Get-Configuration -config $config
	
	# If the NotifiesServicePath is empty then build it up from the configuration
	if ([String]::IsNullOrEmpty($NotifiesServicePath)) {
		$NotifiesServicePath = "{0}\services.txt" -f $script:session.config.paths.notifications
	}
	
	# If there are items to notify iterate around each one and add to the file
	if ($Notifies.count -gt 0) {
		Write-Verbose $NotifiesServicePath
		Write-Verbose ("Service notifications: {0}" -f ($notifies -join "`n"))
		Add-Content -Path $NotifiesServicePath -Value ($notifies -join "`n")	
	}
}
