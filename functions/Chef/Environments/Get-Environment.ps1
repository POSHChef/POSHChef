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


function Get-Environment {

	<#

	.SYNOPSIS
	Retrieve the environment details from the chef server

	.DESCRIPTION
	Given the name of the environment, pull down the details so that the attributes can be retreived

	#>

	[CmdletBinding()]
	param (

		[string]
		# name of the environment to retrieve
		$name

	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	# build up the uri to get the list of environments
	$uri_parts = New-Object System.Collections.ArrayList
	$uri_parts.Add("/environments") | Out-Null

	if (![String]::IsNullOrEmpty($name)) {
		$uri_parts.Add($name) | Out-Null
	}

	# Make a call to the chef server to get the environment
	$uri = $uri_parts -join "/"
	$environment = Invoke-ChefQuery -path $uri

	# if the caller of this function is expecting a returned value pass the environment
	# back
	if ($PSCmdlet.MyInvocation.Line.Trim().startswith('$')) {
		$environment
	} else {

		Write-Log -EventId PC_INFO_0032
		Write-Log -EventId PC_MISC_0001 -extra $name

		# if the default attributes have been set then add them to the session attributes
		if ($environment.default_attributes.count -gt 0) {
			$merged = Merge-Hashtables -primary $environment.default_attributes -secondary $script:session.attributes.environments
			$script:session.attributes.environments = $merged
		}

		# set the name of the environment in the session
		$script:session.environment = $name
	}
}
