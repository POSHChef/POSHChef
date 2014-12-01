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


function Invoke-AnalysePlatform {
	
	<#

	.SYNOPSIS
	Function to analyse the platform on which POSHChef is running

	.DESCRIPTION
	When POSHChef runs there are some automatic attributes that should be collected such as the
	network interfaces and the uptime.  It will source all the files from a plugin directory and execute
	the script contains therein.  These will be added to the node attributes

	#>

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	if ($host.Name -ine "ServerRemoteHost") {
		Write-Log " "
	}

    # define node_attribute hash
    $node_attributes = @{
							client = @{
								name = ($script:session.config.module_info.name)
								version = ($script:session.config.module_info.version.tostring())
							}
						}

	# get all the standard plugins from the module
	$plugins = @(Get-ChildItem -Recurse -Path ("{0}\plugins\attributes" -f $script:session.config.paths.module) -Include *.ps1)

	# add to this any plugins that have been specified in the POSHChef plugin path
	$user_plugins = Get-ChildItem -Recurse -Path ($script:session.config.paths.chef_plugins) -Include *.ps1
	if ($user_plugins.count -gt 0) {
		$plugins += $user_plugins
	}
	

	# If any plugin scripts have been found execute them to build up the attributes
	if ($plugins.count -gt 0) {

		Write-Log -EventId PC_INFO_0014

		# Iterate around the plugins that have been found
		foreach ($plugin in $plugins) {

			# Output the name of the plugin
			Write-Log -EVentId PC_MISC_0001 -extra $plugin.Name #-Message ("`t{0}" -f $plugin.name) -fgcolour yellow

			# Get the contents of the script and execute it
			$plugin_script = Get-Content -Path ($plugin.fullname) -Raw

			# need to be able to splat in the attributes from the node
			# however this will not be the same as those as expected by the script
			# it might be possible to use an alias, but this does not appear to show up in the Parameters of the script when 'GCM' is used

			# Execute the script
			$plugin_attributes = "$plugin_script" | Invoke-Expression

            # Combine this with the node_attributes
			# Put the new haash table first because if there are any duplicate keys this needs to take
			# precedence
			$node_attributes = Merge-HashTables -primary $plugin_attributes -secondary $node_attributes

		}
	}

    $node_attributes

}

