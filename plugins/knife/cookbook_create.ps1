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
		$path
	)

	Write-log -message " "

	# iterate around the names that have been passed to the function
	foreach ($id in $name) {

		Write-Log -Eventid PC_INFO_0023 -extra $id

		if ([String]::IsNullOrEmpty($path)) {
			$path = $script:session.config.paths.cookbooks
		}

		# determine the path to the cookbook
		$cookbook_path = "{0}\{1}" -f $path, $id

		Write-Log -EventId PC_INFO_0024
		Write-Log -Eventid PC_MISC_0001 -extra $cookbook_path

		# Get the username of the person that is creating this cookbook
		$username = $env:username

		# build up an array of the paths that need to be creaated
		$locations = @("attributes"
					"recipes"
					"definitions"
					"libraries"
					"resources"
					"providers"
					"files\default\POSHChef\{0}\files\default\tests" -f $id
					"files\default\POSHChef\{0}\templates\default" -f $id
					"files\default\POSHChef\{0}\attributes" -f $id
					"files\default\POSHChef\{0}\resources" -f $id
					"files\default\POSHChef\{0}\recipes" -f $id
					"templates\default")

		# iterate around the paths and create the directories
		foreach ($location in $locations) {

			# build up the path to create
			$p = "{0}\{1}" -f $cookbook_path, $location

			# Check the path does not exist and only create it if it does not not
			if (!(Test-Path -Path $p)) {
				New-Item -type directory -Path $p | Out-Null
			}
		}

		# Create files in the structure that are useful and compulsory
		# Build up an array of the files
		$files = @("recipes\default.rb"
					"files\default\POSHChef\{0}\attributes\default.psd1" -f $id
					"files\default\POSHChef\{0}\recipes\default.ps1" -f $id
					"CHANGELOG.md"
					"README.md"
					"files\default\POSHChef\{0}\metadata.psd1" -f $id)

		# Iterate around the files that need to be created
		foreach ($file in $files) {

			# Build up the full path to the file
			$file = "{0}\{1}" -f $cookbook_path, $file

			# Work out the path to the skeleton file
			$skeleton_file = "{0}\skeleton\cookbook\{1}" -f ($script:session.config.paths.module), (Split-Path -Leaf $file)

			# If the file does not exist then create it using the skeleton file
			if (!(Test-Path -Path $file) -and (Test-Path -Path $skeleton_file)) {

				# get the contents of the skeleton file
				$contents = Get-Content -Path $skeleton_file -raw

				# Write out evaluated contents to the required file
				$cookbook_name = $id
				Set-Content -Path $file -Value ($ExecutionContext.InvokeCommand.ExpandString($contents))
			}
		}
	}
}
