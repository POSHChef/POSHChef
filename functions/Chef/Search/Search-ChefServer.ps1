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


function Search-ChefServer {

	<#

	.SYNOPSIS
		Search the specified index on the chef server

	.DESCRIPTION
		Using the specified index and query perform a search on the chef server

		This function can be used directly in a Chef recipe and will be called by the knife plugin

	#>

	[CmdletBinding()]
	param (

		[Parameter(Mandatory=$true)]
		[string]
		# Index to search in
		$index,

		[Parameter(Mandatory=$true)]
		[string]
		# Lucene query to run in the specified index
		$query
	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	# Build up the path that is to be called on the chef server
	$path = "/search/{0}?q={1}" -f $index, [System.URI]::EscapeDataString($query)

	# Using the ChefQuery to send the request to the server
	$results = Invoke-ChefQuery -Path $path

	# Return the results to the calling function
	$results

}
