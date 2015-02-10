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


function Set-Configuration {

	<#

	.SYNOPSIS
	Cmdlet that writes out the configuration file for POSHChef

	#>

	[CmdletBinding()]
	param (

		[string]
		$server,

		[string]
		$nodename,

		[string]
		$keeplogs,

		[string]
		$environment,

		[string]
		$nugetsource

	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -EventId PC_DEBUG_0017 -extra $MyInvocation.MyCommand

	# Get the path to the configuration file so it can be written to
	$chef_config_file = "{0}\client.psd1" -f $script:session.config.paths.conf

	# crreate a literal representation of a PSD1 file
	$filedata = @"

@{

	# Address of the chef server
	server = '$server'

	# Name that this node should be known as on the chef server
	node = '$nodename'

	# Environment that this machine belongs to
	environment = '$environment'

	# Nuget Server from which the system will check for updates
	nugetsource = '$nugetsource'

	# The number of log directories to keep
	logs = @{

		keep = $keeplogs

	}
}

"@ 

	# write this data file out to the $chef_config_file
	Set-Content -Path $chef_config_file -Value $filedata
}
