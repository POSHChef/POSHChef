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


function role_delete {

	<#

	.SYNOPSIS
		Delete a role from the chef server

	.DESCRIPTION
		Removes the selected roles from the chef server
		
		When a role is removed, any server using the role will error the next time it runs as it can no longer find
		the the role to download.

		Roles in the chef-repo are conventionally stored with their filename the same as the ID within the contained JSON.
		For example, take the following JSON for a role:

			{
				"id": "WebServer",
				"description": "Configures the server to be a web server",
				"chef_type": "role",
				"json_class": "Chef::Role",
				"default_attributes": {},
				"override_attributes": {},
				"env_run_lists": {},
				"run_list": {
					"recipe[IIS]"
				}
			}

		The name of the role is 'WebServer' and accordingly the file should be named 'WebServer.json', but it does not have to be.

		When deleting a role the name specified must be the one as specified in the 'ID' field as above.  This also means that the
		role name is case-sensitive.

	.EXAMPLE

		Invoke-POSHKnife role delete -name WebServer

		Attempt to delete the role 'WebServer'

	.EXAMPLE

		Invoke-POSHKnife role delete -name webserver

		This will attempt to delete the role called 'webserver' but if the role uploaded was a shown above this will fail because
		the name is 'WebServer'.

	.EXAMPLE

		Invoke-POSHKnife client role -name WebServer,Users

		Attempt to remove the role 'WebServer' and 'Users'.

	#>

	param (

		[string[]]
		# List of names of users to delete
		$name

	)

	# Determine the name of the chef type from the function name
	$chef_type, $action = $MyInvocation.MyCommand -split "_"
	 
	# determine the mapping for the chef query
	$mapping = "{0}s" -f $chef_type

	Write-Log -Message " "
	Write-Log -EVentId PC_INFO_0031 -extra ("Deleting", (Get-Culture).TextInfo.ToTitleCase($mapping))

	# Get a list of the users on the server so that it can be checked to see if the user exists before deleting
	$items_on_server = Invoke-ChefQuery -Path ("/{0}" -f $mapping)

	# iterate around the names that have been passed
	foreach ($id in $name) {

		# see if the user exists
		$user_exists = $items_on_server.keys | Where-Object { $_ -eq $id }

		# if the user exists then remove it
		if (![String]::IsNullOrEmpty($user_exists)) {
			
			Write-Log -EventId PC_MISC_0000 -extra $id

			$result = Invoke-ChefQuery -Method DELETE -path ("/{0}/{1}" -f $mapping, $id) 
		}
	}
}
