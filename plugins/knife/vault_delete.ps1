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


function vault_delete {

	<#

	.SYNOPSIS
		Deletes the specified item from the named vault

	.DESCRIPTION
		Deletes an entire item from the specified vault.

		If you wish to remove a 

	#>

	param (

		[string]
        # Name of the vault
        $vault,

        [string[]]
        # String array of items to remove 
        $name
	)

	Write-Log -Message " "
    Write-log -EventId PC_INFO_0031 -extra ("Deleting Vault Item", "")

	# Check that the named vault exists
	$vault_exists = Invoke-ChefQuery -Path ("/data/{0}" -f $vault) -Passthru

	# if the response is 404 then exit out as no items will be found
	if ($vault_exists.statuscode -eq 404) {
		Write-Log -ErrorLevel -EventId PC_ERROR_0024 -extra $vault -stop
	}

	# iterate around the items that have been passed
	foreach ($id in $name) {

		Write-Log -EventId PC_MISC_0000 -extra $id

		# determine if the current id exists on the chef server
		if ($vault_exists.keys -notcontains $id) {
			Write-Log -EventId PC_MISC_0001 -extra "does not exist, skipping"
			continue
		}

		Write-Log -EventId PC_MISC_0001 -extra "removing" -fgcolour darkgreen

		# Build up the path to delete the two items, the one with the encrypted passwords and the keys
		foreach ($item in @($id, ("{0}_keys" -f $id))) {

			$path = "/data/{0}/{1}" -f $vault, $item

			# run a delete against the chef server
			$result = Invoke-ChefQuery -Method DELETE -path $path
		}
	}
}
