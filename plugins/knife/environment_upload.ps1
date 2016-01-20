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


function environment_upload {


	<#

	.SYNOPSIS
		Upload an environment object to the chef server

	.DESCRiPTION
		Environments are created by writing JSON files with the required options.
		These files then need to be uploaded to the chef server in order for them to be
		accessible and useable.

		During upload the Chef server will check to ensure that the content of the environment
		is valid.  If not then an error message regarding the fault will be presented.

		The function will check that the environment file is valid JSON before an upload
		is attempted.

		Like cookbooks and roles it is possible to specify the name of the environment
		file to upload and the system will assume this is part of the chef_repo that has been
		specifed in the POSHKnife configuration file

  .EXAMPLE

		PS C:\> Invoke-POSHKnife environment upload -name Base,POSHChef

		This will attempt to upload the environment files that are part of the <chef_repo>/environment
		folder.  It will append the .json file extension so the end of the specified files

	.EXAMPLE

		PS C:\> Invoke-POSHKnife environment upload -path "c:\temp\roles\base.json"

		This will attempt to upload the environment contained within the 'base.json' file
	#>

	[CmdletBinding(DefaultParameterSetName="simple")]
	param (

		[Parameter(ParameterSetName="complex")]
		# An environment object
		$InputObject,

		[Parameter(ParameterSetName="simple")]
		[string[]]
		# Array of names of the environments to be uploaded
		# these will assumed to be a the 'roles' subfolder of the chef_repo setting
		$names

	)

	# Setup the mandatory parameters, based on the parameter set name
	switch ($PSCmdlet.ParameterSetName) {
		"simple" {
			$mandatory = @{
				names = "String array of environments to upload (-name)"
			}
		}
		"complex" {
			$mandatory = @{
				inputobject = "Hashtable describing the environment to upload (-InputObject)"
			}
		}
	}

	Confirm-Parameters -Parameters $PSBoundParameters -mandatory $mandatory

	# Determine the name of the chef type from the function name
	$chef_type, $action = $MyInvocation.MyCommand -split "_"

	# determine the mapping for the chef query
	$mapping = "{0}s" -f $chef_type

	Write-Log -Message " "
	Write-Log -EVentId PC_INFO_0031 -extra ("Uploading", (Get-Culture).TextInfo.ToTitleCase($mapping))

	# Get a list of the roles currently on the server
	$list = Get-Environment

	# iterate around the names that have been supplied
	switch ($PSCmdlet.ParameterSetName) {

		"simple" {
			foreach ($name in $names) {

				# build up the hashtable to pass to the Uplaod-ChefItem function
				$splat = @{
					name = $name
					list = $list.keys
					chef_type = $chef_type
				}

				Upload-ChefItem @splat
			}
		}

		"complex" {
			$splat = @{
				InputObject = $InputObject
				list = $list.keys
			}

			Upload-ChefItem @splat
		}
	}

}
