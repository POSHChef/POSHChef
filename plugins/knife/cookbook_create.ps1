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


function cookbook_create {

	<#

	.SYNOPSIS
		Creates a skeleton for a new cookbook

	.DESCRIPTION
		A Chef cookbook must conform to a very specific standard so that it can be uploaded to the
		Chef server.  This command will create the skeleton of cookbook.

		The skeleton consists of the structure shown below, and described in the 'Cookbook Structure' of the POSHChef user guide.

			&lt;COOKBOOK_NAME>
		    |-- attributes\
			|-- definitions\
			|-- files\
				|-- default\
					|-- POSHChef\
						|-- &lt;COOKBOOK_NAME>\
							|-- files\
								|-- default\
									|-- tests\
							|-- attributes\
								|-- default.psd1
							|-- resources\
							|-- recipes\
								|-- default.ps1
							|-- templates\
								|-- default\
							| metadata.psd1
			|-- libraries\
			|-- providers\
			|-- recipes\
				|-- default.rb
			|-- recources\
			|-- templates\
				|-- default\
			|-- CHANGELOG.md
			|-- metadata.rb
			|-- README.md

		The cookbook will be created in the specified path or in the path as defined in the configuration.

		This function calls the 'cookbook_extend' plugin to add the POSHChef folder structure
		This latter function was put in so that community cookbooks could be extended

	.EXAMPLE

		Invoke-POSHKnife cookbook create -name IIS

		This will create a new cookbook called IIS in the cookbook directory as specified in the configuration file.

	.EXAMPLE

		Invoke-POSHKnife cookbook create -name IIS,Firewall -path c:\temp\cookbooks

		Create two new cookbooks and place them in the 'c:\temp\cookbooks' folder.
	#>

	param (

		[string[]]
		# List of names of cookbooks to create
		$name,

		[string]
		# Path where the cookbooks should be created
		$path = [String]::Empty,

		[switch]
		# Specify if the cookbook should not be extended
		$noextend
	)

	Write-log -message " "

	# Source the cookbook_extend plugin so that it can be used to add the POSHChef
	# parts to the cookbook
	$cookbook_extend_function = "{0}\cookbook_extend.ps1" -f $PSScriptRoot
	. $cookbook_extend_function

	# iterate around the names that have been passed to the function
	foreach ($id in $name) {

		Write-Log -Eventid PC_INFO_0023 -extra $id

		# Check to see if the id is an absolute path, if it is then use that
		$uri = $id -as [System.Uri]
		if ($uri.IsAbsoluteUri -eq $true) {
			$cbpath = $id

		} else {

			# determine the parent path to use, depending on whether the path has been
			# passed to the plugin or not
			$parent = "{0}\cookbooks" -f $script:session.config.chef_repo
			if (![String]::IsNullOrEmpty($path)) {
				$parent = $path
			}

			$cbpath = "{0}\{1}" -f $parent, $id
		}

		# as the path is absolute we need the name of the cookbooko
		$id = Split-Path -Leaf -Path $cbpath

		Write-Log -EventId PC_INFO_0024
		Write-Log -Eventid PC_MISC_0001 -extra $cbpath

		# Get the username of the person that is creating this cookbook
		$username = $env:username

		# build up an array of the paths that need to be creaated
		$locations = @("attributes"
					"definitions"
					"files\default"
					"libraries"
					"providers"
					"recipes"
					"resources"
					"templates\default")

		# iterate around the paths and create the directories
		foreach ($location in $locations) {

			# build up the path to create
			$p = "{0}\{1}" -f $cbpath, $location

			# Check the path does not exist and only create it if it does not not
			if (!(Test-Path -Path $p)) {
				New-Item -type directory -Path $p | Out-Null
			}
		}

		# Create files in the structure that are useful and compulsory
		# Build up an array of the files
		$files = @("recipes\default.rb"
					"CHANGELOG.md"
					"README.md"
				)

		# Iterate around the files that need to be created
		foreach ($file in $files) {

			# Build up the full path to the file
			$file = "{0}\{1}" -f $cbpath, $file

			# Work out the path to the skeleton file
			$skeleton_file = "{0}\skeleton\cookbook\{1}" -f ($script:session.module.path), (Split-Path -Leaf $file)

			# If the file does not exist then create it using the skeleton file
			if (!(Test-Path -Path $file) -and (Test-Path -Path $skeleton_file)) {

				# get the contents of the skeleton file
				$contents = Get-Content -Path $skeleton_file -raw

				# Write out evaluated contents to the required file
				$cookbook_name = $id
				Set-Content -Path $file -Value ($ExecutionContext.InvokeCommand.ExpandString($contents))
			}
		}

		# Now that the basic cookbook has been created extend it
		if (!$noextend) {
			cookbook_extend -name $cbpath
		}
	}
}
