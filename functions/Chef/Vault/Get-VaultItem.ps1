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


function Get-VaultItem {

	<#

	.SYNOPSIS
		Function to retieve the specified name and associated password from a named vault

	.DESCRIPTION
		This functionaility has been heavily influenced by the 'chef-vault' project which uses a combination
		of encrypted databags and RSA encryption to securely store passwords on chef.

		This function will attempt to decrpt the credentials of the requested names and pass back an object
		with the data.

	.LINK
		https://github.com/Nordstrom/chef-vault

	#>

	[CmdletBinding()]
	param (
		
		[string]
		# Name of the vault to get the id from
		$vault,

		[string[]]
		# String array of names to get from the vault
		$name
	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	# initlaise array to return to the calling function
	$vaultitems = @{}

	# Obtain a list of all the items in the specified vault
	$items = Get-Databag -name $vault
	
	# iterate around the names that have been requested
	foreach ($id in $name) {

		# check to see if the id exists in the list of items obtained
		if (!($items.keys -contains $id)) {
			Write-Log -WarnLevel -EventId PC_WARN_0009 -extra @($vault, $name)
			continue
		}

		# get the keys that are able to decrypt the password for this id
		$keys = Get-DatabagItem -name $vault -item ("{0}_keys" -f $name) 

		# check that this client is allowed to decrypt the password
		if (!($keys.containskey($script:session.config.client))) {
			Write-Log -ErrorLevel PC_ERROR_0022 -extra @($script:session.config.client, $id)
			continue
		}
		
		# get the actual credentials for this id
		$creds = Get-DatabagItem -name $vault -item $id

		# as this client is allowed to decrypt the key call the AES decrypt function to do so
		# make sure the function uses a private decrypt and passes back the byte array of the plaintext
		$aes_key_bytes = Invoke-Decrypt -cypher $keys.$($script:session.config.client) -pempath ([System.IO.Path]::Combine($script:session.config.paths.conf, $script:session.config.key)) -private -raw

		# iterate around each encrypted section of the creds and decrupt them
		$decrypted = @{}
		foreach ($part in @("username", "password")) {
			
			# Call the AESDecrypt function to decrypt the username and password in the vault
            $plaintext = Invoke-AESDecrypt -data $creds.$part.encrypted_data -iv $creds.$part.iv -key $aes_key_bytes | ConvertFrom-JsonToHashtable

			$decrypted.$part = $plaintext.json_wrapper
		}
		
		# add the decrypted to the vaultitems array
		$vaultitems.$id += $decrypted
	}

	# return the vaultitems to the calling function
	$vaultitems
}
