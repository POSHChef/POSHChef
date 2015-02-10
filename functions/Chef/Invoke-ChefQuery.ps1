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


function Invoke-ChefQuery {

	<#

	.SYNOPSIS
	Run the desired query against chef and pass back an object

	#>

	[CmdletBinding()]
	param (

		[alias("path")]
		# Path that is being requested from the chef server
		$uri,

		[string]
		# Method to be used on the REST request
		$method = "GET",

		# Data that needs to be passed with the request
		$data = [String]::Empty,

		[string]
		# Attribute in the chefconfig to use as the UserId
		$useritem = "client",

		[string]
		# Attribute in the chefconfig to use as the key
		$keyitem = "key",

		[switch]
		# Denote wether the system should get the raw data from the file
		# insetad of an object
		$raw,

		[string]
		# Content type of the request
		$contenttype = "application/json",

		[string]
		# The Md5 checksum of the content
		$data_checksum = $false,

		[switch]
		# State whether to passthru, e.g. any errors should be passed back to the calling function as well
		$passthru
	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	Write-Log -IfDebug -EventId PC_DEBUG_0005 -extra $uri

	# if the data is a hashtable convert it to a json string
	if ($data -is [Hashtable]) {
		$data = $data | ConvertTo-JSON
	}

	# If the path is a string then turn it into a System URI object
	if ($uri -is [String]) {
		$uri = [System.Uri] $uri

		# If the scheme is empty build up a uri based on the server in configuration and the path that has been specified
		if ([String]::IsNullOrEmpty($uri.Scheme)) {
			$uri = [System.Uri] ("{0}{1}" -f $script:Session.config.server, $uri.OriginalString)
		}
	}

	# Sign the request and build up the headers
	$headers = Set-Headers -Path $uri.AbsolutePath -Method $method -data $data -useritem $useritem -keyitem $keyitem

	# if the data_checksum is not false add it to the headers
	if ($data_checksum -ne $false) {
		$headers["content-md5"] = $data_checksum
	}

	# Build up a splat hash to pass to invoke-rest method
	# this is so that the headers that the options being sent can be show in verbose mode
	$splathash = @{uri = $uri.OriginalString
				   headers = $headers
				   method = $method
				   body = $data
				   contenttype = $contenttype}

	# if the raw parameter has been specified then set the accept object
	if ($raw) {
		$splathash.accept = "*/*"
	}

	# output the splathash if in verbose mode
	Write-Log -IfVerbose -EVentid PC_VERBOSE_0002 -extra ($splathash.Keys | ForEach-Object {"{0}:  {1}" -f $_, ($splathash.$_)})

	# Run the request against the chef server
	$response = Invoke-ChefRESTMethod @splathash

	# Analyse the information that has come back from the server
	if (200..204 -contains $response.statuscode) {

		# set the return value
		$return = $response.data
		
		# if not raw then turn the response data into a hashtable
		if (!$raw -and ![String]::IsNullOrEmpty($return)) {
			$return = $return | ConvertFrom-JsonToHashtable
		}

	}

	# check the response to see if there is an error
	#if (![String]::IsNullOrEmpty($response)) {

	#	if ((Get-Member -InputObject $response -MemberType NoteProperty -Name "error") -and !$passthru) {
		
			# There is an error so throw an exception
	#		Write-Log -ErrorLevel -EventId PC_ERROR_0008 -extra $response.error -stop
	#	}
	#}

	# return an object generated from the JSON
	$return
	

}
