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


function environment_nodes {

	<#

	.SYNOPSIS
		Return a list of all the nodes that belong to the named environment

	#>

	[CmdletBinding()]
	param (

		[string]
		# Name of the environment to show servers from
		$name
	)

	# Setup the mandatory parameters
	$mandatory = @{
		name = "Name of environment to list the member nodes from (-name)"
	}

	Confirm-Parameters -Parameters $PSBoundParameters -mandatory $mandatory

	# Determine the name of the chef type from the function name
	$chef_type, $action = $MyInvocation.MyCommand -split "_"

	# determine the mapping for the chef query
	$mapping = "{0}s" -f $chef_type

	Write-Log -Message " "
	Write-Log -EVentId PC_INFO_0031 -extra ("Nodes in Environment:", $name)

	# Get a list of the roles currently on the server
	# This so it can be determined if the role already exists or needs to be created
	$env_nodes = Invoke-ChefQuery -Path ("/{0}/{1}/nodes" -f $mapping, $name)

	# remove the statuscode from the hashtable
	$env_nodes.Remove("statuscode")

	if ($env_nodes.count -gt 0) {
		Write-Log -EventId PC_INFO_0048 -extra ($env_nodes.count)

		# iterate around the nodes
		foreach ($env_node in $env_nodes.keys) {
			Write-Log -EventId PC_MISC_0001 -extra $env_node
		}

		# if the invocation of this command starts with a $ then the executor is expecting the data
		# to be returned, so output the information
		if ($PSCmdlet.MyInvocation.Line.Trim().startswith('$')) {
			$env_nodes
		}
	}



}
