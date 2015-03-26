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

function cookbook_upload {

	<#

	.SYNOPSIS
		Uploads the specified cookbook to the Chef server

	.DESCRIPTION
		When cookbooks have been written they need to be uploaded to the Chef server so that they can
		be added to a node's run list.

		This function will ensure that all the files are uploaded when invoked.  If the cookbook already
		exists on the Chef server then only those files that have changed will be uploaded.

		There are certain conventions that have to be followed for the cookbook to be valid.  One of these
		is that the native recipe files must exist in order for them to be selectable.  Before the files
		are uploaded the function will check for PowerShell based recipe files in:

			files\default\POSHChef\recipes

		For any file that is found a '.rb' version will be created in

			recipes\

		The function will also codegen the metadata.rb file in the root of the cookbook based on information
		from the 'metadata.psd1' file in the POSHChef section of the cookbook.

		During upload those files that have been uploaded will be highlighted (when viewed on the console).

	.EXAMPLE

		Invoke-POSHKnife cookbook upload -name IIS

		Upload the 'IIS' cookbook located in the directory as specified in the 'knife.psd1' configuration file.

	.EXAMPLE

		Invoke-POSHKnife cookbook upload -name IIS -path C:\temp\cookbooks

		Attempt to upload the cookbook 'IIS' from the path 'C:\temp\cookbooks'

	#>

	[CmdletBinding()]
	param (

		[string[]]
		# Name of the cookbook(s) to upload
		$names,

		[string]
		# The path where the cookbook should be created
		$path
	)

	Write-Log -Message " "
	Write-Log -Eventid PC_INFO_0025

	# Setup the mandatory parameters
	$mandatory = @{
		names = "String array of cookbooks to upload to the Chef server (-name)"
	}

	Confirm-Parameters -Parameters $PSBoundParameters -mandatory $mandatory

	# if the path is null or empty then set to the default path
	if ([String]::IsNullOrEmpty($path)) {
		$path = "{0}\cookbooks" -f $script:session.config.chef_repo
	}

	# Iterate around the names that have been supplied
	foreach ($name in $names) {

		# determine the path to the cookbook
		$cookbook_path = "{0}\{1}" -f $path, $name

		# If the cookbook path exists, iterate around all the files and get a checksum
		if (Test-Path -Path $cookbook_path) {

			$cookbook_path = Resolve-Path -Path $cookbook_path

			Write-Log -EventId PC_MISC_0000 -extra $name

			# ensure that the recipe stub files exist in the main recipes area so that they are selectable from chef
			Set-RecipeStubs -Path $cookbook_path

			# Generate the metadata.rb file from the metatdata.psd1 file and get the metadata to send to the server
			$metadata = Set-Metadata -Path $cookbook_path

			# Create an object that will generate the MD5 checksums of the files
			#$md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
			#$utf8 = New-Object -TypeName System.Text.UTF8Encoding

			# create a hashtable to hold the checkum file mapping
			$checksum_files = @{}

			# craete an array to hold all of the checksums that have been found
			$checksums = @{checksums = @{}}

			# get a list of all the files in the directory
			$files = Get-ChildItem -Path $cookbook_path -Recurse | Where-Object { $_.PSISContainer -eq $false }

			# iterate around the files and add each checksum to the array
			foreach ($file in $files) {

				# work out the checksum of the file
				$checksum = Get-Checksum -Path $file.fullname -NoBase64

				# add the checksym and the file to the hashfile, but only if it does not already exist
				if ($checksum_files.keys -notcontains $checksum) {
					$checksum_files.$checksum += $file.fullname
				}

				# add the checksum to the array
				$checksums.checksums.$checksum = $null

			}

			# Perform a post of the checksums to determine which files need to be uploaded
			$results = Invoke-ChefQuery -path "/sandboxes" -method "POST" -data ($checksums | ConvertTo-Json -Depth 99)

			Write-Log -EventId PC_MISC_0001 -extra "Determine which files need to be uploaded"

			# iterate around the checksums in the result and determine which files need to be updated
			foreach ($checksum in $results.checksums.keys) {

				# determine if the file needs uploading
				if ($results.checksums.$checksum.needs_upload -eq $true) {
					Write-Log -EventId PC_MISC_0002 -extra ("'{0}' needs uploading" -f ($checksum_files.$checksum.replace("$cookbook_path\", ""))) -fgcolour darkred

					# Call the Invoke-ChefQuery to upload the file
					$data = Get-Content -Path ($checksum_files.$checksum) -Raw
					$data_checksum = Invoke-Pack -source $checksum -encode

					# create an argument splat
					$splat = @{
						path = $results.checksums.$checksum.url
						contenttype = "application/x-binary"
						method = "PUT"
						data = $data
						data_checksum = $data_checksum
					}

					$response = Invoke-ChefQuery @splat

				} else {
					Write-Log -EventId PC_MISC_0002 -extra ("'{0}' has not changed" -f ($checksum_files.$checksum.replace("$cookbook_path\", ""))) -fgcolour darkgreen
				}
			}

			# Now that the files have been uploaded, commit the sandbox
			$results = Invoke-ChefQuery -path $results.uri -method "PUT" -data (@{is_completed = $true} | ConvertTo-Json)

			# Now build up the manifest that needs to be sent to the server when uploading cookbooks
			$manifest = @{attributes = @()
						  definitions = @()
						  files = @()
						  libraries = @()
						  providers = @()
						  recipes = @()
						  resources = @()
						  root_files = @()
						  templates = @()

						  metadata = $metadata

						  "frozen?" = $false

						  name = "{0}-{1}" -f $metadata.name, $metadata.version
						  cookbook_name = $metadata.name
						  version = $metadata.version
						  json_class = "Chef::CookbookVersion"
						  chef_type = "cookbook_version"}

			# set the types that a file can be
			$components = @("files", "recipes", "templates")

			# Set the files as these have just been uploaded
			foreach ($checksum in $results.checksums) {

				if ($checksum_files.ContainsKey($checksum)) {

					# trim the beginning of the file so it is relative to the cookbook
					$relative_path = $checksum_files.$checksum.replace("$cookbook_path\", "")
					#$relative_path = $file.FullName -replace ("{0}\\" -f [Regex]::Escape($cookbook_path)), ""

					# turn backslashes into forward slashes
					$relative_path = $relative_path -replace "\\", "/"

					# determine the component of the cookbook from the path, e.g. where it belongs in the cookbook
					$component = ($relative_path -split "/")[0]

					# set a default for the component if it is not in components
					if ($components -notcontains $component) {
						$component = "root_files"
					}

					# determine the name to be set in the manifest for this component
					switch ($component) {
						"files" {

							# set the name which is relative to the files directory and the specificy of the file
							# in this case it is default
							$name = $relative_path -replace "files/default/", ""
						}

						"recipes" {

							# set the name which is relative to the recipes path
							$name = $relative_path -replace "recipes/", ""

						}

						"templates" {
							$name = $relative_path -replace "templates/", ""
						}

						"root_files" {
							$name = $relative_path
						}
					}

					# build up a hash for this file
					$hash = @{path = $relative_path
							  name = $name
							  checksum = $checksum
							  specificity = "default"}

					$manifest.$component += $hash
				}
			}

			# The recipes and the providing hashtables in the metadata need to be populated
			foreach ($recipe in $manifest.recipes) {

				# determine the name of the recipe including the cookbook
				$name = "{0}::{1}" -f $manifest.metadata.name, $recipe.name

				# add an entry to each of the hash tables
				$manifest.metadata.providing.$name = ">= 0.0.0"
				$manifest.metadata.recipes.$name = ""
			}

			# If in debug mode output the manifest
			Write-Log -IfDebug -EventId PC_DEBUG_21 -extra ($manifest | convertto-json)

			# Finally save the manifest on the server
			$results = Invoke-ChefQuery -path ("/cookbooks/{0}/{1}" -f $manifest.metadata.name, $manifest.version) `
										-method "PUT" `
										-data ($manifest | ConvertTo-Json -Compress -Depth 50)

		}
	}

}


function Set-Metadata {

	<#

	.SYSNOPSIS
	Function to generate the necessary metadata.rb file as required by Ruby

	.DESCRIPTION

	Return the metadata to the calling function


	#>

	[CmdletBinding()]
	param (

		[string]
		# path to the cookbook on disk
		$path
	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	# set default values for flags
	$community_cookbook = $false

	# if the root directory contains a Gemfile then assume that this is from a community cookbook, and
	# the main metadata file should not be updated
	if (Test-Path -Path ("$path\Gemfile" -f $path)) {

		Write-Log -LogLevel Warn -EventId PC_WARN_0011
		$community_cookbook = $true
	}

	# Attempt find the metadata.psd1 file in the files section of the cookbook
	$metadata_file = Get-ChildItem -Recurse -Path ("{0}\files" -f $path) -Include "metadata.psd1"

	# Only proceed if the file has been found
	if (![String]::IsNullOrEmpty($metadata_file)) {

		# read in the contents of the file
		$metadata = Invoke-Expression (Get-Content -Path $metadata_file -Raw)

		# create an array to hold the lines to be added to the metadata.rb file
		$lines = @()

		# iterate around the metadata and create the necessary lines
		foreach ($key in $metadata.keys) {

			# begin the line
			$line = $key.PadRight(20)

			# check to see if the key is long_description as this has to have some ruby code added
			if ($key -eq "long_description") {
				$line += "IO.read(File.join(File.dirname(__FILE__), '{0}'))" -f $metadata.$key
			} else {
				# build up the line that needs to be appended
				$line += "'{0}'" -f $metadata.$key
			}

			# add the line to the lines array
			$lines += $line
		}

		# set the path to the metadata.rb file
		$cookbook_metadata_file = "{0}\metadata.rb" -f $path

		# Write out the metadata to the ruby based file, only if it is not a community cookbook
		if ($community_cookbook -eq $false) {
			Set-Content -Path $cookbook_metadata_file -Value ($lines -join "`n")
		}
	}

	# Get the long_description from the file that is referenced
	$readme = Get-Content -Path ("{0}\{1}" -f $path, $metadata.long_description) -Raw
	$metadata.long_description = $readme.ToString()

	# add in the extra parameters that are required in the metadata
	foreach ($item in @("platforms", "dependencies", "recommendations", "suggestions", "conflicting", "replacing", "attributes", "groupings", "providing", "recipes")) {
		$metadata.$item = @{}
	}

	# Return the metadata to the calling function
	$metadata
}

function Set-RecipeStubs {

	<#

	.SYSNOPSIS
	Ensures that recipe stubs exist in the main recipes area

	#>

	[CmdletBinding()]
	param (

		[string]
		# path to the cookbook on disk
		$path
	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	Write-Log -EventId PC_MISC_0001 -extra "Checking recipe stub files exist"

	# set the string that will be added to the file
	$content = @'
#
# $recipe_name stub file
#
# This empty recipe file can be set on the node so that when POSHChef
# runs it knows to call the DSC Recipe of the same name

'@

	# Get a list of the recipes in the files area of the cookbook
	$posh_recipes = Get-ChildItem -Recurse -Path ("{0}\files" -f $path) -Include "*.ps1" | Where-Object { $_.Directory.Name -eq "recipes"}

	# Iterate around the files and get its name, based on the filename and craete a stub file if it does not exit
	foreach ($posh_recipe in $posh_recipes) {

		# get the name of the file, withouth the extension
		$recipe_name = [System.IO.Path]::GetFileNameWithoutExtension($posh_recipe.name)
		$recipe = "{0}\recipes\{1}.rb" -f $path, $recipe_name

		# If in debug mode display the path to the recipe
		Write-Log -IfDebug -EventId PC_DEBUG_0022 -extra $recipe

		# check to see if the file exists, create it if it does not
		if (!(Test-Path -Path $recipe)) {

			# Set the content of the stub file with that above
			Set-Content -Path $recipe -Value ($ExecutionContext.InvokeCommand.ExpandString($content))
		}
	}
}
