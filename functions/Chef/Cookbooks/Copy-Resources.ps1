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


function Copy-Resources {

	<#

	.SYNOPSIS
	Copy any DSCResources to Windows system for DSC to find

	.DESCRIPTION
	Look in the cache directory can copy any DSC resources from any cookbook to the correct location in Windows
	This is needed so that the Configuration scripts can find resources

	#>

	[CmdletBinding()]
	param (

		[string]
		# path to the dsc resources that need to be copied
		$path = $script:session.config.paths.file_cache_path,

		[string]
		# specify the subfolder to look for in the path
		$subfolder = "resources"
	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	# Get a list of the dsc resources from the path
	# This has to be done twice so that it is possible to pick up many DSC resources from a top level path
	$dscresources = Get-ChildItem -Path $path -Include $subfolder -Recurse | Foreach-Object { Get-ChildItem -Path $_.fullname }

	# Check to see if there are resources to copy
	if ($dscresources.count -gt 0) {

		Write-Log -Message " "
		Write-Log -EventId PC_INFO_0002

		# iterate around the $dscresources
		foreach ($dscresource in $dscresources) {

			# Output information about the resource being copied
			Write-Log -EventId PC_MISC_0001 -extra $dscresource.name

			# Iterate around the files in the current dscresource
			# This is so the system can work out if the destination file is different from the source using checksum
			$dsc_files = Get-ChildItem -Path $dscresource.FullName -Recurse

			foreach ($dsc_file in $dsc_files) {

				# Build up the path to the target location to see if it exists
				$target = "{0}\{1}\{2}" -f $script:session.config.paths.dscresources, $dscresource.name, $dsc_file.FullName.replace($dscresource.fullname, "").trimstart("\")
				
				Write-Log -IfDebug -EventId PC_DEBUG_0025 -extra $target

				# Does the file exist?
				if (!(Test-Path -Path $target)) {
					
					# The file does not exist so set the flag to copy it
					$copy_dsc_file = $true
				
				} else {

					if (Test-Path -Path $target -pathtype container) {

						$copy_dsc_file = $false
					} else {

					
						# The target file does exist so now get the checksum for the source and target files
						$source_checksum = Get-Checksum -Path $dsc_file.fullname
						$target_checksum = Get-Checksum -Path $target

						# Compare the checksums to determine if the file should be copied
						if ($source_checksum -eq $target_checksum) {
							$copy_dsc_file = $false
						} else {
							$copy_dsc_file = $true
						}
					}

				}

				# Copy the resource file if the flag is true
				if ($copy_dsc_file -eq $true) {

					# check that the parent directory for this file exist
					$target_dir = Split-Path -Parent -Path $target
					if (!(Test-Path -Path $target_dir)) {
					
						# path does not exist so create it
						New-Item -type d -Path $target_dir | Out-Null
					}

					Write-Log -EventId PC_INFO_0028 -extra @($dscresource.name, $dsc_file.name)

					# Copy the file
					$cmd = "Copy-Item -Recurse -Path {0} -Destination {1} -Force" -f ($dsc_file.fullname), $target
					Write-Log -IfDebug -Eventid PC_DEBUG_0008 -extra $cmd
					$cmd | Invoke-Expression
				}
			}		
			
		}
	}
}
