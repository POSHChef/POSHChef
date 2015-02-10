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


function environment_upload {


	<#

	.SYNOPSIS
		Upload an environment object to the chef server

	.DESCRiPTION
		Environments are created by writing JSON files with the required options.
		These files then need to be uploaded to the chef server in order for them to be
		accessible and useable.

		During upload the Chef server will check to ensure that the content of the environment
		is valid.  If not then an error message regarding the fault will be presented.

		The function will check that the environment file is valid JSON before an upload
		is attempted.

		Unlike cookbooks the full path to the role(s) file must be specified.  Multiple paths
		to role files can be specified
		
	.EXAMPLE

		Invoke-POSHKnife role upload -path "c:\temp\roles\base.json"

		This will attempt to upload the role contained within the 'base.json' file
	#>

	param (

		[string[]]
		# String array of paths to the roles to upload
		$path
	)

	# Determine the name of the chef type from the function name
	$chef_type, $action = $MyInvocation.MyCommand -split "_"

	# determine the mapping for the chef query
	$mapping = "{0}s" -f $chef_type

	Write-Log -Message " "
	Write-Log -EVentId PC_INFO_0031 -extra ("Uploading", (Get-Culture).TextInfo.ToTitleCase($mapping))

	# Get a list of the roles currently on the server
	# This so it can be determined if the role already exists and needs to be upadted (PUT) or if it is new (POST)
	$items_on_server = Invoke-ChefQuery -Path ("/{0}" -f $mapping)
	
	# iterate around the paths that have been passed to the function
	foreach ($p in $path) {

		# attempt to the find the file in the current path
		$item_files = @(Get-ChildItem -Path $p -Filter "*.json")

		# if some files have been found iterate around then
		if ($item_files.Count -gt 0) {

			foreach ($item_file in $item_files) {

				# get the contents of the file
				$data = Get-Content -Path $item_file.Fullname -raw

				# tuen the data into an opbject to that the name of it can be determined
				$item = $data | ConvertFrom-JSON

				Write-Log -EventId PC_MISC_0000 -extra $item.name

				# Determien if the item exists ont he server, this is to work out the method to use
				$item_exists = $items_on_server.keys | Where-Object { $_ -eq $item.name }

				# determine the method and the URI for the chef rest call
				if (![String]::IsNullOrEmpty($item_exists)) {
					$method = "PUT"
					$uri = "/{0}/{1}" -f $mapping, $item.name
					$action = "Updating"
				} else {
					$method = "POST"
					$uri = "/{0}" -f $mapping
					$action = "Adding"
				}

				Write-Log -EventId PC_INFO_0030 -extra ($action, $chef_type)

				$result = Invoke-ChefQuery -Method $method -path $uri -data $data
			}
		}
	}
	
}
