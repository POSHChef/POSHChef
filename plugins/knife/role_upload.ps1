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


function role_upload {


	<#

	.SYNOPSIS
		Uploads a role file to the chef server

	.DESCRIPTION
		Once a role has been created in the chef-repo it needs to be uploaded to the Chef server
		so that it can be added to the runlist of a node, another role or an environment.

		This plugin will perform the upload of the specified roles.

		Multiple files can be passed to the plugin to be uploaded.  The specified paths must be an
		absolute path to each role file.

		The name parameter can be used to specify roles that need to be uploaded.  If this is used
		then the plugin will assume that the roles are part of the chef_repo that has been specified
		and look for files that are in the <CHEF_REPO>/roles directory.  The files will have the
		.json extension added if it is not supplied

	.EXAMPLE

		PS C:\> Invoke-POSHKnife role upload -path c:\chef-repo\roles\WebServer.json

		Upload the specified file as a role to the chef server.

	.EXAMPLE

		PS C:\> Invoke-POSHKnife role upload -name WebServer

		This will result in the file <CHEF_REPO>/roles/WebServer.json being uploaded to the file
		if it exists

	#>

	param (

		[string[]]
		# Array of names of roles to be uploaded
		# these will assumed to be a the 'roles' subfolder of the chef_repo setting
		$names

	)

	# Determine the name of the chef type from the function name
	$chef_type, $action = $MyInvocation.MyCommand -split "_"

	# determine the mapping for the chef query
	$mapping = "{0}s" -f $chef_type

	Write-Log -Message " "
	Write-Log -EVentId PC_INFO_0031 -extra ("Uploading", (Get-Culture).TextInfo.ToTitleCase($mapping))

	# Get a list of the roles currently on the server
	$list = Get-Role

	# iterate around the names that have been supplied
	foreach ($name in $names) {

		# build up the hashtable to pass to the Uplaod-ChefItem function
		$splat = @{
			name = $name
			list = $list.keys
			chef_type = "role"
		}

		Upload-ChefItem @splat
	}

}
