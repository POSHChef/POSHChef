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


function Invoke-Handlers {

	<#

	.SYNOPSIS
		Iterates around the handlers that have been configured and runs them

	.DESCRIPTION
		Built into the chef-client is the ability to report on the status of the chef run.  These functions
		are called Handlers and are registered with the client on each node that it is run on

		This function mimics this behaviour.  Each of the handlers that have been found in the handlers
		directory of the POSHChef base dir will be sourced and information passed to them

		This means that handlers can be added by recipes and cookbooks to pass the information to other
		systems such as Logstash and Graphite etc

	#>

	[CmdletBinding()]
	param (

		[Parameter(Mandatory=$true)]
		[hashtable]
		# Hashtable containing the status of the run
		$status,

		[hashtable]
		# All of the resolved attributes for the node
		$attributes
	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	Write-Log " "
	Write-Log -EventId PC_INFO_0057

	# Get all the powershell script that are in the handlers directory
	$handlers = Get-ChildItem -Path $script:session.config.paths.handlers -filter "*.ps1"

	# check to see if there are any handlers to run
	if ($handlers.count -gt 0) {
		
		Write-Log -EventId PC_INFO_0059 -extra $handlers.count

		# iterate around each file
		foreach ($handler in $handlers) {

			# execute the script and pass in the status hashtable
			& $handler.fullname -status $status -attributes $attributes
		}
	} else {

		Write-Log -EventId PC_INFO_0058
	}
}
