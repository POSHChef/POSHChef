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
		$nugetsource,

		[boolean]
		$mofarchive,

		[int]
		$mofkeep = 20,

		[string]
		$chef_config_file = [String]::Empty

	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -EventId PC_DEBUG_0017 -extra $MyInvocation.MyCommand

	# Get the path to the configuration file so it can be written to
	if ([String]::IsNullOrEmpty($chef_config_file)) {
		$chef_config_file = "{0}\client.psd1" -f $script:session.config.paths.conf
	}

	# Create a string builder object so that the configuration file can be written out to disk
	# A string builder is used so that the it is possible to easily add lines to it
	$data = New-Object System.Text.StringBuilder

	# Add each necessary line to the string builder
	$data.AppendLine("@{") | Out-Null
	$data.AppendLine("") | Out-Null

	# Add in the server information
	$data.AppendLine("`t# URL of the Chef server") | Out-Null
	$data.AppendLine("`t# If the target is Chef 12 or Hosted Chef this should include your organization") | Out-Null
	$data.AppendLine(("`tserver = '{0}'" -f $server)) | Out-Null
	$data.AppendLine("") | Out-Null

	# Set the nodename of the machine
	$data.AppendLine("`t# Name that this node should be known as on the Chef server") | Out-Null
	$data.AppendLine(("`tnode = '{0}'" -f $nodename)) | Out-Null
	$data.AppendLine("") | Out-Null

	# Set the environment of the node
	$data.AppendLine("`t# Name of the environment that machine is a member of") | Out-Null
	$data.AppendLine(("`tenvironment = '{0}'" -f $environment)) | out-null
	$data.AppendLine("") | Out-Null

	# Set the number of logs to keep
	$data.AppendLine("`t# The number of POSHChef logs to keep") | Out-Null
	$data.AppendLine("`tlogs = @{") | Out-Null
	$data.AppendLine(("`t`tkeep = {0}" -f $keeplogs)) | Out-Null
	$data.AppendLine("`t}") | Out-Null
	$data.AppendLine("") | Out-Null

	# If the nuget source has been specified add it in
	if (![String]::IsNullOrEmpty($nugetsource)) {
		$data.AppendLine("`t# Nuget server from which the module will check for updates") | out-Null
		$data.AppendLine(("`tnugetsource = '{0}'" -f $nugetsource)) | Out-Null
		$data.AppendLine("") | Out-Null
	}

	# If the mofacrhive has been specified update the configuration file
	if ($mofarchive -eq $true) {
		$data.AppendLine("`t# Set the MOF archive parameters") | Out-Null
		$data.AppendLine("`tmof = @{") | Out-Null
		$data.AppendLine('{0}archive = $true' -f "`t`t") | Out-Null
		$data.AppendLine(("`t`tkeep = {0}" -f $mofcount)) | Out-Null
		$data.AppendLine("`t}") | Out-Null
		$data.AppendLine("") | Out-Null
	}

	# Ensure the file is terminated properly
	$data.AppendLine("}") | Out-Null

	# write this data file out to the $chef_config_file
	Set-Content -Path $chef_config_file -Value $data.ToString()
}
