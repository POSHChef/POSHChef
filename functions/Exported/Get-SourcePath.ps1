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


function Get-SourcePath {

	<#

	.SYNOPSIS
		Cmdlet to assist resources in finding source files in the cache

	.DESCRIPTION
		This is a helper cmdlet to assist in finding files within cookbooks in the cache directory
		There a few resources that need this functionaility, so it has been taken out of the individual resource files
		and put as an exported function in POSHChef

		If a relative path is passed to the cmdlet it will be appended to the end of the CacheDir path, which is derived
		If the source is absolute it will be returned as is

		The return value of this cmdlet is either the path to the file or false if the file does not exist

	#>

	[CmdletBinding()]
	param (

		[Parameter(Mandatory=$true)]
		[string]
		# Path to the source file
		$Source,

		[Parameter(Mandatory=$true)]
		[string]
		# The cookbook that contains the file to be copied
		$Cookbook,

		[string]
		# CacheDir to find the files
		$cachedir = [String]::Empty,

		[Parameter(Mandatory=$true)]
		[string]
		# The type of file being sought, e.g. template or file
		$type,

		[string]
		# Set the basedir for where POSHChef should store configuration files, keys
		# logs, cache and generated mof file
		$basedir = "C:\POSHChef",

		[string]
		# Path to the configuration file to use
		# If left blank the default 'knife.psd1' will be used
		$config = [String]::Empty
	)

	# Patch the $PSBoundParameters to contain the default values
	# if they have not been explicitly set
	foreach ($param in @("basedir")) {
		if (!$PSBoundParameters.ContainsKey($param)) {
			$PSBoundParameters.$param = (Get-Variable -Name $param).Value
		}
	}

	# Initialize the sesion and configure global variables
	# Pass the module information so that it can be added to the session configuration
	Update-Session -Parameters $PSBoundParameters

	# Read the configuration file
	Get-Configuration -config $config

	# If the cachedir is empty then use the one in the configuration
	if ([String]::IsNullOrEmpty($cachedir)) {
		$cachedir = $script:session.config.paths.file_cache_path
	}

	# Determine if the $source is absolute or not
	if ((Split-Path -IsAbsolute -Path $Source) -eq $true) {
		$path = $Source
	} else {

		# The source is absolute so build it up using the cache path and the name of the cookbook
		$path = "{0}\cookbooks\{1}\{2}s\default\{3}" -f $cachedir, $Cookbook, $type, $source
	}

	Write-Verbose $path

	# Check to see if the path exists
	if (Test-Path -Path $path) {
		$return = $path
	} else {
		$return = $false
	}

	# Return the return value to the calling function
	$return

}
