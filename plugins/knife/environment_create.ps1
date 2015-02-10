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
		Create the named environments on the chef server
	#>

	param (
		
		[string[]]
		# String array of environments to create
		$name,

		[string[]]
		# String array of descriptions that should be applied to each node
		$descriptions = @()
	)

	Write-Log -Message " "
	Write-Log -EVentId PC_INFO_0031 -extra ("Create", "Environment")
	
	# Determine the name of the chef type from the function name
	$chef_type, $action = $MyInvocation.MyCommand -split "_"
	 
	# determine the mapping for the chef query
	$mapping = "{0}s" -f $chef_type

	# get a list of the environments already known to the system to determine if it already exists
	$result = Invoke-ChefQuery -Path ("/{0}" -f $mapping)

	# iterate around the environment names that have been passed
	$element = 0
	foreach ($id in $name) {

		# determine if the current id is already on the server
		if ($result.ContainsKey($id)) {
			Write-Log -EventId PC_INFO_0039 -extra $id
		} else {

			# determine if there is a description for the environment
			if ($descriptions.count -gt 0) {
				$description = $descriptions[$element]
			} else {
				$description = ""
			}

			# build up an array that will be used as the payload for the POST request
			$body = @{
				name = $id
				default_attributes = @{}
				override_attributes = @{}
				json_class = "Chef::Environment"
				description = $description
				cookbook_versions = @{}
				chef_type = "environment"	
			}

			# perform the post that will create the environment on the chef server
			$response = Invoke-ChefQuery -Path ("/{0}" -f $mapping) -Method "post" -data $body

		}

		# increment the element count
		$element ++
	}
}
