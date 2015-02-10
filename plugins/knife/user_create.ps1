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



function user_create {

	<#

	.SYNOPSIS
		Creates the specified users

	.DESCRIPTION
		This plugin will create the specified users.  Users have to be created for anyone that
		will be accessing the Web UI or authoring and managing cookbooks through the use of POSHKnife.

		When a user is created the password can be specified or one will be generated for the user.
		The response from the server for a new user is to provide the private key for that user.  This is a onetime
		chance to save the key and pass it onto the user.

		The key must be configured in the knife.psd1 file of the users workstation so that they are able to send
		commands to the chef server.  The key is what signs the requests so that the Chef server knows that the
		requestor is valid.

		If a user looses their private key they will have to have it regenerated on the server, which will invalidate
		the existing key.

		The plugin will either output information on the pipeline or it can be saved to an output directory.  The former
		is useful to be able to email people their information immediately.

	.EXAMPLE

		Invoke-POSHKnife -name foo -password foobar -admin

		Key                                                               Name                                                              Password
		---                                                               ----                                                              --------
		-----BEGIN RSA PRIVATE KEY-----...                                foo                                                               foobar  

		Creates a new user called 'foo' with a password of 'foobar'.  The user will have admin rights within the Chef system.

	.EXAMPLE

		Invoke-POSHKnife -name foo,bar -output c:\temp\users

		Creates two new users with automatically generated passwords and saves the details as 'foo.txt' and 'bar.txt'.

	#>

	param (

		[string[]]
		# List of names of users to create
		$name,

		[string[]]
		# Array of passwords to assign to each user
		# If this is null then automatic passwords are generated
		$passwords,

		[switch]
		# Switch to specify if this user should be an administrator or not
		$admin,

		[string]
		# Specify a directory that newly created user details should be saved in
		$output = [String]::Empty
	)

	# Determine the name of the chef type from the function name
	$chef_type, $action = $MyInvocation.MyCommand -split "_"
	 
	# determine the mapping for the chef query
	$mapping = "{0}s" -f $chef_type

	Write-Log -Message " "
	Write-Log -EVentId PC_INFO_0031 -extra ("Creating", (Get-Culture).TextInfo.ToTitleCase($mapping))

	# Run a query to get the list of users that already exist in chef
	$result = Invoke-ChefQuery -Path ("/{0}" -f $mapping)

	# create a hash that will store the passwords and the privateky for the users that are created
	$users = @()

	# iterate around the names that have been passed to the function
	$count = 0
	foreach ($id in $name) {

		# determine if the current id is already on the server
		if ($result.ContainsKey($id)) {
			Write-Log -EventId PC_INFO_0039 -extra $id
		} else {

			Write-Log -EventId PC_INFO_0038 -extra $id

			# determine the password for this user
			# if the password array is not empty and there is a vlaue at the same element use that
			if ($passwords.Count -gt 0 -and ![String]::IsNullOrEmpty($passwords[$count])) {
				$password = $passwords[$count]
			} else {

				# generate a random password for the user
				$password = [system.web.security.membership]::GeneratePassword(12,0)
			}

			# Build up the hashtable which will act as the payload to send to the server
			# This will be turned into a JSON object to pass to the server
			$body = @{
				name = $id
				admin = [boolean] $admin.tostring()
				password = $password
			}

			# Call Invoke-ChefQuery to perform the post
			$result = Invoke-ChefQuery -Method POST -Path ("/{0}" -f $mapping) -Data ($body | ConvertTo-Json)

			# Add the details of the user to the users array
			$users += (New-Object PSObject -Property @{Name = $id; Password = $password; Key = $result.private_key})
		}

		# increment the count
		$count ++

	}

	# determine if an output directory was specified
	if ([String]::IsNullOrEmpty($output)) {

		# none was specified so output to the screen
		$users
	} else {

		# an output directory has been specified
		# check that it exists
		if (!(Test-Path -Path $output)) {
			New-Item -type directory -Path $output | out-null
		}

		# iterate around the users array and craetea file for each user based on the name
		foreach ($user in $users) {
			
			# set the body for the text file
			$text = @"
Username:    $($user.name)

Password:    $($user.password)

Chef key:

$($user.key)
"@

			# write out the file based on the userbname
			Set-Content -Path ("{0}\{1}.txt" -f $output, $user.name) -Value $text
		}
	}
}
