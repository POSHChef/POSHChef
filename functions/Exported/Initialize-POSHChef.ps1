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


function Initialize-POSHChef {

	<#

	.SYNOPSIS
	Configure the installation of POSHChef

	.DESCRIPTION
	In order for POSHChef to operate it needs to know three main bits of information

		Chef Server
		Name of the node
		The chef-validator signing key

	If Invoke-ChefClient is run without this being done first it will run an interactive session asking
	questions about what is required.  As this needs to be scripts, this function provides a way to
	programmatically provide this information

	#>

	[CmdletBinding()]
	param (

		[string]
		# URL of Chef server
		$server,

		[string]
		# Name of the node as it will be stored in Chef
		$nodename,

		[int]
		# Number of logs to keep
		$keeplogs = 20,

		[string]
		# Path to the chef_validation key.  This can be a URL so that
		# the file is copied down and put into the correct location
		$validator,

		[string]
		# path to the client's key.
		# if the machine has been pre-registered with chef then this will need to point
		# to the file that has been created and downloaded
		$client_key = [String]::Empty,

		[string]
		# Base directory where POSHChef files are stored
		$basedir = "C:\POSHChef",

		[string]
		# Environment that this node should be a member of
		$environment = "_default",

		[string]
		# Nuget source server from where POSHChef can be installed
		$nugetsource,

		[boolean]
		# Sepcify of MOF files should be archived or not
		$mofarchive = $false,

		[int]
		# The number of mof files that should be kept
		$mofcount = 20

	)

	# Set log paraneters so that we have access to the help file
	Set-LogParameters -helpfile ("{0}\..\..\lib\POSHChef.resources" -f $PSScriptRoot)

	Write-Log -Eventid PC_INFO_0006 -extra ((Get-Module -Name POSHChef).Version.ToString())

	Write-Log -EventId PC_INFO_0019

	# Patch the $PSBoundParameters to contain the default values
	# if they have not been explicitly set
	foreach ($param in @("server", "nodename", "keeplogs", "basedir", "environment")) {
		if (!$PSBoundParameters.ContainsKey($param)) {
			$PSBoundParameters.$param = (Get-Variable -Name $param).Value
		}
	}

	# Check that mandatory parameters have been set
	Confirm-Parameters -parameters $PSBoundParameters -name ($MyInvocation.MyCommand)

	# Initialize a session to that we can use the paths that are setup accessible
	Initialize-Session -parameters $PSBoundParameters

	# Call the Set-Configuration function to get these parameters written to the configuration file
	$splat = @{
		server = $server
		nodename = $nodename
		keeplogs = $keeplogs
		environment = $environment
		nugetsource = $nugetsource
		mofarchive = $mofarchive
		mofcount = $mofcount
	}
	Set-Configuration @splat

	# Determine the file that is to be downloaded, based on whether a clientkey has been specified or not
	if (![String]::IsNullOrEmpty($client_key)) {
		$uri = [System.URI] $client_key
	} else {
		$uri = [System.URI] $validator
	}

	switch -Wildcard ($uri.scheme) {

		"http*" {

			# Work out the path to download the file to
			$download_path = "{0}\{1}" -f ($script:session.config.paths.conf), (Split-Path -Leaf ($uri.Absolutepath))

			Write-Log -EventId PC_INFO_0020
			Write-Log -EventId PC_MISC_0001 -extra $download_path

			# Run the method to actually download the file
			Invoke-WebRequest -Uri $uri -OutFile $download_path
		}

		"file" {

			# The validator is a file so copy it to the correct lcoation
			# overwrite the target if it exists

			# Check that the file exists
			If ((Test-Path -Path  $uri.OriginalString)) {

				Write-Log -EventId PC_INFO_0021
				Write-Log -EventId PC_MISC_0001 -extra ($script:Session.config.paths.conf)

				# Copy the file to the correct location
				Copy-Item -Path $uri.OriginalString -Destination ($script:Session.config.paths.conf)

			} else {

				# output error and stop
				Write-Log -ErrorLevel -EventId PC_ERROR_0010 -extra $validator -stop
			}
		}
	}


}
