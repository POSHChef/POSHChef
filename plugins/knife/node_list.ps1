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


function node_list {


	<#

	.SYNOPSIS
		List all of the nodes that are registered with the server

	.DESCRIPTION
		Although the Chef Web UI provides a method to show the registered nodes, it can be useful
		to be able to get this on the command line.

		No additional parameters are required for this plugin

	.EXAMPLE

		Invoke-POSHKnife node list

		Will list out the node

	#>

	Write-Log -Message " "
	Write-Log -EVentId PC_INFO_0031 -extra ("Listing", "Nodes")

	# Get a list of the roles currently on the server
	# This so it can be determined if the role already exists or needs to be created
	$items_on_server = Invoke-ChefQuery -Path "/nodes"

	# Iterate around the items of the server and show list them
	foreach ($item in ($items_on_server.keys | sort)) {

		Write-Log -EventId PC_MISC_0000 -extra ($item)
	}
	
}
