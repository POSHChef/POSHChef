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


function Initialize-POSHKnife {

	<#

	.SYNOPSIS
	Configure the installation of POSHChef

	.DESCRIPTION
	For a machine to be configured as a Chef workstation 4 bits of information are required

		Chef Server
		Client name (not the same as the web username)
		Path to client key
		Path to cookbooks (if not specified this will be set to the <BASEDIR>\cookbooks

	If Invoke-ChefClient is run without this being done first it will run an interactive session asking
	questions about what is required.  As this needs to be scripts, this function provides a way to
	programmatically provide this information

	The key that is required is one that will have been created on the chef server.
	Without this key it is not possible to manage cookbooks in chef using this tool.

	.EXAMPLE

	Intialize-POSHKnife -server "https://chef.local" -client fred -clientkey c:\temp\fred.pem

	Will create the necessary folder structure under C:\POSHChef and will copy the client key to C:\POSHChef\conf\client.pem
	The knife.psd1 file is created with the specified configuration.

	#>

	[CmdletBinding()]
	param (

		[string]
		# URL of Chef server
		$server,

		[string]
		# Name of the node as it will be stored in Chef
		$client,

		[int]
		# Number of logs to keep
		$keeplogs = 20,

		[string]
		# Path to the client key. 
		$clientkey,

		[string]
		# Base directory where POSHChef files are stored
		$basedir = "C:\POSHChef",

		[string]
		# Path to the cookbooks
		$cookbook_path = [String]::Empty
	)

	# Set log paraneters so that we have access to the help file
	Set-LogParameters -helpfile ("{0}\..\..\lib\POSHChef.resources" -f $PSScriptRoot)

	Write-Log -Eventid PC_INFO_0006 -extra ((Get-Module -Name POSHChef).Version.ToString())

	Write-Log -EventId PC_INFO_0026

	# Check the cookbook path and if it is empty set it based on the basedir
	if ([String]::IsNullOrEmpty($cookbook_path)) {
		$cookbook_path = "{0}\cookbooks" -f $basedir
	}

	# Patch the $PSBoundParameters to contain the default values
	# if they have not been explicitly set
	foreach ($param in @("server", "client", "clientkey", "keeplogs", "basedir", "cookbook_path")) {
		if (!$PSBoundParameters.ContainsKey($param)) {
			$PSBoundParameters.$param = (Get-Variable -Name $param).Value
		}
	}

	# Check that mandatory parameters have been set
	Confirm-Parameters -parameters $PSBoundParameters -name ($MyInvocation.MyCommand)

	# Initialize a session to that we can use the paths that are setup accessible
	Initialize-Session -parameters $PSBoundParameters

	# check the client key file exists
	if (!(Test-Path -Path $clientkey)) {
		Write-Log -ErrorLevel -EventId PC_ERROR_0012 -Extra $clientkey -stop
	}

	# As the file exists, copy the file to the conf directory
	$destination = "{0}\client.pem" -f $script:session.config.paths.conf
	Write-Log -EventId PC_INFO_0027 -Extra $destination
	Copy-Item -Path $clientkey -Destination $destination | Out-Null

	# Call the Set-Configuration function to get these parameters written to the configuration file
	Set-KnifeConfiguration -server $server -nodename $client -keeplogs $keeplogs -cookbook_path $cookbook_path

}
