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


function node_create {

	<#

	.SYNOPSIS
		Create a new node on the Chef server

	.DESCRIPTION
		The option to pre-register a machine ont he server is sometimes necessary as it means
		that the runlist etc can be configured before the machine is even created

		This plugin allows this to take place

	#>

	[CmdletBinding()]
	param (

		[string[]]
		# Name of the node(s) to create
		$name,

		[string[]]
		# The runlist to apply to the machine
		$runlist = @(),

		[string]
		# Environment, if any, that the machine should belong to
		$environment = [String]::Empty,
		
		[hashtable]
		# hashtable of attributes to add to the server
		$attributes = @{}
	)

	# Setup the mandatory parameters
	$mandatory = @{
		name = "String array of nodes to create on the Chef server (-name)"
	}

	# Ensure that the default values for the parameters have been set
	foreach ($param in @("runlist")) {
		if (!$PSBoundParameters.ContainsKey($param)) {
			$PSBoundParameters.$param = (Get-Variable -Name $param).Value
		}
	}

	Confirm-Parameters -Parameters $PSBoundParameters -mandatory $mandatory

	Write-Log -Message " "
	Write-Log -EVentId PC_INFO_0031 -extra ("Create", "Node")

	# Iterate around the name that have been supplied and create a new node for each one
	foreach ($id in $name) {

		# create argument hash to splat into the function
		$splat = @{
			name = $id
			runlist = $runlist
			environment = $environment
		}

		$node = New-Node @splat

		# if attributes have been set then call the update command
		if ($attributes.count -gt 0) {
			
			$splat = @{
				attrs = $attributes
				name = $id
			}

			Update-Node @splat
			
		}

		$node
	}
}
