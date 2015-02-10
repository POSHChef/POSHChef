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


function Sort-Hashtable {

	<#

	.SYNOPSIS
	Returns an alphabetically sorted version of the passed hash

	.DESCRIPTION
	This is a recursive function that ensures that a nested hashtable is sorted

	#>

	[CmdletBinding()]
	param (

		[hashtable]
		[Parameter(Mandatory=$true,
				   ValueFromPipeline=$true,
				   Position=0)]
		# The hash to sort
		$hash
	)

	# declare the return object
	$return = [Ordered] @{}

	# Iterate around the passed hashtable in order
	foreach ($property in ($hash.GetEnumerator() | Sort-Object Name)) {
	
		# determine if the property is another hash table
		if ($property.Value -is [hashtable]) {
			$return.($property.name) = Sort-Hashtable $property.Value
		} elseif ($property.Value -is [object[]]) {
			
			$return.($property.name) = @()

			# iterate around the array
			foreach ($item in $property.value) {
				if ($item -is [hashtable]) {
					$return.($property.name) += Sort-Hashtable $item
				} else {
					$return.($property.name) += $item
				}
			}


		} else {
			$return.($property.name) = $property.value
		}
		
	}

	# return the sorted version
	$return
	
}
