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


function databag_list {


	<#

	.SYNOPSIS
		Display a list of the databags on the server, or list items for a named bag

	.DESCRIPTION
		Databags are useful to hold central bits of information that the system may require, such as the name of any
		users to create for example.

		This function lists the databags that are on the Chef server, or the items within a named databag

	.EXAMPLE

		Invoke-POSHKnife databag list

		Display a list of all the databags on the server

	.EXAMPLE

		Invoke-POSHKnife databag list -name foo

		Display all the item names that are in the specified databag

	#>

	[CmdletBinding()]
	param (

		[string]
		# Name of the databag to list items from
		$name
	)

	# Determine the name of the chef type from the function name
	$chef_type, $action = $MyInvocation.MyCommand -split "_"

	# Build up the hashtable for the arguments to pass to Get-Databag
	$splat = @{}
	if ([String]::IsNullOrEmpty($name)) {
		$extra = "Databags"
	} else {
		$extra = "items in Databag: {0}" -f $name
		$splat.name = $name
	}

	Write-Log -Message " "
	Write-Log -EVentId PC_INFO_0031 -extra ("Listing", $extra)

	# Get a list of the roles currently on the server
	# This so it can be determined if the role already exists or needs to be created
	$items_on_server = Get-Databag @splat

	if ($script:session.knife.return_results) {
		$items_on_server
	} else {

		# Iterate around the items of the server and show list them
		foreach ($item in ($items_on_server.keys | sort)) {

			Write-Log -EventId PC_MISC_0000 -extra ($item)
		}
	}
}
