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

function Invoke-ChefRestMethod {

	[CmdletBinding()]
	param (

		[string]
		# The URI of the end point that needs to used
		$uri,

		[hashtable]
		# Hash of headers that need to be added to the request
		$headers = @{},

		[string]
		# The accept string.
		$accept = "application/json",

		[string]
		# REST method, defaults to GET
		$method = "GET",

		[string]
		# The body to be passed with a POST or PUT request
		$body,

		[string]
		# Set the content type to be applued to the request
		$contenttype = "application/json",

		[string]
		# Path to where the file should be downloaded to
		$outfile
	)

	# Function variables
	$data = $false

	# Disable SSL checks
	[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

	# Build up the request using .NET classes as it is not possible to set the correct Accept header using
	# Invoke-RestMethod
	# https://connect.microsoft.com/PowerShell/feedback/details/757249/invoke-restmethod-accept-header
	$request = [System.Net.WebRequest]::create($uri)

	# Set the request method
	$request.Method = $method

	# Set the agent
	# $request.UserAgent = "Chef Knife/11.8.0 (ruby-1.9.3-p448; ohai-6.20.0; i386-mingw32; +http://opscode.com)"
	$request.UserAgent = "POSHChef/{0} (PowerShell {1})" -f $script:session.module.version, $PSVersionTable.PSVersion.tostring()

	# loop round the headers that have been passed
	$headers.keys | ForEach-Object {
		$request.headers.add($_, $headers.item($_))
	}

	# Set the Accept
	$request.Accept = $accept

	# if the content type is not false then add it to the request
	# only set the conttentype if the accept is not '*/*'.  this is so that files can
	# be downloaded from the cookbook
	if ($contenttype -ne $false -and $accept -ne "*/*") {
		$request.ContentType = $contenttype
	}

	# Prepare the body to pass to the endpoint
	if ($method -eq "POST" -or $method -eq "PUT") {

		# get the number of bytes the payload includes
		$enc = [System.Text.Encoding]::GetEncoding("UTF-8")
		[byte[]] $bytes = $enc.GetBytes($body)

		# Set the contentlength of the request
		$request.ContentLength = $bytes.length

		# add the body to the request stream
		$request_stream = [System.IO.Stream] $request.GetRequestStream()
		$request_stream.Write($bytes, 0, $bytes.length)

	}

	# Send the request to the server and get the response
	try {

		$response = $request.GetResponse()

		# Take the response and read from the stream
		$response_stream = $response.GetResponseStream()

		$return = @{}

		# if an outfile has been set ensure a filestream object is used
		if ([String]::IsNullOrEmpty($outfile)) {
			$sr = New-Object system.IO.StreamReader $response_stream

			# Get information about the api version that is actually in use from the response headers
			# this will be used to determine how to interpret the response from the server
			$api_info = @{}
			$api_header = $response.GetResponseHeader("X-Ops-API-Info")

			# Split on the ; character to get the components of the API information
			$components = $api_header -split ";"
			foreach($component in $components) {

				# split the component using the = sign
				$parts = $component -split "="

				# now set the api_info hashtable
				$api_info.$($parts[0]) = $parts[1]

			}

			$return.data = $sr.ReadToEnd()
			$return.apiversion = $api_info.version

		} else {

			$fs = New-Object System.IO.FileStream -ArgumentList $outfile,Create

			# ensure the file is downloaded in chunks
			$buffer = New-Object Byte[] 10KB
			$count = $response_stream.Read($buffer, 0, $buffer.length)
			while ($count -gt 0) {
				$fs.Write($buffer, 0, $count)
				$count = $response_stream.Read($buffer, 0, $buffer.length)
			}


			$fs.Flush()
			$fs.Close()
			$fs.Dispose()
		}

		# build up the return object to be sent to the calling function
		$return.statuscode = [int32] ($response.StatusCode)

	} catch [System.Net.WebException] {

		# An exception has occured
		# get the body of the response as it will have the error message in it
		$response = $_.Exception.Response.GetResponseStream()

		$sr = New-Object System.IO.StreamReader $response

		# build up the return object to be sent to the calling function
		$return = @{
			data = $sr.ReadToEnd()
			statuscode = [int32] $($_.Exception.Response.StatusCode)
		}

		# determine when to exit and when not to
		if ([int]$return.StatusCode -ge 500) {

			Write-Log -ErrorLevel -EventId PC_ERROR_0001 -extra $_.Exception.Message -stop
			$data = $false

		}

	}

	$response_stream.close()

	$return

	# Return a hashtable of the response data and the status code
	# return @{data = $data; statuscode = $statuscode; apiversion = $api_info.version}

}
