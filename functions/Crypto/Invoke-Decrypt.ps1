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


function Invoke-Decrypt {

	[CmdletBinding()]
	param (

		[string]
		# Cypher text to decrypt
		$cypher,

		[string]
		# Path to PEM key file
		$pemPath,

		[switch]
		# Specify if this should be a a private decrypt
		$private,

		[switch]
		# Specify if the decrypted data should be passed back as a byte array
		$raw

	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -EventId PC_DEBUG_0017 -extra $MyInvocation.MyCommand

	_InitialiseBouncyCastle

	$keys = _GetKeyPairFromPem $pemPath
	
	$engine = New-Object Org.BouncyCastle.Crypto.Encodings.Pkcs1Encoding (New-Object Org.BouncyCastle.Crypto.Engines.RsaEngine)

	if ($private) {
		$engine.Init($false, $keys.Private)
	} else {
		$engine.Init($false, $keys.Public)
	}
	
    $cypherBytes = [System.Convert]::FromBase64String($cypher)
	$decrypted = $engine.ProcessBlock($cypherBytes, 0, $cypherBytes.Length)

	if ($raw) {
		return $decrypted
	} else {
	    $encoding = New-Object System.Text.ASCIIEncoding	
		return $encoding.getstring($decrypted)
	}
}
