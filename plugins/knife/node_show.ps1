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


function node_show {


	<#

	.SYNOPSIS
		Display the specified node

	.DESCRIPTION
		Display the details of the specified node

	.EXAMPLE

		Invoke-POSHKnife node show -name foo

		Will list out the node called 'foo'

	#>

	param (

		[string]
		# List of names of users to create
		$name
	)

	Write-Log -Message " "
	Write-Log -EVentId PC_INFO_0031 -extra ("Display", "Node")

	# Call the POSHChef function to get the node
	$node = Get-Node -name $name -passthru

	# output the information
	$node
	
}
