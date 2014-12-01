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


function Get-Databag {

	<#

	.SYNOPSIS
		Gets a list of all the items contained within the named databag

	#>

	[CmdletBinding()]
	param (

		[string]
		# Name of the databag to retrieve
		$name
	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	# build up the path to call
	$path = "/data/{0}" -f $name
	
	# Query the chef server using the API to get the named item
	$databag = Invoke-ChefQuery -path $path
	
	# return the databag to the calling function
	$databag


}
