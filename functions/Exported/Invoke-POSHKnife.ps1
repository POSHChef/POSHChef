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


function Invoke-POSHKnife {

	<#

	.SYNOPSIS
	Provides the the functionaility as per native chef in the knife command

	.DESCRIPTION
	The knife tool is the main configuration tool for managing chef.

	The tool provides the following functionality:

		Cookbooks

			Craete a new cookbook file structure
			Upload a cookbook to the server

	.EXAMPLE

	Invoke-POSHKnife -type cookbook -command create -name test

	Will create a new cookbook in the cookbook path as defined in c:\POSHChef\conf\knife.psd1

	.EXAMPLE

	Invoke-POSHKnife cookbook create test

	This example is identical to the first, but uses positional parameters to pass the information to the cmdlet

	#>

	[CmdletBinding()]
	param (

		[Parameter(Position=0, Mandatory=$false)]
		[string]
		# The type of chef item that is being worked on
		$type,

		[Parameter(Position=1, Mandatory=$false)]
		[string]
		# Command that is to be run against the type that has been selected
		$action,

		[string]
		# Set the basedir for where POSHChef should store configuration files, keys
		# logs, cache and generated mof file
		$basedir = "C:\POSHChef",

		[string]
		# Where the logs for the runs should be kept
		$logdir = "logs",

		[string]
		# log filename
		$logfilename = "client.log",

		[string]
		# Path to the configuration file to use
		# If left blank the default 'knife.psd1' will be used
		$config = [String]::Empty,

		[array]
		# string array of the logtargets
		$logtargets,

		[string]
		# quick way to change the verbnosity of the logging
		$loglevel = "info"
	)

	# Build up the dynamic parameters that are required for the subcommand
	# Any parameters that are also apliced to the sub command are removed
	DynamicParam {

		if ([String]::IsNullOrEmpty($basedir)) {
			$basedir = "c:\POSHChef"
		}

		# Build up array of directories to look in for the plugin
		$knife_plugin_dirs = @(("{0}\plugins\knife" -f (Split-Path -Parent (Get-Module -Name POSHChef).path)),
							   ("{0}\plugins\knife" -f $basedir))

		# based on the type and action that has been defined work out the function name
		if ([String]::IsNullOrEmpty($action)) {
			$function_name = $type
		} else {
			$function_name = "{0}_{1}" -f $type, $action
		}

		# attempt to find the script based on the type passed to the function
		$script = $knife_plugin_dirs | Foreach-Object {Get-ChildItem -Path $_ -Filter ("{0}.ps1" -f $function_name)}

		# if the script is not empty at this point then add the dynamic parameters
		if (![string]::IsNullOrEmpty($script)) {

			# source the script
			. $script.FullName

			$Attributes = New-Object 'Management.Automation.ParameterAttribute'
			$Attributes.ParameterSetName = "__AllParameterSets"
			$Attributes.Mandatory = $false

			$AttributesCollection = New-Object 'Collections.ObjectModel.Collection[Attribute]'
			$AttributesCollection.Add($attributes)

			$ParamDictionary = New-Object 'Management.Automation.RuntimeDefinedParameterDictionary'

			# get the parameters from the command that has been loaded
			$cmd = Get-Command $function_name
			foreach ($param in $cmd.parameters.keys) {

				# do not include any parameters that are already configured in this function
				if (@("type", "action", "options") -contains $param) {
					continue
				}

				$new_param = New-Object -TypeName 'Management.Automation.RunTimeDefinedParameter' -ArgumentList ($param, $cmd.Parameters.$param.ParameterType, $AttributesCollection)
				$ParamDictionary.Add($param, $new_param)
			}

			$ParamDictionary
		}
	}

	Process {

		# Set the error action preference
		$ErrorActionPreference = "Stop"

		$argcount = $PSBoundParameters.count

		# Set the log parameters for this function
		if (!$logtargets) {
			$logtargets = @(
				@{logProvider="screen"; verbosity=$loglevel;}
			)
		}

		# Set the log parameters for this function
		Set-LogParameters -targets $logtargets -resource_path ("{0}\lib\POSHChef.resources" -f $script:session.module.path) -module (Get-ModuleFunctions)

		# Patch the $PSBoundParameters to contain the default values
		# if they have not been explicitly set
		foreach ($param in @("options", "basedir", "output", "password", "logdir", "logfilename")) {
			if (!$PSBoundParameters.ContainsKey($param) -and ![String]::IsNullOrEmpty((Get-Variable -Name $param -ErrorAction SilentlyContinue).Value)) {
				$PSBoundParameters.$param = (Get-Variable -Name $param).Value
			}
		}

		# Get the configuration for chef
		Update-Session -Parameters $PSBoundParameters
		Get-Configuration -knife -config $config

		Set-LogDir -logtargets $logtargets

		# now get a list of the commands that each type supports
		# this is done by looking in the plugins directory and calling the function with the -supports flag
		# which will return an array of the types that the action is for

		$cmd_hash = @{}

		# define an array of the paths for knife plugins
		$knife_plugin_dirs = @(("{0}\plugins\knife" -f $script:session.module.path),
								$script:session.config.paths.knife_plugins)

		# iterate around each of the knife_plugin_dirs
		foreach ($knife_plugin_dir in $knife_plugin_dirs) {

			Get-ChildItem -Path $knife_plugin_dir | Foreach-Object {

				# source the file so it can be executed
				. $_.FullName

				# Get the command and the action that the file supports
				$chef_type, $act = ([io.path]::GetFileNameWithoutExtension($_.FullName)).Split("_")

				# first check the type exists as a key in the cmd_hash
				if (!($cmd_hash.ContainsKey($chef_type))) {
					$cmd_hash.$chef_type = @{
												actions = @()

											}
				}

				# append this command to the actions list for the type
				$cmd_hash.$chef_type.actions += $act

			}
		}

		# if no parameters have been specified then output some help
		if ($argcount -eq 0) {

			# iterate around the cmd_hash and the subsequent actions giving examples
			foreach ($chef_type in $cmd_hash.keys) {

				write-log " "
				Write-Log -Message ("{0} commands" -f ((Get-Culture).TextInfo.ToTitleCase($chef_type)))

				# iterate over the actions
				foreach ($action in $cmd_hash.$chef_type.actions) {
					Write-Log -Message ("{0} {1}" -f $chef_type, $action) -EventId PC_MISC_0000
				}
			}

			return
		}

		# check that the type is one of the supported types
		if ($cmd_hash.keys -notcontains $type) {
			Write-Log -EventId PC_ERROR_0014 -extra $type -stop -error
		}

		# if no parameters have been specified then output some help
		if ($argcount -eq 1) {

			write-log " "
			Write-Log -Message ("{0} commands" -f ((Get-Culture).TextInfo.ToTitleCase($type)))

			# iterate over the actions
			foreach ($action in $cmd_hash.$type.actions) {
				Write-Log -Message ("{0} {1}" -f $type, $action) -EventId PC_MISC_0000
			}

			return
		}

		# Check that the itemn supports the selected action
		if (!($cmd_hash.$type.actions -contains $action) -and ![String]::IsNullOrEmpty($action)) {
			Write-Log -EventId PC_ERROR_0015 -Extra @($type, $action)  -Error -stop
		}

		# Determine what items in the PSBoundParameters should be passed to the underlying function
		$h = @{}
		ForEach ($key in (gcm $function_name).Parameters.Keys) {
			$h.$key = $PSBoundParameters.$key
		}

		# ensure the chef_type is added to $h
		$h.chef_type = $type

		& $function_name @h

	}

}
