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


function cookbook_delete {

	<#

	.SYNOPSIS
		Deletes the named cookbooks

	.DESCRIPTION
		Uses the Chef Server API to delete the specified cookbooks

	#>

	param (

		[string[]]
		# Name(s) of the cookbooks that the files should be listed from
		$name,

		[string]
		# version of the cookbook to list out
		# Default: _latest
		$version

	)

	# Determine the name of the chef type from the function name
	$chef_type, $action = $MyInvocation.MyCommand -split "_"

	# determine the mapping for the chef query
	$mapping = "{0}s" -f $chef_type

	# determine the version
	# if it is null then use _latest
	if ([String]::IsNullOrEmpty($version)) {
		$version = "_latest"
	}

	Write-Log -Message " "
	Write-Log -EVentId PC_INFO_0031 -extra ("Deleting Cookbooks", (Get-Culture).TextInfo.ToTitleCase($mapping))

	# iterate around the cookbooks that have been specified
	foreach ($cookbook in $name) {

		# build up the uri to send to the function
		$uri = "/{0}/{1}/{2}" -f $mapping, $cookbook, $version

		# get cookbooks from chef
		$detail = Invoke-ChefQuery -Uri $Uri -Method "DELETE"

	}

}
