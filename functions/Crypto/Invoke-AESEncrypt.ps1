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


function Invoke-AESEncrypt {


	[CmdletBinding()]
	param (

		[string[]]
		# String array of data that needs to be encrypted
		$data
	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	# create the return hash
	$return = @{encrypted = @()}

	# Create the aes object
	$aes = New-Object System.Security.Cryptography.AesCryptoServiceProvider
	
	# Generate the Key and the IV
	$aes.GenerateKey()
	$aes.GenerateIV()

	# add the key to the return array before it is turned into a digest
	$return.key = $aes.key

	# create a 256 digest of the key
	$hasher = [System.Security.Cryptography.HashAlgorithm]::Create("sha256")
	$aes.key = $hasher.ComputeHash($aes.key)

	# iterate around the data that has been passed and encrypt it
	foreach ($d in $data) {
	
		# craete an encoding object to use
		$encoding = New-Object System.Text.ASCIIEncoding

		# create the encryptor object
		$encrypt = $aes.CreateEncryptor()

		# turn the data into bytes
		$bytes = $encoding.GetBytes($d)

		# encrypt the string
		$encrypted = $encrypt.TransformFinalBlock($bytes, 0, $bytes.length)
		
		$return.encrypted += @(,$encrypted)
	}

	# add the IV and the Key to the return hash
	$return.iv = $aes.iv
	

	# return the encrypted information
	$return
}
