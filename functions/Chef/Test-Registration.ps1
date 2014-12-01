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


function Test-Registration {

	<#

	.SYNOPSIS
	Test that the node is registered with the chef server

	.DESCRIPTION
	This function tests that the client / node is registered with the Chef server.
	However it does not use any remote requests to accomplish this, it just looks to see if there is a 
	validation key available.  This is because if there is no key then it would not be able to execute a
	remote request to the Chef server

	If the key does not exist then the system will call the Invoke-Registration command to register the node using
	the chef-validator

	#>

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	# determine if the path to the key specified in the configuration is an absolute URL 
	# or if not then build up the path relative to the module directory
	if ([System.IO.Path]::IsPathRooted($script:session.config.key)) {
		$client_key = $script:session.config.key
	} else {
		$client_key = "{0}\{1}" -f $script:session.config.paths.conf, $script:session.config.key
	}
	
	Write-Log -IfDebug -EventId PC_DEBUG_0002 -extra $client_key

	# Check that the key specified in the configuration file exists
	if (!(Test-Path -Path $client_key)) {
		Write-Log -WarnLevel -EventId PC_WARN_0001 -extra $client_key

		# Call the registration function
		Invoke-Registration -keypath $client_key

	}


}
