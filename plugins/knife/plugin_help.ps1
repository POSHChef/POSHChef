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


function plugin_help {

	<#

	.SYNOPSIS

		Displays the help for a specified plugin

	.DESCRIPTION

		Although the plugins are simple powershell scripts they are consumed by the main Invoke-POSHKnife
		cmdlet.  This means that it is more difficult to display the help from a script

		This plugin displays the help for the named plugin.

		When a plugin is installed or listed its name will be based on a file name.  Thus the plugin associated
		with the command 'POSHKnife node delete' is called 'node_delete'.  When help is requested about a
		plugin the name of the plugin should be used.

	.EXAMPLE

		POSHChef plugin help -name node_delete

		Will display the help that is associated with the node_delete plugin

	.EXAMPLE

		POSHChef plugin help -name node_delete -examples

		Show any examples that have been added to the help in the plugin

	#>

	param (

		[string]
		# Name of the plugin to display help about
		$name,

		[switch]
		# State whether examples should be displayed when showing the help
		$examples

	)

	Write-Log " "
	Write-Log -EVentId PC_INFO_0031 -extra ("Plugin Help -", $name)

	# if the name does not have an extension then set it now, to ps1
	if ([String]::IsNullOrEmpty([System.IO.Path]::GetExtension($name))) {
		$name = "{0}.ps1" -f $name
	}

	# get the name of the function
	$function = [System.IO.Path]::GetFileNameWithoutExtension($name)

	# Build up a an array containing the paths to look for the plugin in
	$search_folders = @($script:session.config.paths.knife_plugins,
						[System.IO.Path]::Combine($script:session.module.path, "plugins\knife"))

	# set flag to denote if the plugin has been found
	$found = $false

	# iterate around the folders and determine if the plugin can be found
	foreach ($search_folder in $search_folders) {

		# build up a path to test for
		$plugin = [System.IO.Path]::Combine($search_folder, $name)

		# test to make sure the path exists
		if (Test-Path -Path $plugin) {

			# source the function so that help can be retrieve
			. $plugin

			# the plugin exists so get-help
			Get-Help $function -examples:$examples

			# remove the function from the current scope
			Remove-Item function:\$function

			# set the flag
			$found = $true

			# break out of the loop as the plugin has been found
			break
		}
	}

	# if the plugin was not found then display error
	if (!$found) {
		Write-Log -ErrorLevel -EventId PC_ERROR_0021 -extra $function
	}
}
