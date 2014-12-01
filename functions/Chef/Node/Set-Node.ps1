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


function Set-Node {

	<#

	.SYNOPSIS
	Creates or updates a node on the chef server

	.DESCRIPTION
	Depending on the parameters passed to the function, the system will 
	attempt to create or update the node on the server

	#>

	[CmdletBinding()]
	param (

		# Existing node information
		$node,

		[Hashtable]
		# Attributes that need to be added to the node
		$attrs,

		[switch]
		$create
	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	# set the method that needs to be specified based on the switch
	$path = "/nodes/{0}" -f $script:session.config.node

	# use the current node information to set the postdata
	$postdata = $node

	# if a runlist has been specified on the command line read this in and add to the postdata
	if ($script:session.local_runlist -ne $false) {

		Write-Log -IfDebug -EventId PC_DEBUG_0004 -extra $script:session.local_runlist

		# ensure that the runlist is an array
		if ($script:session.local_runlist -is [System.String]) {
			$local:runlist = @($script:session.local_runlist)
		} else {
			$local:runlist = $script:session.local_runlist
		}

		# add to the existing hash
		$postdata["run_list"] = $local:runlist
	}

	# check to see if the environment has been set
	if ($script:session.environment -ne $false -and $postdata["chef_environment"] -ne $script:session.environment) {
		$postdata["chef_environment"] = $script:session.environment
	}

	# If the attributes is not false then add to the postdata
	if ($attrs.ContainsKey("AllNodes")) {
		$attrs.Remove("AllNodes")
	}

	if ($attrs.length -gt 0) {
	
		# add in the recipes and roles that have been discovered to the attrs
		$attrs["recipes"] = $script:session.recipes
		$attrs["roles"] = $script:session.roles
		
		# add to the $postdata that needs to be sent back to the server
		# this goes into an automatic key
		$postdata["automatic"] = $attrs
		
	}	

	# convert the postdata to a json object
	$postdata = $postdata | ConvertTo-Json -Depth 999

	Write-Log -IfVerbose -Extra $postdata -EventId PC_DEBUG_0003

	$response = Invoke-ChefQuery -path $path -method "PUT" -data $postdata
}
