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


function Get-Configuration {

	<#

	.SYNOPSIS
	Read in the POSHChef configuration from the filesystem

	.DESCRIPTION
	Read in the configuration file, based on convention, into the configuration object

	If the file does not exist then various questions will be asked and the file will be
	dynamically created and then read back in

	#>

	[CmdletBinding()]
	param (

		[switch]
		# Specify if need to look at the knife configuation
		$knife,

		[string]
		# Path to configuration file to use
		$config
	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	Write-Log -Message " "
	Write-Log -EventId PC_INFO_0007

	# Determine the path to the configuraton file
	Write-Log -EventId PC_INFO_0008
	if ($knife -eq $false) {
		$chef_config_file = "{0}\client.psd1" -f $script:session.config.paths.conf
	} else {
		$chef_config_file = "{0}\knife.psd1" -f $script:session.config.paths.conf
	}

	# see if a configuration file has been specified, if it has then check it exists
	if (![String]::IsNullOrEmpty($config)) {
		$chef_config_file = $config
	}

	# set the configuration file path in the session
	$script:session.config.file = $chef_config_file

	Write-Log -EventId PC_MISC_0001 -Extra $chef_config_file

	# Determine if the path exists
	if (!(Test-Path -Path $chef_config_file)) {

		# The file does not exist so error
		Write-Log -EventId PC_ERROR_0016 -extra $chef_config_file -stop -error

	}

	# Read the configuration file in and then set the various parts of the session configuration
	$configuration = Invoke-Expression (Get-Content -Path ($chef_config_file) -raw)

	# set the various parts of the session
	$script:session.config.server = $configuration.server
	$script:session.config.node = $configuration.node
	$script:session.config.client = $configuration.node
	$script:session.config.logs.keep = $configuration.logs.keep
	$script:session.config.nugetsource = $configuration.nugetsource

	# Set the environment for the node, if it is blank then do not bother
	if (![String]::IsNullOrEmpty($configuration.environment)) {
		$script:session.environment = $configuration.environment
	}

	# Set the interval to run the schduled task
	if ($configuration.containskey("interval")) {
		$script:session.task.interval = $configuration.interval
	}

	# Set the path to the cookbooks
	if (![String]::IsNullOrEmpty($configuration.cookbook_path)) {
		$script:session.config.paths.cookbooks = $configuration.cookbook_path
	}

	# if the client_key has been set then set the session based on this
	if (![String]::IsNullOrEmpty($configuration.client_key)) {
		$script:session.config.key = $configuration.client_key
	}

	# if skip items have been specified then add to the configutation
	if ($configuration.containskey("skip") -and $script:session.skip.count -eq 0) {
		$script:session.skip = $configuration.skip
	}

}
