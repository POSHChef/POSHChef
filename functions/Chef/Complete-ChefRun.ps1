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


function Complete-ChefRun {

	<#

	.SYNOPSIS
	Function to complete the chefrun

	.DESCRIPTION
	When the chef run completes successfully, or it fails, information still needs to be sent back to the chef server
	This function is called at the end of the run, if things have run successfully or by the trap that has been setup
	to denote that the fun was a failure

	#>

	[CmdletBinding()]
	param (

		[hashtable]
		# The run_status object
		$run_status,

		[switch]
		# indicate if the run was successful
		$success,

		[switch]
		# indicate if the run failed
		$fail,

		# the execption that may have been passed
		$exception,

		[hashtable]
		# Node attributes
		$attributes

	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	# It is assumed that when the system is here the run is complete
	# we need to do this before the last Update so that the timings are the same
	# Set the elapsed and stop times
	$run_status.end = Get-FormattedDate
	$run_status.elapsed = $run_status.stopwatch.elapsed.totalseconds

	<#
	# set the status flag based on the switch
	if ($success) {
		$run_status.status = "successful"
	} elseif ($fail) {
		$run_status.status = "failed"

		# add in the exception message
		$run_status.debug = @{}
		$run_status.debug.exception = $_
	}
	#>
	
	# Combine the run_status information with the node_attrubutes under the last_run element
	$node_attributes = Merge-Hashtables -primary (Get-LastRun -status $run_status) -secondary $attributes

	# Add in ohai_time as an attribute as this is how Chef knows when a node has checked in
	$node_attributes.ohai_time = (New-TimeSpan -Start (Get-Date -Date "01/01/1970") -End (Get-Date)).TotalSeconds

	# Update the node with the attributes
	Update-Node -attrs $node_attributes
	
	Write-Log " "
	Write-Log -EventId PC_INFO_0015 -extra $run_status.elapsed

}
