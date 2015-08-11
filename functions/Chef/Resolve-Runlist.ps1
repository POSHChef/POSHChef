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


function Resolve-Runlist {

	<#

	.SYNOPSIS
	Given a run list from chef, resolve this into a list of recipes

	#>

	[CmdletBinding()]
	param (

		# Run list that needs to be analysed
		$runlist
	)

	# Create an array that will hold the list of items that cannot
	# be located on the server
	$missing = New-Object System.Collections.ArrayList

	# Iterate around the run_list and build up the expanded run_list
	foreach ($item in $runlist) {

		# Match the current item to determine if a role or a recipe
		if ($item -match "(.*)?\[(.*)\]") {

			# get the run list type and the name of the item
			$item_type = $matches[1]
			$item_name = $matches[2]

			switch ($item_type) {
				# if the $item_type is a recipe then add it to the expanded run_list
				"recipe" {

					# add the role to the roles array in the session if it does not already exist
					if (!($script:session.recipes -contains $item)) {
						$script:session.recipes += $item
					}

					# add in default if there is nothing on the list
					# this will also allow the script to collect the cookbook names so they can be downloaded
					$run_item = $item_name -split "::"

					# set the name of the cookbook
					$cookbook = $run_item[0]

					# determine if the cookbook is already pary of the session object, if not add it
					# this is used to determine what is required in the run and therefore what to clean up
					if (!($script:session.cookbooks.contains($cookbook))) {
						$script:session.cookbooks[$cookbook] = "latest"

						# add the cookbook to the resolve queue
						# this is to assist with the downloading of cookbooks and their dependencies
						$script:session.resolve.queue.Enqueue(@{$cookbook = "latest"})
					}

					# using the length of the run_item, determine if the 'default' recipe
					# is intended
					$recipe = "default"
					if ($run_item.length -gt 1) {
						$recipe = $run_item[1]
					}

					# set the run_item to add to the expanded run_list
					$expanded_run_item = "{0}_{1}" -f $cookbook, $recipe

					# only add to the run list if it does not already exist
					if (!($script:session.expanded_runlist -contains $expanded_run_item)) {
						$script:session.expanded_runlist += $expanded_run_item
					}
				}

				# if the $item_type is a role then get the role information as part of another request
				"role" {

					# Add all the roles to the session so that they can be processed
					$script:session.roles += $item

					# Attempt to get the role to check that it exists
					$role = Get-Role -name $item_name

					# if the role is false do not merge
					if ($role -ne $false) {
						
						# Now call this function again with the runlist that has been applied to the role
						Resolve-Runlist -runlist $role.run_list
					} else {
						$missing.Add($item_name) | Out-Null
					}
				}
			}
		}
	}

	# check the missing array to find out if any items cannot be found
	if ($missing.count -gt 0) {
		Write-Log -LogLevel Error -EventId PC_ERROR_0031 -extra $missing -stop
	}
}
