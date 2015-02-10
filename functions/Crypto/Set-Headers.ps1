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

function Set-Headers {

	<#

	.SYNOPSIS
	Build up the headers that are required for a chef API query

	.DESCRIPTION
	Function to build up the headers for the query against the chef server.

	It will also build up the hash that is required for the body and then sign it

	#>

	param (
		[string]
		$path,

		[string]
		$method = "GET",

		$data,

		[hashtable]
		$headers,

		[string]
		# Attribute in the chefconfig to use as the UserId
		$useritem = "client",

		[string]
		# Attribute in the chefconfig to use as the key
		$keyitem = "key"
	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	# generate a timestamp, this must be UTC
	$timestamp = Get-Date -Date ([DateTime]::UTCNow) -uformat "+%Y-%m-%dT%H:%M:%SZ"
	Write-Log -IfDebug -EventId PC_DEBUG_0014 -Extra $timestamp

	# Determine the SHA1 hash of the content
	$content_hash = Get-CheckSum -string $data -algorithm SHA1

	# define the headers hash table
	$headers = @{
		'X-Ops-Sign' = 'algorithm=sha1;version=1.0'
		'X-Ops-UserId' = $script:session.config.$useritem
		'X-Ops-Timestamp' = $timestamp
		'X-Ops-Content-Hash' = $content_hash
		'X-Chef-Version' = $script:session.config.apiversion
	}

  # Create ArrayList to hold the parts of the header that need to be encrypted
	$al = New-Object System.Collections.ArrayList

	$al.Add(("Method:{0}" -f $method.ToUpper())) | Out-Null
	$al.Add(("Hashed Path:{0}" -f $(Get-Checksum -string $path -algorithm SHA1))) | Out-Null
	$al.Add(("X-Ops-Content-Hash:{0}" -f $content_hash)) | Out-Null
	$al.Add(("X-Ops-Timestamp:{0}" -f $timestamp)) | Out-Null
	$al.Add(("X-Ops-UserId:{0}" -f $script:session.config.$useritem.trim())) | Out-Null

	$canonicalized_header = $al -join "`n"

	Write-Log -IfVerbose -EventId PC_VERBOSE_0004 -extra $canonicalized_header

	Write-Log -IfDebug -EventId PC_DEBUG_0016 -extra $keyitem
	$cipher = Invoke-Encrypt -data $canonicalized_header -pempath ("{0}\{1}" -f $Script:Session.config.paths.conf, $Script:Session.config.$keyitem) -private

	# Write out the cipher in Verbose mode
	Write-Log -IfDebug -EventId PC_VERBOSE_0007 -extra $cipher

	# the signature now needs to be split into lines of 60 characters each
	$signature = $cipher -split "(.{60})" | Where-Object {$_}

	# Add the signature to the header
	$loop = 1
	$signature.split("`r") | Foreach-Object {

		# Add each bit to the header
		$headers[$("X-Ops-Authorization-{0}" -f $loop)] = $_

		# increment the counter
		$loop ++
	}

	# if in verbose mode output the headers that have been built up
	Write-Log -IfVerbose -Eventid PC_VERBOSE_0003 -extra ($headers.Keys | Sort-Object $_ | ForEach-Object {"{0}:  {1}" -f $_, ($headers.$_)})

	# return the headers to the calling function
	$headers
}
