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


function Update-POSHChef {

	<#

	.SYNOPSIS
		Cmdlet to handle the updating of POSHChef

	.DESCRIPTION
		Updating POSHChef using PSGet requires many options, this cmdlet
		provides a wrapper for doing this

	#>

	[CmdletBinding()]
	param (

		[string]
		# Path to the configuration file to use
		# If left blank the default 'knife.psd1' will be used
		# This is so that the Nuget source can be read
		$config = [String]::Empty,

		[string]
		# Set the basedir for where POSHChef should store configuration files, keys
		# logs, cache and generated mof file
		$basedir = "C:\POSHChef",

		[switch]
		# Specify if prerelease packages are ok
		$prerelease,

		[string]
		# Log level to quickly apply to the screen provider
		$loglevel = "info"
	)

	# Get the module information
	$moduleinfo = Get-Module -Name POSHChef

	# Set the log parameters for this function
	if (!$logtargets) {
		$logtargets = @(
				@{logProvider="screen"; verbosity=$loglevel;},
				@{logProvider="logfile"; verbosity="Debug"; logDir=$logdir; logfilename=$logfilename}
		)
	}

	Set-LogParameters -targets $logtargets -resource_path ("{0}\lib\POSHChef.resources" -f (Split-Path -Parent $(Get-Module -Name POSHChef).path))

	# Patch the $PSBoundParameters to contain the default values
	# if they have not been explicitly set
	foreach ($param in @("basedir")) {
		if (!$PSBoundParameters.ContainsKey($param)) {
			$PSBoundParameters.$param = (Get-Variable -Name $param).Value
		}
	}


	# Initialize the sesion and configure global variables
	# Pass the module information so that it can be added to the session configuration
	Initialize-Session -Parameters $PSBoundParameters -moduleinfo $moduleinfo

	# Read the configuration file
	Get-Configuration -config $config

	# Build up the command that will be used to update poshchef
	# Configure the hashtable to pass the relevant parameters
	$splat = @{
		NugetPackageId = "POSHChef"
		NugetSource = $script:session.config.nugetsource
		Destination = "c:\windows\system32\windowspowershell\v1.0\modules"
		Update = $true
	}

	# if prerelease has been set then add to the splat
	if ($prerelease) {
		$splat.prerelease = $true
	}

	# Run the command to perform the update
	Install-Module @splat
}
