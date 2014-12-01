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


function Get-Cookbooks {

	<#

	.SYNOPSIS
	Download the cookbooks as specified in the session object

	.DESCRIPTION
	As a chef run progresses it builds up a list of the cookbooks that are required to complete
	the configuration.  This function determines if:

		1.  The specified cookbook exists on the server
		2.  The required version exists on the server
		3.  If 1 & 2 are satisfied determine if the cookbook exists locally
		4.  If it does then get the checksum and compare with local copy
		5.  If new or 4 is false then download the cookbook

	#>

	[CmdletBinding()]
	param (

		[hashtable]
		# Hashtable of cookbooks to download with the version
		$cookbooks =  @{}
	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	# Determine if configured to download files, return to the calling function if not
	if (!$script:session.config.download) {
		Write-Log -WarnLevel -EventId PC_WARN_0004
		return
	}

	Write-Log -message " "
	Write-Log -EventId PC_INFO_0001

	# if no cookbooks have been specified then set them from the session
	if ($cookbooks.count -eq 0) {
		$cookbooks = $script:session.cookbooks		
	}

	# define varuiable to hold the missing cookbooks on the server
	$missing_cookbooks = @()

	# Retrieve a list of the cookbooks on the chef server
	$server_cookbooks = Invoke-ChefQuery -path "/cookbooks"

	# Create hashtable that will be used to store the files that should exist in a cookbook
	$cookbook_files = @{}
	
	# Iterate around the cookbooks that have been specified and check whether they exist on the server
	foreach ($cookbook in $cookbooks.keys) {

		# compare the name of the current cookbook with that retrived from the server
		#$exists = $server_cookbook_names | Where-Object { $_.Name -eq $cookbook }

		# check the value of $exists
		#if ([String]::IsNullOrEmpty($exists)) {
		if (!$server_cookbooks.containskey($cookbook)) {
			$missing_cookbooks += $cookbook
		}

	}

	# check the missing cookbooks
	# if any have been specified then throw an error
	if ($missing_cookbooks.count -gt 0) {

		Write-Log -ErrorLevel -EventId PC_ERROR_0002 -stop -extra ($missing_cookbooks -join ", ")
	}

	# Download the cookbooks that are in the queue
	do {

		# get the cookbook information from the queue
		$cookbooks = $script:session.resolve.queue.Dequeue()
		
		# Iterate around the cookbooks that have been specified
		foreach ($cookbook in $cookbooks.keys) {
	
			# Output information about the cookbook being retrieved
			Write-Log -EventId PC_MISC_0001 -extra $cookbook

			# Build up the path on the chef server
			$path = "/cookbooks/{0}/{1}" -f $cookbook, $cookbooks.$cookbook

			# Execute the query on the server
			$detail = Invoke-ChefQuery -path $path
		
			# ensure the cookbook exists in the cookbooks
			$cookbook_files.$cookbook = @()

			# Iterate around the files section of the detail
			foreach ($file in $detail.files) {
			
				# Reset variables
				$download_file = $false
			
				# determine the path to which the file should be downloaded to
				# get the full URI and ensure the forward slashes are replaced
				$corrected_path = $file.path -replace "/", "\"

				# reduce the path down to the attributes, reipces etc folders
				$replace = "files\\default\\POSHChef\\{0}\\" -f $cookbook
				$reduced_path = $corrected_path -replace $replace, ""

				# now we have the reduce path, build up the full download path
				$target = "{0}\cookbooks\{1}\{2}" -f $script:session.config.paths.file_cache_path, $cookbook, $reduced_path

				#Write-Host $target

				# build up the path for the file
				#Write-Host $file.path
				#$path = "{0}\cookbooks\{1}\{2}" -f $script:session.config.paths.file_cache_path, $cookbook, ($file.path -replace "/", "\")
				$path = $target

				# check to see if the parent path needs creating
				$parent = Split-Path -Parent $path
				if (!(Test-Path -Path $parent)) {
					Write-Log -IfDebug -Message "Creating directory" -extra $parent
					New-Item -Type d -Path $parent | Out-Null
				}

				# Add the path to the cookbooks
				$cookbook_files.$cookbook += $path

				# Determine if the file needs to be downloaded
				# There are two scenarios for this
				# 1. the files does not exist locally
				# 2. it is different from the file on the server
				if (!(Test-Path -Path $path)) {
					$download_file = $true
				} else {

					# Get the checksum of the file
					$checksum = Get-Checksum -Path $path -nobase64

					# Compare the checksums, if they are different download the file
					if ($checksum -ne $file.checksum) {
						$download_file = $true
					}
				}

				# Only get the file if download is true
				if ($download_file -eq $true) {

					Write-Log -EventId PC_MISC_0002 -extra $file.path 

					# Now perform another GET on the chef server to get the contents of the file
					$content = Invoke-ChefQuery -Path $file.url -Raw

					# Write the cotent to the cache file on disk
					# However do not use the 'Set-Content' function as this adds an extra CR to the end of the file
					# which means the checksum check is incorrect
					[System.IO.File]::WriteAllText($path, $content) 

				}

			}

			# now add this cookbook to the list of cookbooks that have been checked
			$script:session.resolve.done += $cookbook
		}

		# Call the Resolve-Dependencies function which will interrogate the depends item in the metadata of each
		# cookbook and ensure that any that have not be downloaded are
		Resolve-Dependencies

	} until ($script:session.resolve.queue.Count -eq 0)

	# Ensure that any locally cached cookbooks that are not in the runlist are removed
	Clean-Cookbooks -files $cookbook_files

	# Copy any DSC resource files to the correct location
	Copy-Resources
}
