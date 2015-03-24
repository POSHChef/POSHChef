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


function databag_get {

	<#

	.SYNOPSIS
		Attempts to retrieve the specified items from the named databag

	.DESCRIPTION
		Plugin to retrieve the named items from the databag.  If the results of the plugin
		are not being added to a variable then the number of items found will be
		displayed.

		The system will check that the items exist before trying to display them.  Any
		that do not are alerted as a warning at the end.

	.EXAMPLE

		PS C:\> Invoke-POSHKnife databag get -name acme -item roadrunner

		If the roadrunner item exists in the named databag then this fact will be shown in the
		logtargets

	.EXAMPLE

		PS C:\> $items = @(Invoke-POSHKnife get -name acme -item roadrunner,coyote)

		Returns an array of the items 'roadrunner' and 'coyote' and adds them to the '$items' variable.

	#>

	[CmdletBinding()]
	param (

		[string]
		# Name of databag to list out the items for
		$name,

		[string[]]
		# String array of items to get from the named bag
		$items

	)

	# Setup the mandatory parameters
	$mandatory = @{
		name = "Name of databag to retrieve items from (-name)"
		items = "String array of items to get (-items)"
	}

	Confirm-Parameters -Parameters $PSBoundParameters -mandatory $mandatory

	Write-Log -Message " "
	Write-Log -EVentId PC_INFO_0031 -extra ("Getting", "Databags")

	# set array to hold list of items that do not exist
	$unknown = New-Object System.Collections.ArrayList

	# craete hashtable to add the items to
	$databag_items = New-Object System.Collections.ArrayList

	Write-Log -EventId PC_MISC_0000 -extra $name

	# Get the named databag
	$databag = Get-Databag -name $name

	# iterate around the items that have been requested
	foreach ($item in $items) {

		# check that the item exists in the databag
		if (!$databag.containskey($item)) {

			# if it does not then add to the unknown array
			$unknown.Add($item) | Out-Null

			continue
		}

		# Call the databag item function to get the item
		$dbitem = Get-DatabagItem -name $name -item $item

		# add the item to the arraylost
		$databag_items.Add($dbitem) | Out-Null
	}

	# Determine if the results are expected to be returned
	if ($script:session.knife.return_results -eq $true) {
		$databag_items
	} else {
		Write-Log -EventId PC_MISC_0001 -Extra ("{0} items found" -f $databag_items.count)
	}

	# Check to see if there are any unknown items specified
	if ($unknown.count -gt 0) {
		Write-Log -EventId PC_WARN_0019 -LogLevel Warn -Extra $unknown
	}

}
