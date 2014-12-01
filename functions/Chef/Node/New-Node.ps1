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


function New-Node {


	<#

	.SYNOPSIS
		Create the node on the Chef server

	.DESCRIPTION
		Method to register a new node on the server.

		If run with no arguments, as is the case with self registration, the command will register a
		machine using information in configuration files

		The other way in which this can be called is by POSHKnife which will specify all of the things, such
		as the name of the machine, the environment and the runlist that needs to be applied

	#>

	[CmdletBinding()]
	param (

		[string]
		# Name of the node to create on the server
		$name = [String]::IsNullOrEmpty,

		[string[]]
		# Runlist to be applied to the new machine
		$runlist = @(),

		[string]
		# Environment that the new machine should belong to
		$environment = [String]::IsNullOrEmpty
	)
	
	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	Write-Log -WarnLevel -EventId PC_WARN_0002

	# set the values to be applied to the node
	# If a nodename has not been specified then get it from the session
	if ([String]::IsNullOrEmpty($name)) {
		$name = $script:session.config.node
	}

	# determine the environment to set if not specified
	if ([String]::IsNullOrEmpty($environment)) {
		$environment = $script:session.environment

		# check the environment to see if it has been set or is false
		if ($environment -eq $false -or [String]::IsNullOrEmpty($environment)) {
			$environment = "_default"
		}
	}

	# determine if the node already exists
	$exists = Get-Node -name $name -passthru

	# if the statuscode does not equal 404, not found, then return as the node 
	# already exists
	# if ($exists.statuscode -ne "404") {
	if (![String]::IsNullOrEmpty($exists)) {
		$exists
		return
	}

	# Create a hash of the new data that needs to be specified
	$postdata = @{
		name = $name
		chef_type = "node"
		json_class = "Chef::Node"
		chef_environment = $environment
	}

	# add the runlist
	# there seems to be a problem with the conversion to JSON for an empty array
	if ($runlist.count -eq 0) {
		$postdata.run_list = @()
	} else {
		$postdata.run_list = $runlist
	}

	# Call the Invoke-ChefQuery fnction to add the node
	$response = Invoke-ChefQuery -path "/nodes" -method "POST" -data $postdata

	# If the response is false output an error message and exit
	if ($response -eq $false) {
		Write-Log -ErrorLevel -EventId PC_ERROR_0005 -stop
	}

	# Return the node to the calling function
	Get-Node -name $name
}
