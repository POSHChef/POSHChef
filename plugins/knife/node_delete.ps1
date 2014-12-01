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


function node_delete {

	<#

	.SYNOPSIS
		Delete one or more nodes from the chef server

	.DESCRIPTION
		To enable Chef to work correctly in terms of seraching for nodes, it is a good
		idea to remove nodes from the server when they have been decomissioned.

		This plugin allows one or more nodes to be removed from chef.

	.EXAMPLE

		Invoke-POSHKnife node delete -name "test01.example.co.uk"

		Attempt to remove the node 'test01.example.co.uk' from the chef server.

	.NOTES
		If a node is removed but not its client the POSHChef on the node will fail as it 
		will not be able to retrieve a valid node object

	#>

	param (

		[string[]]
		# List of names of users to delete
		$name

	)

	# Determine the name of the chef type from the function name
	$chef_type, $action = $MyInvocation.MyCommand -split "_"
	 
	# determine the mapping for the chef query
	$mapping = "{0}s" -f $chef_type

	Write-Log -Message " "
	Write-Log -EVentId PC_INFO_0031 -extra ("Deleting", (Get-Culture).TextInfo.ToTitleCase($mapping))

	# Get a list of the users on the server so that it can be checked to see if the user exists before deleting
	$items_on_server = Invoke-ChefQuery -Path ("/{0}" -f $mapping)

	# iterate around the names that have been passed
	foreach ($id in $name) {

		# see if the user exists
		$user_exists = $items_on_server.keys | Where-Object { $_ -eq $id }

		# if the user exists then remove it
		if (![String]::IsNullOrEmpty($user_exists)) {
			
			Write-Log -EventId PC_MISC_0000 -extra $id

			$result = Invoke-ChefQuery -Method DELETE -path ("/{0}/{1}" -f $mapping, $id) 
		}
	}
}
