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
		[alias("key")]
		# path to the client's key.
		# if the machine has been pre-registered with chef then this will need to point
		# to the file that has been created and downloaded
		$client_key = [String]::Empty,

		[string]
		# Sub folder in the conf directory that the key should be stored in
		$keydir = [String]::Empty,

		[string]
		# Base directory where POSHChef files are stored
		$basedir = "C:\POSHChef",

		[string]
		# Environment that this node should be a member of
		$environment = "_default",

		[string]
		# Nuget source server from where POSHChef can be installed
		$nugetsource,

		[string]
		# Name of the configuration file to create
		$name = [String]::Empty,

		[string[]]
		# String array of operations withing POSHChef that should be skipped
		$skip,

		[boolean]
		# Sepcify of MOF files should be archived or not
		$mofarchive = $false,

		[int]
		# The number of mof files that should be kept
		$mofcount = 20,

		[string]
		# Set the API version to use when communicating with the chef server
		$apiversion = "12.0.2",

		[switch]
		# Specify if any existing files should be overwtitten
		$force,

		[switch]
		# Specify if the key should be kept in the same place
		$nocopykey

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
	Update-Session -parameters $PSBoundParameters

	# Build up an object to pass to the Setup-ConfigFiles function to configure the conf file
	# for Chef
	$userconfig = @{
		server = $server
		node = $nodename
		logs = @{
			keep = $keeplogs
		}
		environment = $environment
		mof = @{
			keep = $mofcount
			archive = $mofarchive
		}
		apiversion = $apiversion
		skip = @($skip)
		keydir = $keydir
	}

	# add in the extra information if it has been specified
	if (![String]::IsNullOrEmpty($client_key)) {
		$userconfig.client_key = $client_key
	} else {
		$userconfig.validation_key = $validator
	}

	# if a nugetsource has been specified add it here
	if (![String]::IsNullOrEmpty($nugetsource)) {
		$userconfig.nugetsource = $nugetsource
	}

	# Create the argument hashtable to splat into the Setup-Configfiles function
	$splat = @{
		type = "client"
		name = $name
		userconfig = $userconfig
		force = $force
		nocopykey = $nocopykey
		keydir = $keydir
	}

	Setup-ConfigFiles @splat


}
