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


function search {

	<#

	.SYNOPSIS
		Performs a search against the specified index in chef

	#>

	[CmdletBinding()]
	param (

		[string]
		# Index on which the query should be executed
		$index,

		[string]
		# The query to run
		$query
	)

	# Setup the mandatory parameters
	$mandatory = @{
		index = "Index on which the query should be run (-index)"
		query = "Lucene query to run on the index (-query)"
	}

	Confirm-Parameters -Parameters $PSBoundParameters -mandatory $mandatory

	# Output information on screen
	Write-Log -Message " "
	Write-Log -EVentId PC_INFO_0031 -extra (("Searching the '{0}'" -f $index), "Index")

	$results = Search-ChefServer -index $index -query $query

	# output information about the search
	if ($results.total -gt 0) {
		Write-Log -EventId PC_INFO_0048 -extra ($results.total)

		# loop round the rows information
		foreach ($row in $results.rows) {
			$row
		}
	} else {
		Write-Log -EventId PC_INFO_0047
	}
}
