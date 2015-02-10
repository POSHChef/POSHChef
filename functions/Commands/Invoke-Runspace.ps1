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


function Invoke-Runspace {

	<#

	.SYNOPSIS
	Run the specified command within its own runspace

	.DESCRIPTION
	This function allows a command to be run within its own Runspace
	The reason for doing this is that it make is possible to intercept output from Write-Verbose for example

	#>

	[CmdletBinding()]
	param (
		
		[string]
		# Name of the command to run
		$Command,

		[hashtable]
		# The arguments to supply to the command as a hashtable
		$Arguments,

		[string]
		# The stream of information that we are interested in
		$Stream
	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	# Create the runspace for the command
	Write-Log -IfDebug -EventId PC_DEBUG_0026
	$ps = [management.automation.powershell]::create()

	# Add the command and the parameters
	$null = $ps.AddCommand($Command).AddParameters($Arguments)

	# Create the runspace to execute the commands in
	Write-Log -IfDebug -EventId PC_DEBUG_0027
	$rs = [management.automation.runspaces.runspacefactory]::CreateRunspace()

	# open the runspace
	$rs.Open()

	# if the stream that is being sought is verbose then add in the verbosepreference
	if ($Stream -ieq "verbose") {
		$rs.SessionStateProxy.SetVariable("verbosepreference", "continue")
	}

	# Add the runspace to the powershell object
	$ps.Runspace = $rs

	# Execute the command
	Write-Log -IfDebug -EventId PC_DEBUG_0028 -extra ("{0}" -f $Command)
	$ps.Invoke()

	# now iterate around the stream of information that is has been requested
	foreach ($item in $ps.streams.$Stream) {
		Write-Log -eventid PC_INFO_0045 -extra $item
	}

	# check if there are any errors
	if ($ps.streams.error.count -gt 0) {

		# iterate around all the errors
		foreach ($item in $ps.streams.error) {
			Write-Log -ErrorLevel -Message $item
		}

		# stop the exection of chef
		Write-Log -ErrorLevel -EventId PC_ERROR_0018 -stop
	}

	# Clear up the runspace and powershell objects
	$rs.Dispose()
	$rs = $null

	$ps.Dispose()
	$ps = $null
}
