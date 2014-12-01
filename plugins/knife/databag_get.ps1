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


function databag_get {

	<#

	.SYNOPSIS
		Show a list of all the items in the named databag

	#>


	param (

		[string[]]
		# List of names of database to create
		$name
	)

	
	# Determine the name of the chef type from the function name
	$chef_type, $action = $MyInvocation.MyCommand -split "_"

	# determine the mapping for the chef query
	$mapping = "/data"

	Write-Log -Message " "
	Write-Log -EVentId PC_INFO_0031 -extra ("Getting", "Databags")

	# iterate around all the names that have been specified
	foreach ($bag in $name) {

		Write-Log -EventId PC_MISC_0000 -extra $bag

		# get the information about the databag
		$items = Invoke-ChefQuery -Uri ("/data/{0}" -f $bag)

		foreach ($item in $items.keys) {
			write-log -eventid PC_MISC_0001 -extra $item
		}

	}
}
