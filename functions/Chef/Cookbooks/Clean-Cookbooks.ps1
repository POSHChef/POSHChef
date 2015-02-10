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


function Clean-Cookbooks {

	<#

	.SYNOPSIS
		Ensure that only the cookbooks that are required for the runlist exist locally

	.DESCRIPTION
		Each time POSHChef runs it checks to see if the specified cookbooks are downloaded
		This function ensures that only this cookbooks specified in the node's runlist exist locally.  It will
		delete other cookbooks that may remain because it was removed from the runlist

		This needs to be updated so that the cookbooks that do remain are cleaned so that only the files
		for the latest version are found locally
	#>

	[CmdletBinding()]
	param (

		[hashtable]
		# Hashtable of cookbooks and their files
		$files = @{}
	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	Write-Log -Message " "
	Write-Log -EventId PC_INFO_0053 

	# Get a list of the cookbooks that exist locally
	$cached_cookbooks_path = "{0}\cookbooks" -f $script:session.config.paths.file_cache_path
	$cached = Get-ChildItem -Path $cached_cookbooks_path | Where-Object { $_.PSIsContainer -eq $true }

	# Get the list of cookbooks that are required for this run
	$required = [array] $script:session.cookbooks.keys

	# Compare the two arrays to determine which items need to be removed from the cache
	$obsolete = Compare-Object -ReferenceObject $required -DifferenceObject $cached | Foreach-Object { $_.InputObject }

	# Iterate around the obsolete cookbooks and remove them
	foreach ($defunct in $obsolete) {

		# Write out information
		Write-Log -EventId PC_INFO_0054 -Extra $defunct

		# Determine if the cookbook has any resources and if so make sure they are removed from the Modules directory
		# Get a list of resources from the cookbook
		$resources_path = "{0}\cookbooks\{1}\resources" -f $script:session.config.paths.file_cache_path, $defunct

		if (Test-Path -Path $resources_path) {

			$resources = Get-ChildItem -Path $resources_path | Where-Object { $_.PSIsContainer -eq $true } 

			# if cookbook contains resources then see if they exist in windows
			if (![String]::IsNullOrEmpty($resources)) {

				foreach ($resource_name in $resources) {

					# build up the path to the resource module in Windows
					$windows_resource = "{0}{1}" -f $script:session.config.paths.dscresources, $resource_name

					# if the path exists remove it
					if (Test-Path -Path $windows_resource) {
				
						Write-Log -EventId PC_INFO_0055 -extra $resource_name

						# The resources directory exists so remove it
						Remove-Item -Path $windows_resource -Force -Recurse -Confirm:$false | Out-Null
					}

				}
			}
		}

		# Finally remove the cookbook from the cache
		$cached_path = "{0}\cookbooks\{1}" -f $script:session.config.paths.file_cache_path, $defunct
		if (Test-Path -Path $cached_path) {
			Remove-Item -Path $cached_path -Force -Recurse -Confirm:$false | Out-Null
		}
	}

	# If there is a files hashtable iterate around it to get the cookbooks and the associated files
	# then compare this with a list of files from the cookbook in the cache
	if ($files.count -gt 0) {

		foreach ($cookbook in $files.keys) {
		
			# Get a list of the files in the cached cookbook directory
			$path = "{0}\cookbooks\{1}" -f $script:session.config.paths.file_cache_path, $cookbook
			$cached_cookbook_files = Get-ChildItem -Path $path -Recurse | Where-Object { $_.PSIsContainer -eq $false } | Foreach-Object { $_.FullName }

			# Compare the files that should be there with the ones that acutally are
			$notrequired = Compare-Object -ReferenceObject $files.$cookbook -DifferenceObject $cached_cookbook_files | Foreach-Object { $_.InputObject }

			# if notrequired has items then delete them
			if ($notrequired.count -gt 0) {

				Write-Log -EventId PC_INFO_0056 -extra $cookbook

				foreach ($file in $notrequired) {
					Write-Log -EventId PC_MISC_0002 -extra $file
					Remove-Item -Path $file -Force -Confirm:$false |  Out-Null
				}
			}

			# Finally remove any empty folders in the cookbook
			Get-ChildItem -Path $path -Recurse | Where { $_.PSIsContainer -and @(Get-ChildItem -LiteralPath $_.FullName -Recurse | Where-Object { !$_.PSIsContainer}).Length -eq 0} | Remove-Item -Recurse -Force | Out-Null
		}
	}
}
