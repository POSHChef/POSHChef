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

function Invoke-Knife {
<#

	.SYNOPSIS
	Powershell based knife tool for Chef

	.DESCRIPTION
	Script that tries to mimic the functionality of the native chef package in PowerShell

#>

[CmdletBinding()]
param (

	[string]
	[Parameter(Mandatory=$True,Position=1)]
	# Type of chef object that is being managed
	$chef_type,

	[string]
	[Parameter(Mandatory=$True,Position=2)]
	# What is going to be done to the chef object
	$mode,

	[string]
	[Parameter(Position=3)]
	# The data that needs to be supplied to the object, e.g. the node to look for
	$data,

	[String[]]
	# Array of options that can be passed to the client
	$options = @("ruby")

)

# Set the error action preference
$ErrorActionPreference = "Stop"

$global:basedir = $PSScriptRoot

# Load in libraries that are required
#Add-Type -Path $("{0}\packages\chilkat-x64.9.4.1.42\lib\net40\ChilkatDotNet4.dll" -f $PSScriptRoot)

# Initalise libraries
#$RSA = New-Object Chilkat.Rsa
#$RSA.UnlockComponent("Trial") | Out-Null

# Build up the path to the functions folder so that the functions can be sourced
#$functions_path = "{0}\functions" -f $PSScriptRoot

# Force the import of the Write-Log function so that if can be used to report problems if they 
# exist during the function import
#. $("{0}\Logging\Write-Log.ps1" -f $functions_path)

# Load in all the function files, apart from the ones that have already been loaded
#$function_files = Get-ChildItem -Recurse -Path $functions_path -Include "*.ps1" | Where-Object { $_.FullName -notmatch "Logging" }

#if ($function_files) {
#	foreach ($function_file in $function_files) {
		
		# Source the function file
#		. $function_file.FullName

#		Write-Log -IfDebug -Message "Loading" -Extra $function_file.FullName
#	}
#}

# Define the chef configuration to connect to the server with
$chef_config = @{
	server	=	"https://asnav-lnx-01.navisite.com"
	client	=	"russells"
	key		=	"c:\users\russellseymour\.chef\asos\russells.pem"
	version =	"11.8.0"
}


# Build up the basic headers to access the Chef server
$headers = @{
	'X-Chef-Version' = '{0}' -f $chef_config.version
}

# Set some default values
$RESTMethod = "GET"
$body_data = ""

# Configure the parameters for the request based on what is being asked for
switch ($chef_type) {
	"node" {
		switch ($mode) {
			"list" {
				$path = "/nodes"
			}

			"show" {
				$path = "/nodes/{0}" -f $data
			}
		}
	}

	"role" {
		switch ($mode) {
			"list" {
				$path = "/roles"
			}

			"show" {
				$path = "/roles/{0}" -f $data
			}
		}
	}
	
	"environment" {
		switch ($mode) {
			"list" {
				$path = "/environments"
			}

			"show" {
				$path = "/environments/{0}" -f $data
			}
		}
	}	
}

# Build up the $endpoint that needs to be access in the request
$endpoint = "{0}{1}" -f $chef_config.server, $path

Write-Host "Endpoint: $endpoint`n"

# Sign the request
$headers = Get-Signature -path $path -method $RESTMethod -data $body_data -headers $headers

# Now execute the request
$return = Invoke-ChefRESTMethod -uri $endpoint -headers $headers -Accept 'application/json'

$return | ConvertFrom-Json
}
