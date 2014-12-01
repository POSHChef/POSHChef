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


function Get-Node {

	<#

	.SYNOPSIS
	Retrives a node from the chef server

	#>

	[CmdletBinding()]
	param (
		[string]
		# The node to get information about
		$name = [String]::Empty,

		[switch]
		$passthru
	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	# if the node is null then use the one configured in the session
	if ([String]::IsNullOrEmpty($name)) {
		$name = $script:session.config.node
	}

	# Run the chefquery to attempt to get the node from the server
	$path = "/nodes/{0}" -f $name
	$node = Invoke-ChefQuery -path $path -passthru

	# return to the calling function
	$node
}
