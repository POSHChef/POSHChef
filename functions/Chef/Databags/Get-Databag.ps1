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
		Get a specific databag or list all on the server

	#>

	[CmdletBinding()]
	param (

		[string]
		# Name of the databag to retrieve
		$name
	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	# build up the uri to get the list of environments
	$uri_parts = New-Object System.Collections.ArrayList
	$uri_parts.Add("/data") | Out-Null

	if (![String]::IsNullOrEmpty($name)) {
		$uri_parts.Add($name) | Out-Null
	}

	# Make a call to the chef server to get the environment
	$uri = $uri_parts -join "/"
	$databag = Invoke-ChefQuery -path $uri

	# return the databag to the calling function
	$databag


}
