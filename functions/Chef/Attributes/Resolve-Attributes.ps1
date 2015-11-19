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


function Resolve-Attributes {

	<#

	.SYNOPSIS
	Loads all of the attribute files from the cache directory

	.DESCRIPTION
	Loads all of the attributes from the attributes folders in the cache directory, it then returns
	a hash table of the merged attributes

	#>

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	Write-Log " "
	Write-Log -EventId PC_INFO_0004

	# create a dsconfig to return to the calling function
	$dsc_config = @{
			AllNodes = @()
		}

	# Get a list of the attribute files
	$attributes = @(Get-ChildItem -Recurse -Path ($script:session.config.paths.file_cache_path) -Include *.psd1 | `
					Where-Object { $_.FullName -match "attributes" })

	# retrieve the node from the server so that any attributes that have been set there are respected
	$chef_node = Get-Node 
	
	# depending on the result set the resolved_attrs or create a new hashtable
	if ($chef_node.containskey("automatic")) {
		$resolved_attrs = $chef_node.automatic
	} else {
		$resolved_attrs = @{}
	}

	# update the resolved_attributes
	$resolved_attrs.NodeName = hostname
	$resolved_attrs.PSDscAllowPlainTextPassword = $true
	
	if (!$resolved_attrs.containskey("POSHChef")) {
		$resolved_attrs.POSHChef = @{}
	}
	
	$resolved_attrs.POSHChef.conf = $script:session.config.paths.conf
	$resolved_attrs.POSHChef.plugins = $script:session.config.paths.plugins
	$resolved_attrs.POSHChef.notifications = $script:session.config.paths.notifications
	$resolved_attrs.POSHChef.cache = $script:session.config.paths.file_cache_path
	$resolved_attrs.POSHChef.handlers_path = $script:session.config.paths.handlers
	
	$resolved_attrs.thisrun = @{
		logdir = $script:session.config.logdir
	}

	# If there are attribute files then load them in
	if ($attributes.count -gt 0) {
		
		Write-Log -IfDebug -EventId PC_DEBUG_0010

		# iterate around the attribute files
		foreach ($attribute_file in $attributes) {

			Write-Log -IfDebug -Message ("`t{0}" -f $attribute_file.fullname)

			# Load in the current attribute file
			$cookbook_attrs = Invoke-Expression (Get-Content -Path ($attribute_file.fullname) -raw)

			# iterate around the default attrs that have been set
			foreach ($attr in $cookbook_attrs.default.keys) {
			
				# if the resolved_attrs contains a hashtable at this $attr and the target is hashtable then perform a merge
				if ($resolved_attrs[$attr] -is [hashtable] -and $cookbook_attrs.default.$attr -is [hashtable]) {

					$resolved_attrs[$attr] = Merge-Hashtables -primary $resolved_attrs[$attr] -secondary $cookbook_attrs.default.$attr
				} else {

					# add the current attr and value to the resolved_attrs
					$resolved_attrs[$attr] = $cookbook_attrs.default.$attr
				}
			}

		}

	} else {
		Write-Log -Message "`tno cookbook attributes found" -fgcolour yellow 
	}

	# Now check to see if there are any role attributes
	if ($script:session.attributes.roles.count -gt 0) {

		# there are so merge those attributes with the ones we already have
		# this needs to be done so that the role values win out
		$resolved_attrs = Merge-Hashtables -primary $script:session.attributes.roles -secondary $resolved_attrs
	}

	# Check to see if there are any environment attributes
	if ($script:session.attributes.environments.count -gt 0) {

		# there are so merge those attributes with the ones we already have
		# this needs to be done so that the environment values win out
		$resolved_attrs = Merge-Hashtables -primary $script:session.attributes.environments -secondary $resolved_attrs

	}

	# add a chef attribute
	if (!$resolved_attrs.containskey("chef")) {
		$resolved_attrs.chef = @{}
	}

	# set the environment so it can be passed to recipes
	$resolved_attrs.chef.chef_environment = $script:session.environment

	# set the path to the configuration file being used by Chef, this so that
	# the system can call the POSHKnife commands to get searches from the chef server
	$resolved_attrs.chef.config_file = $script:session.config.file

	# Add the recipes and roles that have been resolved to the attributes
	$resolved_attrs.roles = $script:session.roles
	$resolved_attrs.recipes = $script:session.recipes

	# Run the platform attribute plugins and merge them with the resolved_attrs
	$resolved_attrs = Merge-HashTables -primary $resolved_attrs -secondary (Invoke-AnalysePlatform)

	# Determine if any attributes have been specified on the command line
	if ($script:session.attributes.cmdline.count -gt 0) {

		# determine the type of the attributes that have been set on the command line
		if ($script:session.attributes.cmdline -is [hashtable]) {

			# It is already a hashtable so set as the primary table to merge
			$primary = $script:session.attributes.cmdline

		}

		# merge in the attributes that have been specified on the command line
		# such attributes will override anything that has been previously set	
		$resolved_attrs = Merge-Hashtables -primary $primary -secondary $resolved_attrs
	}

	# Output the resolved attributes if in Debug mode
	# Write-Log -IfDebug -Message $resolved_attrs -asJson -jsonDepth 8

	# Add the resolved attrs to the dsc_config
	$dsc_config.AllNodes += $resolved_attrs

	# Return the dsc_config to the calling function
	$dsc_config
}
