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


function Confirm-Parameters {

	<#

	.SYNOPSIS
	Confirms the mandatory parameters have been set for this operation

	.DESCRIPTION
	Given a list of parameters and the function that is being invoked, this method will determine
	if the manadtory parameters have been set

	If all successful it will return a list of the parameters to the calling function
	If not it will halt the execution with a list of the parameters that have not been set

	#>

	[CmdletBinding()]
	param (

		[alias("switches")]
		# Object of parameters that needs to be analysed
		$parameters,

		[hashtable]
		# Hashtable containing the keys of the parameters to check for
		# and the help message for that key in the event of it being missing
		$mandatory
	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -EventId PC_DEBUG_0017 -extra $MyInvocation.MyCommand

	# Set method variable to hold the missing parameters
	$required = @()

	# Use the mandatory array and iterate around it to ensure that those items have been set in the parameters object
	foreach ($key in $mandatory.keys) {

		# check the value of the parameter as spcified by the key
		if ([String]::IsNullOrEmpty($parameters.$key) -or ($parameters.$key) -eq $false) {

			# add this key to the missing array
			$required += $mandatory.$key
		}
	}

	# determine if the missing array is empty or not
	if ($required.count -gt 0) {
		Write-Log -ErrorLevel -EventId PC_ERROR_0009 -extra $required -stop
	}

}
