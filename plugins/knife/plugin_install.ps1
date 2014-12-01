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


function plugin_install {

	<#

	.SYNOPSIS
		Installs a custom plugin from a specified source

	.DESCRIPTION
		Although there are a few standard knife plugins for POSHChef, there is a plugin architecture that allows
		people to create custom plugins to perform different tasks.

		One such use case is to synchronise the environments on the Chef server with another repository, such as 
		a filesystem.  This plugin could be called 'environments_sync.ps1' and would be stored in the 
		<BASEDIR>\plugins\knife

		This would then be available to POSHKnife as a useable item, e.g.

			POSHKnife environment sync -path <PATH_TO_ENVIRONMENTS>

		The 'plugin install' takes a location argument that will be analysed to determine what sort of end point it is,
		e.g. local disk, share, HTTP etc

	.EXAMPLE

		POSHKnife plugin install -name environment_sync -location \\fileserver\chef\plugins

		This will attempt to copy the named plugin from the specified location to the local machine


	#>

	param (
		
		[string[]]
		# String array of plugins to attempt to install from the specified location
		$name,

		[string]
		# Location to get the specified plugins from
		$location
	)

	Write-Log " "
	Write-Log -EVentId PC_INFO_0031 -extra ("Installing", "Plugins")

	# Determine the full path to the knife plugins
	$plugins_dir = [System.IO.Path]::Combine($basedir, "plugins\knife")

	# check that the plugins dir exists
	if (!(Test-Path -Path $plugins_dir)) {
		New-Item -type directory -Path $plugins_dir | Out-Null
	}

	# Analyse the location that has been specified by turning it into a uri
	$location_uri = $location -as [System.URI]

	# iterate around the names that have been passed
	foreach ($plugin in $name) {

		Write-Log -EventId PC_MISC_0000 -extra $plugin

		# check to see if the plugin has an extension
		if ([String]::IsNullOrEmpty([System.IO.Path]::GetExtension($plugin))) {

			# it does not so append ps1 to it
			$plugin = "{0}.ps1" -f $plugin
		}

		# perform the copy from the concatenated location by using the appropriate method as described by the scheme in the uri
		switch ($location_uri.scheme) {

			# local or shared file
			"file" {

				# build up the full path to the file
				$fullpath = [System.IO.Path]::Combine($location, $plugin)

				# check that the file exists, if it does copy to the base location
				if (Test-Path -Path $fullpath) {

					Write-Log -EventId PC_INFO_0046

					# copy the plugin
					Copy-Item -Path $fullpath -Destination $plugins_dir -Force

				} else {
					Write-Log -ErrorLevel -EventId PC_ERROR_0019 -extra $fullpath
				}

			}

			# set a default message that will be called if the scheme is not understood
			# and break out of the foreach loop as none of the plugins will be found
			default {
				Write-Log -ErrorLevel -EventId PC_ERROR_0020 -extra $location_uri.scheme -stop
			}
		}

	}
}
