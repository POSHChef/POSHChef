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


function environment_delete {

	<#

	.SYNOPSIS
		Remove an environment from the chef server

	.DESCRIPTION
		Delete one or more environments from the chef server

		The name parameter is a string array and will accept multiple environment names.

	.EXAMPLE

		Invoke-POSHKnife environment delete -name "01Test"

		Remove the environment '01Test' from the chef server

	#>

	param (

		[string[]]
		# List of names of users to delete
		$name,

		[switch]
		[alias('nodes')]
		# Specify if the nodes of the environment should be removed as well
		$deletenodes

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
		$env_exists = $items_on_server.keys | Where-Object { $_ -eq $id }

		# if the user exists then remove it
		if (![String]::IsNullOrEmpty($env_exists)) {
			
			# if the nodes switch has been set, ensure that all the nodes associated with the environment are removed as well
			if ($deletenodes) {

				# get a list of the nodes associated with this environment
				$nodes = Invoke-ChefQuery -path ("/{0}/{1}/nodes" -f $mapping, $id)
				
				# iterate around the nodes that have been founf
				foreach ($node in $nodes.keys) {
				
					if ($node -eq "statuscode") {
						continue
					}

					# using the http ref of the node remove it from the server
					$response = Invoke-ChefQuery -path  $nodes.$node -method "DELETE"

					# finally remove the client from the chef server as well
					$path = "/clients/{0}" -f $node
					$response = Invoke-ChefQuery -path $path -method "DELETE"
				}
			}

			Write-Log -EventId PC_MISC_0000 -extra $id

			$result = Invoke-ChefQuery -Method DELETE -path ("/{0}/{1}" -f $mapping, $id) 
		}
	}
}
