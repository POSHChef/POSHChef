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

		If the specified path is a directory it will attempt to upload all json files in that dir, howvere
		if it is just one file then that one will be updated

		To delete items requires the use of the delete switch and a list of items to remove
	#>

	[CmdLetBinding()]
	param (

		[String]
		# name of the databag being updated
		$name,

		[String]
		# Path to the item(s) to be upload
		$path,

		[switch]
		# Specify if items should be removed
		$delete,

		[string[]]
		# String array of items to be removed
		$items
	)

	# Setup the mandatory parameters
	$mandatory = @{
		name = "String array of databags to upload to Chef server (-name)"
	}

	Confirm-Parameters -Parameters $PSBoundParameters -mandatory $mandatory

	Write-Log -Message " "
	Write-Log -EVentId PC_INFO_0031 -extra ("Updating Databag -", (Get-Culture).TextInfo.ToTitleCase($name))

	# Check that the named databag exists
	$items_on_server = Invoke-ChefQuery -Path "/data"

	if ($items_on_server.keys -notcontains $name) {
		Write-Log -EventId PC_ERROR_0026 -Error -Stop -Extra $name
	}

	# check to see if the items are being removed
	if ($delete) {

		# iterate around each of the items to remove
		foreach ($item in $items) {

			# attempt to remove the specified item
			$splat = @{
				method = "DELETE"
				uri = "/data/{0}/{1}" -f $name, $item
			}

			$result = Invoke-ChefQuery @splat

			if ($result.containskey("statuscode")) {
				# there has been an error removing the item so decode the data and output the infromation
				$data = $reponse.data | ConvertFrom-Json
				Write-Log -LogLevel Warn -EventId PC_WARN_0013 -Extra $data.error
			} else {
				Write-Log -EventId PC_MISC_0000 -Extra ("Deleted {0}" -f $item)
			}
		}

	} else {

		# If the path does not exist then come out of the function with an error
		if (!(Test-Path -Path $path)) {
			Write-Log -EventId PC_ERROR_0025 -Extra $path -stop -LogLevel Error
		}

		# get the file items in the path
		$fileitems = Get-ChildItem -Path $path -filter "*.json"

		# iterate around each of the file items and read them in
		foreach ($fileitem in $fileitems) {

			# Read in the contents of the file and convert to a hashtable
			# this is required so the objecvt can be checked to have an id field
			$dbitem = Get-Content -Path $fileitem.fullname -Raw | ConvertFrom-JSONtoHashtable

			if (!($dbitem.containskey("id"))) {
				Write-Log -Warn -EventId PC_WARN_0012 -Extra $fileitem.fullname
				continue
			}

			# create the argument splat for Chef-Query
			# The first test is to attempt to udate the item
			$splat = @{
				method = "PUT"
				uri = ("/data/{0}/{1}" -f $name, $dbitem.id)
				data = (Get-Content -Path $fileitem.fullname -Raw)
			}

			$result = Invoke-ChefQuery @splat

			# this has worked if there is not statucode, howvere if there is one then need to check what it is
			if ($result.containskey("statuscode") -and $result.statuscode -eq 404) {

				# the item does not exist so change the methid to a post and then try again
				$splat.method = "POST"
				$splat.uri = ("/data/{0}" -f $name)
				$result = Invoke-ChefQuery @splat

				Write-Log -EventId PC_MISC_0000 -Extra ("Created {0}" -f $dbitem.id)

			} else {
				Write-Log -EventId PC_MISC_0000 -Extra ("Updated {0}" -f $dbitem.id)
			}
		}
	}
}
