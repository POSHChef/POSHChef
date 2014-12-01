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


function Get-DatabagItem {

	<#

	.SYNOPSIS
		Retrieves the data bag item from the specified data bag

	.DESCRIPTION
		Databags are used in chef to store and share data between machines.
		This information is meant to be static data that does not change, such as the URL for a CDN for example.

		This function attempts to retrieve the item from the named databag and return a hashtable 
		of the data contained therein.

	#>

	[CmdletBinding()]
	param (

		[string]
		# Name of the databag to get
		$name,

		[string]
		# Item within the databag to retreieve
		$item
	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	$path = "/data/{0}/{1}" -f $name, $item

	# Query the chef server using the API to get the named item
	$dbitem = Invoke-ChefQuery -path $path

	# return the item to the calling function
	$dbitem

}
