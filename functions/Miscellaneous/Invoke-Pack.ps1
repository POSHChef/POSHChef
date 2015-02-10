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


function Invoke-Pack {

	<#

	.SYNOPSIS
	Reduces the passed string into a byte array which can then be base64 encoded

	.DESCRIPTION
	Takes the specified checksum, as defined in source, and checks each pair of characters as a HEX value.
	A conversion to DEC is performed on this HEX value and it is checked against the ASCII table.

	if the DEC is between 32 and 127 then the actual character that this encodes to is stored
	If not then the DEC value is stored

	Each item is stored as new element in the packed array, which is returned as is to the calling function

	#>

	[CmdletBinding()]
	param (

		[string]
		# The string to be packed
		$source,

		[switch]
		# Whether or not to encode the return
		$encode
	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	# Configure function variables
	# The packed array, this will contain the byte characters that need encoding
	$packed = @()

	# turn the source into a list of components by splitting every two characters
	$components = $source -split '(.{2})' | Where-Object { $_ }

	# iterate around each of the components
	foreach ($component in $components) {

		# Get the decimal value from hex value
		# (Hex is base 16)
		$dec = [Convert]::ToInt32($component, 16)

		# check the decimal value within the bounds of the printable characters in the ASCII table
		if ($dec -ge 32 -and $dec -le 127) {

			# add the actual character to the packed array
			$packed += [char] $dec
		
		} else {

			# otherwise add the decimal value to the array
			$packed += $dec
		}

	}

	# Determine if the encode parameter has been passed
	if ($encode) {
		$packed = Get-Base64 -data $packed
	}

	# return packed to the calling function
	$packed
}
