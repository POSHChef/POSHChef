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


function Get-LastRun {

	<#

	.SYNOPSIS
	Returns a hashtable that can be combined with the node_attributes with information about the last run

	.DESCRIPTION
	It is desirable to have information about how the run has performed, this function produces a LastRun attribute
	hash that can be combined with the node_attributes, this is to support the knife plugin 'lastrun'

	.LINK
	https://github.com/jgoulah/knife-lastrun

	#>

	[CmdletBinding()]
	param (

		[hashtable]
		[alias("status")]
		# Hashtable containing the status information about the run
		$run_status
	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	# declare an empty hash
	$data = @{}

	# Iterate around the run_status and extract the relevant information
	$relevant = $run_status.GetEnumerator() | Where-Object { @("start", "end", "elapsed") -contains $_.name }

	foreach ($item in $relevant) {
		# add each information to the data hash
		$data.($item.name) = $item.value
	}

	# return the necessary format of data
	@{
		lastrun = @{
			status = $run_status.status
			runtimes = $data
		}
	}
}
