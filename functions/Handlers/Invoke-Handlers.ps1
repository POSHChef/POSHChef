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

		[hashtable]
		# Hashtable containing the status of the run
		$status,

		[hashtable]
		# All of the resolved attributes for the node
		$attributes,

		[string]
		# The type of handler that needs to be run
		$type = "report"
	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	# get a title from the type of the handler that is being run
	$textinfo = (Get-Culture).TextInfo

	Write-Log " "
	Write-Log -EventId PC_INFO_0057 -extra ($textinfo.ToTitleCase($type))

	# Get all the powershell script that are in the handlers directory
	# Build up the path to the to the handlers directory
	$path = "{0}\{1}" -f $script:session.config.paths.handlers, $type
	$handlers = Get-ChildItem -Path $path -filter "*.ps1" -ErrorAction SilentlyContinue

	# check to see if there are any handlers to run
	if ($handlers.count -gt 0) {
		
		Write-Log -EventId PC_INFO_0059 -extra $handlers.count

		# iterate around each file
		foreach ($handler in $handlers) {

			# Create a splat hashtable of the parameters to pass to the handler
			$splat = @{}
			$all_parameters = @{
				status = $status
				attributes = $attributes
				logparameters = get-logparameters
			}

			# Source the file so that the parameters it supports can be analysed
			. $handler.fullname

			$function_name = "{0}-Handler" -f $type

			# Iterate around the parameters that the handler supports and add each to the splat
			foreach ($param in (Get-Command $function_name).Parameters.Keys) {
				if ($all_parameters.ContainsKey($param)) {
					$splat.$param = $all_parameters.$param
				}
			}

			$result = & $function_name @splat

			# execute the script and pass in the status hashtable
			# $result = & $handler.fullname @splat
		}
	} else {

		Write-Log -EventId PC_INFO_0058
	}

	if ($type -eq "test") {
		return $result
	}
}
