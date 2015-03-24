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

function environment_create {

	<#

		.SYNOPSIS
			Creates the named environment(s) on the server

		.DESCRIPTION
			Plugin to allow the creation of environment(s) on the Chef server.  There are three parameter sets.

			1. Single - a single environment can be created by specifying the individual parts
			2. Object - a hashtable of the environment containing the correct structure can be passed
			3. Multiple - an array of hashtables (the same as in 2) can be passed to create multiple environments

			The plugin will check to see if the environment already exists on the server.  If it does then a
			warning will be thrown as the environment needs to be modified and uploaded.

		.NOTES
			Although plugins support the CmdletBinding annotation is not possible to pass values into the plugin using the pipeline
			This is because the wrapper cmdlet already has positional parameters that make it impossible to pipeline into the command

		.EXAMPLE

			PS C:\> Invoke-POSHKnife environment create -name Testing -description "Testing environment" -defaultattributes @{team = "Roobarb"}

			This will attempt to create a new enviornment called 'Testing' with the specified description.  Some default attributes will be set as well

		.EXAMPLE

			PS C:\> $object = @{name = Testing; description = "Testing environment"; defaultattributes = @{team = "Roobarb"}}
			PS C:\> Invoke-POSHKnife environment create -InputObject $object

			This example is technically the same as the previous example, it just supports the creation of the environment using an object

		 .EXAMPLE

			PS C:\> $multiple = @($object, @{name = "Testing 2"; description = "Another testing environment"})
			PS C:\> Invoke-POSHKnife environment create -multiple $multiple

			This example takes an array of hashtables each of which contain information about the environment to craete.
			It will create two environments called 'Testing' and 'Testing 2'.  (The first one comes from the object created in Example 2)

	#>

	[CmdletBinding(DefaultParameterSetName="single")]
	param (

		[Parameter(ParameterSetName="single")]
		[string]
		# Name of environment to create
		$name,

		[Parameter(ParameterSetName="single")]
		[string]
		# Descrtiption of the environment being created
		$description = [String]::Empty,

		[Parameter(ParameterSetName="single")]
		[alias("attributes")]
		[hashtable]
		# Hashtable of attributes to assign to the environment
		$defaultattributes = @{},

		[Parameter(ParameterSetName="single")]
		[hashtable]
		# Hashtable of override attributes to assign
		$overrideattributes = @{},

		[Parameter(ParameterSetName="object")]
		[hashtable]
		# Hashtable containing the information that is required to create a new environment
		# on the chef server
		$InputObject,

		[Parameter(ParameterSetName="multiple")]
		[array]
		# Array of hashtables containing all of the environments that need to be created
		$multiple
	)

	# Setup the mandatory parameters, based on the parameter set name
	switch ($PSCmdlet.ParameterSetName) {
		"single" {
			$mandatory = @{
				name = "String array of environments create (-name)"
			}
		}
		"object" {
			$mandatory = @{
				inputobject = "Hashtable describing the new environment (-InputObject)"
			}
		}
		"multiple" {
			$mandatory = @{
				multiple = "Array of hashtables of environments to create (-multiple)"
			}
		}
	}
	
	Confirm-Parameters -Parameters $PSBoundParameters -mandatory $mandatory

	Write-Log -Message " "
	Write-Log -EVentId PC_INFO_0031 -extra ("Create", "Environment")

	# Based on the parameter set that has been used build up an object that can
	# be iterated around to create the necessary environments
	switch ($PSCmdLet.ParameterSetName) {
		"single" {
			$multiple = @{
				name = $name
				description = $description
				attributes = @{
					default = $defaultattributes
					override = $overrideattributes
				}
			}
		}

		"object" {
			$multiple = @($InputObject)
		}
	}

	# Determine the name of the chef type from the function name
	$chef_type, $action = $MyInvocation.MyCommand -split "_"

	# determine the mapping for the chef query
	$mapping = "{0}s" -f $chef_type

	# get a list of the environments already known to the system to determine if it already exists
	$environments = Get-Environment

	# iterate around each of the environments as defined in the multiple variable
	foreach ($environment in $multiple) {

		# Check that the environment being created does not already exist on the server
		if ($environments.keys -ccontains $environment.name) {
			Write-Log -EventId PC_INFO_0039 -extra $environment.name
		}

		# ensure that the default values for the object exist
		if (!$environment.containskey("attributes")) {
			$environment.attributes = @{}
		}

		if (!$environment.attributes.containskey("default")) {
			$environment.attributes.default = @{}
		}

		if (!$environment.attributes.containskey("override")) {
			$environment.attributes.override = @{}
		}

		# Build up the hashtable to be used to create the new environment on the server
		$splat = @{
			InputObject = @{
				name = $environment.name
				default_attributes = $environment.attributes.default
				override_attributes = $environment.attributes.override
				json_class = "Chef::Environment"
				description = $environment.description
				cookbook_versions = @{}
				chef_type = "environment"
			}
			list = $environments.keys
		}

		# Call function to create the environment on the chef server
		$response = Upload-ChefItem @splat
	}
}
