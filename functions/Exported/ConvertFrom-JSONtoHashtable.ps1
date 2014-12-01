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


function ConvertFrom-JsonToHashtable {

	<#

	.SYNOPSIS
		Helper function to take a JSON string and turn it into a hashtable

	.DESCRIPTION
		The built in ConvertFrom-Json file produces as PSCustomObject that has case-insensitive keys.  This means that
		if the JSON string has different keys but of the same name, e.g. 'size' and 'Size' the comversion will fail.

		Additionally to turn a PSCustomObject into a hashtable requires another function to perform the operation.
		This function does all the work in step using the JavaScriptSerializer .NET class

	#>

	[CmdletBinding()]
	param(

		[Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
		[AllowNull()]
		[string]
		$InputObject
	)

	# Perform a test to determine if the inputobject is null, if it is then return an empty hash table
	if ([String]::IsNullOrEmpty($InputObject)) {

		$dict = @{}

	} else {
		
		# load the required dll
		[void][System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")
		$deserializer = New-Object -TypeName System.Web.Script.Serialization.JavaScriptSerializer
		$dict = $deserializer.DeserializeObject($InputObject)

	}
	
	return $dict
}
