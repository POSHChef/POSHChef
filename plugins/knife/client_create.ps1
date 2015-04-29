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



function client_create {

	<#

	.SYNOPSIS
		Creates the specified clients

	.DESCRIPTION
		Sometimes is is necessary to pre-seed the Chef server with nodes that will be accessing it.
		This is so that the private key can be loaded on the machine without the need for pre-registration

		This plugin uses allows the new client to be created.  The private key will be returned as an object
		or optionally can be saved to a file

	.EXAMPLE

		Invoke-POSHKnife client create -name foo -admin

		Key                                                               Name                                                              Password
		---                                                               ----                                                              --------
		-----BEGIN RSA PRIVATE KEY-----...                                foo                                                               foobar

		Creates a new client called 'foo'.  The user will have admin rights within the Chef system.

	.EXAMPLE

		Invoke-POSHKnife client create -name foo,bar -output c:\temp\users

		Creates two new clients and save the private key as 'foo.pem' and 'bar.pem'.

	#>

	[CmdletBinding()]
	param (

		[string[]]
		# List of names of users to create
		$name,

		[switch]
		# Switch to specify if this user should be an administrator or not
		$admin,

		[string]
		# Specify a directory that newly created user details should be saved in
		$output = [String]::Empty
	)

	# Setup the mandatory parameters
	$mandatory = @{
		name = "String array of clients to create (-name)"
	}
	Confirm-Parameters -Parameters $PSBoundParameters -mandatory $mandatory

	# Determine the name of the chef type from the function name
	$chef_type, $action = $MyInvocation.MyCommand -split "_"

	# determine the mapping for the chef query
	$mapping = "{0}s" -f $chef_type

	Write-Log -Message " "
	Write-Log -EVentId PC_INFO_0031 -extra ("Creating", (Get-Culture).TextInfo.ToTitleCase($mapping))

	# Run a query to get the list of users that already exist in chef
	$existing_clients = Invoke-ChefQuery -Path ("/{0}" -f $mapping)

	# create a hash that will store the passwords and the privateky for the users that are created
	$clients = @()

	# iterate around the names that have been passed to the function
	$count = 0
	foreach ($id in $name) {

		# determine if the current id is already on the server
		if ($existing_clients.ContainsKey($id)) {
			Write-Log -EventId PC_INFO_0039 -extra $id
		} else {

			Write-Log -EventId PC_INFO_0038 -extra $id

			# Build up the hashtable which will act as the payload to send to the server
			# This will be turned into a JSON object to pass to the server
			$body = @{
				name = $id
				admin = [boolean] $admin.tostring()
			}

			# Call Invoke-ChefQuery to perform the post
			$result = Invoke-ChefQuery -Method POST -Path ("/{0}" -f $mapping) -Data ($body | ConvertTo-Json -Compress)

			# Add the details of the user to the users array
			$clients += (New-Object PSObject -Property @{Name = $id; Password = $password; Key = $result.private_key})
		}

		# increment the count
		$count ++

	}

	# determine if an output directory was specified
	if ([String]::IsNullOrEmpty($output)) {

		# none was specified so output to the screen
		$clients
	} else {

		# an output directory has been specified
		# check that it exists
		if (!(Test-Path -Path $output)) {
			New-Item -type directory -Path $output | out-null
		}

		# iterate around the users array and craetea file for each user based on the name
		foreach ($client in $clients) {

			# write out the file based on the userbname
			Set-Content -Path ("{0}\{1}.pem" -f $output, $client.name) -Value $client.key
		}
	}
}
