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


function databag_item {

	<#

	.SYNOPSIS
		Creates one or more databag items in the named databag

	.DESCRIPTION
		Once a databag has been created it needs to be populated with items of information
		This function does this work.

		If the specified path is a directory it will attempt to upload all json files in that dir, however
		if it is just one file then that one will be updated

		To delete items requires the use of the delete switch and a list of items to remove
	#>

	[CmdLetBinding()]
	param (

		[String]
		# name of the databag being updated
		$name,

		[String[]]
		# String array of items to add to the databag
		$items,

		[string]
		# Path to the databag items
		$path
	)

	# Setup the mandatory parameters
	$mandatory = @{
		name = "String array of databags to upload to Chef server (-name)"
	}

	Confirm-Parameters -Parameters $PSBoundParameters -mandatory $mandatory

	Write-Log -Message " "
	Write-Log -EVentId PC_INFO_0031 -extra ("Updating Databag -", $name)

	# Check that the named databag exists
	$items_on_server = Get-DataBag

	if ($items_on_server.keys -notcontains $name) {
		Write-Log -EventId PC_ERROR_0026 -Error -Stop -Extra $name
	}

	# Set the path to the chef_repo respoitory if it is null
	if ([String]::IsNullOrEmpty($path)) {
		$path = "{0}\databags\{1}" -f $script:session.config.chef_repo, $name
	}

	# Get a list of the items in the databag
	$dbitems = Get-DatabagItem -name $name

	# If the items is empty then do a lookup in the path for the items
	if ($items.count -eq 0) {
		$items = Get-ChildItem -Path $path -filter "*.json" | Foreach-Object { $_.name }
	}

	# iterate around the items that have been specified
	foreach ($item in $items) {

		$file = $item
		if (!$file.EndsWith(".json")) {
			$file = "{0}.json" -f $file
		}

		# determine the path to the chef-repo item
		$item_path = Join-Path $path $file

		# Check that the item exists
		if (!(Test-Path -Path $item_path)) {
			Write-Log -EventId PC_ERROR_0025 -Extra $item_path -LogLevel Error
		}

		# read in the dbitem from disk
		$dbi = Get-Content -path $item_path -Raw | ConvertFrom-JSONToHashtable

		# reset the argument hashtable
		$splat = @{
			data = $dbi
		}

		# Determine if the item already exists on the server, this is used to set
		# the method that is used.  E.g. PUT for update and POST for new item
		if ($dbitems.containskey(($item -replace ".json", ""))) {
			$splat.method = "PUT"
			$splat.uri = "/data/{0}/{1}" -f $name, $dbi.id
			Write-Log -EventId PC_MISC_0000 -Extra ("Updated {0}" -f $dbi.id)
		} else {
			$splat.method = "POST"
			$splat.uri = "/data/{0}" -f $name
			Write-Log -EventId PC_MISC_0000 -Extra ("Created {0}" -f $item)
		}

		# Attempt to upload the item on the server
		$result = Invoke-ChefQuery @splat

	}

}
