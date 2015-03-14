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


function Get-ModuleFunctions {

	<#

	.SYNOPSIS
		Get a list of the module functions

	.DESCRIOPTION
		So that multiple log parameters can be set per module the Logging module
		needs to understand what functions are associated with the module

		This function will return all the function in the module, including the private ones
		so that when Write-Log is called, it can determine the module it came from and therefore
		the settings that have been applied

	.NOTE
		Write-Log is not used in this function, as this function is used to build the list
		of functions that need to be regsitered with Write-Log

	#>

	[Cmdletbinding()]
	param (

	)

	# Determine the name of the module from the MyInvocation object
	$module = $script:session.module

	# set up the functions array
	$functions = @()

	# Get a list of all the functions in the module
	$files = Get-ChildItem -Recurse *.ps1 -Path $module.path

	# iterate around each of the files
	# and strip off the extension to give the name of the function
	foreach ($file in $files) {
		$function = [System.IO.Path]::GetFileNameWithoutExtension($file.fullname)

		# only add the function to the functions array if it is not this one
		if ($function -ne $MyInvocation.Name) {
			$functions += $function
		}
	}

	# Ensure that Test-Handler and Report-Handler are added to the function list so that
	# these are recognised as coming from POSHChef
	$functions += "Test-Handler"
	$functions += "Report-Handler"

	# return the hashtable of information to the calling function
	$return = @{
		$module.name = $functions
	}

	$return

}
