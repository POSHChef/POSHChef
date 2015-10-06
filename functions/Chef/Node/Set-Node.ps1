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
		# Specify if the node information should be taken as is and pushed
		# back up to the server
		$update,

		[string]
		# Name of the node to update.  This is in case the node is alredy
		# a string
		$name
	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	if ($update) {

		# The node is being updated so assume that the node specified has all of the
		# correct information to pass back to the Chef server

		# set the path for the Invoke-ChefQuery
		if ($node -is [String]) {
			$path = "/nodes/{0}" -f $name
			$postdata = $node
		} else {

			$path = "/nodes/{0}" -f $node.name

			# convert the node to postdata to be sent to the query
			$postdata = $node | ConvertTo-JSON -Compress
		}

	} else {
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

		# Remove the AllNodes key, if it is exists as this is not required
		if ($attrs.ContainsKey("AllNodes")) {
			$attrs.Remove("AllNodes")
		}
		
		# The attributes contain a 'thisrun' key which states, among other things, the logdir for
		# the last run, this needs to be removed from the attributes as it will change on every run
		# and does not need to be sent back to the server
		$attrs.Remove("thisrun") | Out-Null

		if ($attrs.length -gt 0) {

			# add in the recipes and roles that have been discovered to the attrs
			$attrs["recipes"] = $script:session.recipes
			$attrs["roles"] = $script:session.roles

			# add to the $postdata that needs to be sent back to the server
			# this goes into an automatic key
			$postdata["automatic"] = $attrs

		}

		# convert the postdata to a json object
		$postdata = $postdata | ConvertTo-Json -Depth 999 -Compress
	}

	Write-Log -IfVerbose -Extra $postdata -EventId PC_DEBUG_0003

	$response = Invoke-ChefQuery -path $path -method "PUT" -data $postdata
}
