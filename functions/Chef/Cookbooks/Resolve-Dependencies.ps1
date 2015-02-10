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


function Resolve-Dependencies {

	<#

	.SYNOPSIS
		Ensures that any cookbook depdencies are downloaded

	.DESCRIPTION
		Any cookbook can have a list of dependent cookbooks. This function ensures that they are all downloaded

	#>

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	# Find all the metadata.psd1 files in the cookbooks cache directory
	$path = "{0}\cookbooks" -f $script:session.config.paths.file_cache_path
	$metadata_files = Get-ChildItem -Path $path -Recurse -Include "metadata.psd1" | Foreach-Object { $_.Fullname }

	# Iterate around each of the metadata files and read each one in
	foreach ($metadata_file in $metadata_files) {

		# The metadata file is a hashtable to get the contents and read in as such
		$metadata = Invoke-Expression (Get-Content -Path $metadata_file -Raw)

		# if the metadata has any dependencies ensure that they are part of the cookbook list
		if ($metadata.containskey("depends") -and $metadata.depends.count -gt 0) {

			# iterate around the keys and check that the cookbook is part of the set to be downloaded
			foreach ($name in $metadata.depends.keys) {

				# if the cookbooks to be downloaded do not contain this cookbook then add to the list
				if (!$script:session.cookbooks.containskey($name)) {

					# if the version of the depends cookbook is null then set it to latest
					if ([String]::IsNullOrEmpty($metadata.depends.$name)) {
						$version = "latest"
					} else {
						$version = $metadata.depends.$name
					}

					$script:session.cookbooks[$name] = $version

					# if the cookbook is not part of the 'done' list then add it to the queue to be downloaded, or at least checked
					if ($script:session.resolve.done -notcontains $name) {
						$script:session.resolve.queue.Enqueue(@{$name = $version})
					}
				}
			}

		}
	}
	 
}
