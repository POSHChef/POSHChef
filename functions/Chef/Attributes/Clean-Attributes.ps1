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


function Clean-Attributes {

	<#

	.SYNOPSIS
	Given the DSC Configuration data return a hashtable that can be passed to Chef as is

	#>

	[CmdletBinding()]
	param (

		[hashtable]
		# DSC configuration data
		$configurationdata
	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	Write-Log " "
	Write-Log -EventId PC_INFO_0022

	# Set the attrs hash that will be added to and returned
	$attrs = @{}

	# Only attempt to remove attributes if the configurationdata has an AllNodes child
	if ($configurationdata.ContainsKey("AllNodes")) {
		# Remove the nodename from the attributes
		$attrs = $configurationdata.AllNodes[0]
		$attrs.Remove("Nodename")
		$attrs.Remove("PSDscAllowPlainTextPassword")
	}

	# return the attributes to the calling function
	$attrs
}
