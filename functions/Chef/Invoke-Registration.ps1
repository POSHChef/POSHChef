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


function Invoke-Registration {

	<#

	.SYNOPSIS
	Attempt to register the node as a new client in chef

	.DESCRIPTION
	Use the Chef Server API to register the node as a new client in Chef
	This will need to use the chef-validator and the key to achieve this

	The return result should be the private RSA key that the node needs to keep

	#>

	[CmdletBinding()]
	param (

		[string]
		# Path to the file where the private key should be stored
		$keypath
	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	# Build up the data string to pass in the request
	$postdata = @{"name" = $script:session.config.client; "admin" = $false} | ConvertTo-Json -Compress

	Write-Log -IfDebug -Extra $postdata -EventId PC_DEBUG_0003

	# Before attempting to register the client, ensure that the validation key exists
	$validation_key_path = "{0}\{1}" -f $script:session.config.paths.conf, $script:session.config.validation_key
	if (!(Test-Path -Path $validation_key_path)) {

		Write-Log -ErrorLevel -EventId PC_ERROR_0007 -extra $validation_key_path -stop
	}

	# Call the Invoke-ChefQuery to perform the registration
	$response = Invoke-ChefQuery -path "/clients" -method "POST" -data $postdata -useritem "validation_name" -keyitem "validation_key"

	# If the response is false output an error message and exit
	if ($response -eq $false) {
		Write-Log -ErrorLevel -EventId PC_ERROR_0004 -stop
	}

	# write the private key out to the specified file
	if (![String]::IsNullOrEmpty($response.private_key)) {
		Set-Content -Path $keypath -Value $response.private_key
	}

	# Call the function to create the node on teh server
	New-Node -name $script:session.config.node -environment $script:session.environment
}
