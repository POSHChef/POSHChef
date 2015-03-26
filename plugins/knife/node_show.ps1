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


function node_show {


	<#

	.SYNOPSIS
	Display the specified node

	.DESCRIPTION
	Display the details of the specified node

	.EXAMPLE

	Invoke-POSHKnife node show -name foo

	Will list out the node called 'foo'

	#>

	[CmdletBinding()]
	param (

		[string]
		# List of names of users to create
		$name,

		[switch]
		# Specify if the node should be saved to a file
		$save,

		[string]
		# Directory that the file should be saved in.
		# This is applicable when the filename is not an absolute path
		# The default for this is the <BASEDIR>\nodes directory
		$folder = [String]::Empty,

		[string]
		# Filename that contents should be saved in
		# By default this will be the name of the node with JSON extension
		$filename = [String]::Empty,

		[string]
		# The format that the file should be written out as
		# By default this is as a PSON object
		$format = "json"


	)

	# Setup the mandatory parameters
	$mandatory = @{
		name = "Name of the node to display or save (-name)"
	}

	Confirm-Parameters -Parameters $PSBoundParameters -mandatory $mandatory

	Write-Log -Message " "
	Write-Log -EVentId PC_INFO_0031 -extra ("Display", "Node")

	# Call the POSHChef function to get the node
	$node = Get-Node -name $name -passthru

	# Depending on whether a file has been specified save the contents to it
	# or output them to the pipeline
	if (!$save) {
		$node
	} else {

		# Build up the argument hashtable to pass to the Save-ChefItem
		$splat = @{
			folder = $folder
			filename = $filename
			format = $format
			InputObject = $node
		}
		Save-ChefItem @splat
	}

}
