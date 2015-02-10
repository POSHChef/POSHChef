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


function cookbook_list {


	<#

	.SYNOPSIS
		Lists all the cookbooks that exist on the Chef server

	.DESCRIPTION
		This function will list out all the cookbooks that exist on the Chef server.

		When removing cookbooks from Chef the name has to be specified correctly.
		Although the Delete function will check to see if the cookbook exists before attempting to remove
		it, it does will not provide any feed back about the correct name.

		This function has no parameters

	.EXAMPLE

		Invoke-POSHKnife cookbook list

		List the cookbooks on the server

	#>

	# Determine the name of the chef type from the function name
	$chef_type, $action = $MyInvocation.MyCommand -split "_"

	# determine the mapping for the chef query
	$mapping = "{0}s" -f $chef_type

	Write-Log -Message " "
	Write-Log -EVentId PC_INFO_0031 -extra ("Listing", (Get-Culture).TextInfo.ToTitleCase($mapping))

	# Get a list of the roles currently on the server
	# This so it can be determined if the role already exists or needs to be created
	$items_on_server = Invoke-ChefQuery -Path ("/{0}" -f $mapping)

	# Iterate around the items of the server and show list them
	foreach ($item in ($items_on_server.keys | sort)) {

		Write-Log -EventId PC_MISC_0000 -extra ($item)
	}
	
}
