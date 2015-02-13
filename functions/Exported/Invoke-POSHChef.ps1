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

#
# chef-client.ps1
#
# https://github.com/jenssegers/php-chef/blob/master/src/Jenssegers/Chef/Chef.php

function Invoke-POSHChef {
	[CmdletBinding(PositionalBinding=$false)]
	param (

		[string]
		# Path to file containing array of items to run in the runlist
		$runlist = $false,

		[string]
		# Enironment that the node should belong to
		$environment = $false,

		[String[]]
		# Array of options that can be passed to the client
		$options = @(),

		[string]
		# Path to use for the cache
		$cache = "cache",

		[string]
		# Path for the resultant Mof files
		$generated = "mof",

		[boolean]
		# Specify whether to download cookbooks
		# Default is TRUE
		$download = $true,

		[string]
		# Set the basedir for where POSHChef should store configuration files, keys
		# logs, cache and generated mof file
		$basedir = "C:\POSHChef",

		[string]
		# Where the logs for the runs should be kept
		$logdir = "logs",

		[array]
		# string array of the logtargets
		$logtargets,

		[string]
		# log filename
		$logfilename = "client.log",

		[string[]]
		# Arry fo string about the sections of Invoke-ChefClient that
		# should be skipped, e.g. configuration
		$skip = @(),

		[string]
		# Name of the key that should be used when contacting the chef server
		$key = "client.pem",

		[switch]
		# Specify if the log settings should be returned at the end of the run
		# This will contain all the messages that have been sent to Write-Log and can then be processed
		$OutputLog,

		[string]
		# Path to the configuration file to use
		# If left blank the default 'knife.psd1' will be used
		$config = [String]::Empty,

		[string]
		# Log level to quickly apply to the screen provider
		$loglevel = "info",

		[switch]
		# Sepcify this switch to Force a DSC run
		$force,

		[alias("attributes")]
		# List of attributes that should be added from the command line
		# This allows extra information to be set that can be acted upon, e.g. if this is the first run or not
		$json_attributes

	)

	# clear

	# Set the error action preference
	$ErrorActionPreference = "Stop"

	# Update the ProgressPreference for when Invoke-WebRequest is used
	$ProgressPreference = "SilentlyContinue"

	# Define script information
	$moduleInfo = Get-Module -Name POSHChef

	# Set the log parameters for this function
	if (!$logtargets) {
		$logtargets = @(
				@{logProvider="screen"; verbosity=$loglevel;}
		)
	}

	Set-LogParameters -targets $logtargets -resource_path ("{0}\lib\POSHChef.resources" -f (Split-Path -Parent $(Get-Module -Name POSHChef).path))  -module (Get-ModuleFunctions -module $moduleinfo)

	# Create a hash table that contains information about the run, such as start, end and elapsed times
	# this is not set in the Initialise-Session function as we need to set this up as sson as the function starts
	$run_status = @{
						# set the default status of the run
						status = "failed"

						# set the starttime of the run
						start = (Get-FormattedDate)

						# decalre the end time, which has not been set yet
						end = $false

						# declare a stopwatch for the run
						stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

						# decclare an elapsed time which is worked out from the stopwatch
						elapsed = $false

				   }

	# Patch the $PSBoundParameters to contain the default values
	# if they have not been explicitly set
	foreach ($param in @("options", "runlist", "environment", "cache", "download", "generated", "basedir", "logdir", "key", "skip", "json_attributes")) {
		if (!$PSBoundParameters.ContainsKey($param)) {
			$PSBoundParameters.$param = (Get-Variable -Name $param).Value
		}
	}

	# Get the module information
	$moduleinfo = Get-Module -Name POSHChef

	# Work out the version of POSHChef that is running
	$current_version = $moduleinfo.version.ToString()

	Write-Log -EVentId PC_INFO_0006 -extra $current_version

	# Initialize the sesion and configure global variables
	# Pass the module information so that it can be added to the session configuration
	Initialize-Session -Parameters $PSBoundParameters -moduleinfo $moduleinfo

	# Read the configuration file
	Get-Configuration -config $config

	Set-LogDir -logtargets $logtargets -logtofile

	# Build up an array with the information that has been gathered
	Write-Log " "
	Write-Log -EventId PC_INFO_0009 -extra @("Chef Server:`t{0}" -f $script:session.config.server
										     "Node:`t`t{0}" -f $script:session.config.node
											 "Client:`t`t{0}" -f $script:session.config.client
											 "Log Directory:`t`t{0}" -f $script:session.config.logdir)

	# Determine if this is the latest version of the software or not
	# Get the Feed from NuGet for this module
	$uri = "{0}/Packages()?`$filter=tolower(Id)+eq+'poshchef'&`$orderby=id" -f $script:session.config.nugetsource
	[xml] $feed = Invoke-WebRequest -Uri $uri -UseBasicParsing
	$latest_version = ($feed.feed.entry.properties.version -match "^(\d+(\s*\.\s*\d+){0,3})?$") | Select -Last 1

	# Compare the latest version with the current version and report that an update is available if different
	if ($current_version -ne $latest_version) {
		Write-Log " "
		Write-Log -EVentId PC_INFO_0049 -extra $latest_version
	}

	# Perform checks to ensure that POSHChef will run on the server
	Assert-PSRemoting

	# Check that the system can contact the chef server
	Test-Network

	# Copy the module DSC resources, if the switch has been specified on the command line
	if ($options -contains "copydsc") {
		Copy-Resources -Path $script:session.config.paths.module -subfolder "dscresources"
	}

	# Test that the node is registered on the server
	Test-Registration

	# Get the node information from the server
	$node = Invoke-ChefQuery -path $("/nodes/{0}" -f $script:session.config.node)

	Write-Log " "
	Write-Log -EventId PC_INFO_0012

	# check that the node is not false
	if ($node -eq $false -or [String]::IsNullOrEmpty($node)) {

		Write-Log -EventId PC_ERROR_0006 -Error -Extra $script:session.config.node

	} else {

		# set a default configuration data object
		$configurationdata = @{}

		# get the environment for which this node belongs
		Get-Environment -name $node.chef_environment

		# Write out information about the run list that has been applied
		Write-Log -Message " "
		Write-Log -EventId PC_INFO_0013

		if ([String]::IsNullOrEmpty($node.run_list)) {
			Write-Log -WarnLevel -EventId PC_WARN_0005
		} else {
			foreach ($item in $node.run_list) {
				Write-Log -EventId PC_MISC_0001 -extra $item
			}

			# determine the runlist to use
			if (![String]::IsNullOrEmpty($script:session.local_runlist) -and
				$script:session.local_runlist -ne $false) {
				$_runlist = $script:session.local_runlist
			} else {
				$_runlist = $node.run_list
			}

			# Resolve the run list, in other words expand this out into base level recipes
			Resolve-Runlist -runlist $_runlist

			# Output information about the expanded_runlisy
			Write-Log -Message " "
			Write-Log -EventId PC_INFO_0016
			foreach ($item in $script:session.expanded_runlist) {
				Write-Log -EventId PC_MISC_0001 -extra $item
			}

			# Ensure the cookbooks are available locally
			Get-Cookbooks

			# Resolve the attributes of the coobooks that have been downloaded
			$configurationdata = Resolve-Attributes

			# Perform house keeping on the MOF files
			Invoke-MofHousekeeping

			# Call the Set-DSCConfiguration function to set the local configuration manager settings for the node
			Set-DSCConfiguration -Configuration $configurationdata

			# Execute the runlist
			Write-Log " "
			Write-Log -Eventid PC_INFO_0003
			Write-Log -EventId PC_INFO_0050 -extra $script:session.config.paths.mof_file_path

			# build up and argument splat to be passed to Invoke-RunList, this helps with debugging
			$splat = @{
				runlist = $script:session.expanded_runlist
				node = $script:session.config.node
				configuration = $configurationdata
				outputpath = $script:session.config.paths.mof_file_path
			}

			Write-Log -LogLevel Debug -EventId PC_DEBUG_0031 -extra "Invoke-RunList"
			Write-Log -LogLevel Debug -Message ($splat | ConvertTo-Json -Depth 99 | Out-String)

			# Call the function to generate the mof file that DSC required
			# this returns the path to the mof file
			$mof = Invoke-RunList @splat

			# Provide feedback about the name of the file that has been created
			Write-Log -Message " "
			Write-Log -EVentId PC_INFO_0018
			Write-Log -EVentId PC_INFO_0017
			Write-Log -EventId PC_MISC_0002 -Extra $mof.Fullname

			# Call the Start-Configuration cmdlet that will be used to run the mof file
			# this will use a hash to splat in so that various options can be added
			$dscsplat = @{path = ($script:session.config.paths.mof_file_path)
						  wait = $true}

			# if the force option has been set then set this on the parameters for DSC
			if ($force) {
				$dscsplat.force = $true
			}

			# add the verbose flag to the options so that we can see what is happening
			$dscsplat.verbose = $true

			if ($skip -notcontains "runconfig") {

				Write-Log -EventId PC_INFO_0043

				Write-Log -LogLevel Verbose -EventId PC_VERBOSE_0006 -extra ($dscsplat.Keys | Sort-Object $_ | ForEach-Object {"{0}:  {1}" -f $_, ($dscsplat.$_)})

				# Call the Runspace function to run the Start-DSCConfiguration command
				try {
					Invoke-Runspace -Command Start-DscConfiguration -Arguments $dscsplat -Stream verbose

					# set the run status to success
					$run_status.status = "success"
				} catch {

					# set the status flag to failed
					$run_status.status = "fail"

					# ensure that the exception is add to the run_status
					$run_status.exception = $_.ToString()
				}

				# Call the 'Start-DSCConfiguration' cmdlet to perform the configuration update
				# Start-DscConfiguration @dscsplat -force
			}
		}

		# Determine if any services need to be restarted after the DSC configuration
		Get-Notifications

		# Call function to convert the configurationdata attributes into the correct format for chef
		$node_attributes = Clean-Attributes -configurationdata $configurationdata

		# Run Test handlers and use the result to determine if the run has failed
		# However do not invoke them if the run has already failed

		if (![String]::IsNullOrEmpty($node_attributes.tests.enabled) -and
		    $node_attributes.tests.enabled -eq $true -and
			$run_status.status -eq "success") {

			$splat = @{
				attributes = $node_attributes
				type = "test"
			}

			$test_results = Invoke-Handlers @splat

			# If the test_results are greater than 0 then set the run status to fail
			if ($test_results.failed -gt 0) {
				$run_status.status = "fail"
				$run_status.exception = "{0} of {1} tests failed" -f $test_results.failed, $test_results.total
			}
		}

		# The following line must be executed at the very end of the run
		Complete-ChefRun -run_status $run_status -attributes $node_attributes

		# Now that the run has completed the handlers can be run
		Invoke-Handlers -status $run_status -attributes $node_attributes


	}

	if ($OutputLog) {
		Write-Output (Write-Log -showconfig)
	}

}
