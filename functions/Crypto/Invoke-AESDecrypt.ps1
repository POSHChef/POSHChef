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


function Invoke-AESDecrypt {

	<#

	.SYNOPSIS
		Function to decrypt an encypted string using a AES symmetric key

	.DESCRIPTION
		Chef uses the AES encryption standard to store sensitive data in a data bag.
		This function takes the encypted data, the key and the IV to decrypt the data

		It will pass back a string or a byte array

	#>

	[CmdletBinding()]
	param (

		[Parameter(Mandatory=$true)]
		# The base64 encoded string or byte array of the data to decrypt
		$data,

		[Parameter(Mandatory=$true)]
		# A base64 encoded string of the key or a byte array
		$key,

		[Parameter(Mandatory=$true)]
		# The base54 encoded string or byte array of the initialization vector
		$iv,

		[switch]
		# Specify if the data should be passed back as a string (default) or bytes
		$raw,

		[string]
		# String representing the AES mode, this is hardcoded into Chef to there
		# is not much flexibility here
		$mode = "aes-256-cbc"

	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	# Create an ASCII encoding object
	$encoding = New-Object System.Text.ASCIIEncoding
	
	# Determine if the key is a string, if it is then turn it into a byte array
	if ($key -is [String]) {
		Write-Log -IfDebug -EventID PC_DEBUG_0029
		$key = $encoding.GetString($key)
	}
	
	# Turn the key into a SHA256 digest
	# create the hasher object
	$hasher = [System.Security.Cryptography.HashAlgorithm]::Create("sha256")
	$digest = $hasher.ComputeHash($key)
	Write-Log -IfDebug -EventId PC_DEBUG_0030 -extra ($digest -join " ")

	# Get byte versions of the encrypted data and the iv
	$bytes = @{}
	
	# if the data is a string then turn into byte array
	if ($data -is [String]) {
		$bytes.data = [System.Convert]::FromBase64String($data.replace("`n", ""))
	} elseif ($data -is [Byte[]]) {
		$bytes.data = $data
	}

	# if the initialization vector is a string then turn into byte array
	if ($iv -is [String]) {
		$bytes.iv = [System.Convert]::FromBase64String($iv)
	} elseif ($iv -is [Byte[]]) {
		$bytes.iv = $iv
	}

	# Create the AES object
	$aes = New-Object System.Security.Cryptography.AesCryptoServiceProvider

	# Set the keysize and the mode
	$mode_parts = $mode -split "-"
	$aes.keysize = $mode_parts[1]
	$aes.Mode = $mode_parts[2]

	# create the decryptor
	$decryptor = $aes.CreateDecryptor($digest, $bytes.iv)

	# perform the decryption
	$bytes.plaintext = $decryptor.TransformFinalBlock($bytes.data, 0, $bytes.data.length)

	# return the string or bytes depending if the raw argument has been passed
	if ($raw) {
		$bytes.plaintext
	} else {
		$encoding.GetString($bytes.plaintext)
	}
}
