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


function databag_create {


	<#

	.SYNOPSIS
		Create a new database on the server

	.DESCRIPTION
		Databags are useful to hold central bits of information that the system may require, such as the name of any
		users to create for example.

		This function attempts to create a new databag on the server

	.EXAMPLE

		Invoke-POSHKnife databag create -name example

		Creates new datag called 'example'

	#>

	param (

		[string[]]
		# List of names of database to create
		$name
	)

	# Determine the name of the chef type from the function name
	$chef_type, $action = $MyInvocation.MyCommand -split "_"

	# determine the mapping for the chef query
	$mapping = "{0}s" -f $chef_type

	Write-Log -Message " "
	Write-Log -EVentId PC_INFO_0031 -extra ("Creating", (Get-Culture).TextInfo.ToTitleCase($mapping))

	# iterate around each of the items in the name
	foreach ($item in $name) {

		Write-Log -EventId PC_MISC_0000 -extra $item

		# Create the necessary body
		$body = @{
			name = $item
		}

		# Call the Invoke-ChefQuery function to create the named bags
		$result = Invoke-ChefQuery -Path "/data" -Method POST -data ($body | convertto-json -Depth 999)

	}
}
