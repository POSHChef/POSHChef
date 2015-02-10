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

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Message
	)

	# Simply return the message that has been sent
	return $message
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Message,

		[System.String]
		$Providers,

		[System.String]
		$Level = "info",

		[System.String[]]
		$Notifies,

		[System.String]
		$NotifiesServicePath,

		[System.Boolean]
		$Reboot
	)

	# If the providers is empty then create a default of using the screen
	if ([String]::IsNulLOrEmpty($Providers)) {
		$Providers = @(
			@{
				logProvider = "screen"
				verbosity = $Level
			}
		) 
	} else {

		# decode the providers from the JSON object
		$Providers = ConvertFrom-JSONtoHashtable -InputObject $Providers
	}

	# Set the log parameters
	Set-LogParameters -targets $Providers

	# Output the specified message
	Write-Log -Message $message

	# Notify any services of this change
	# Set the DSC resource to reboot the machine if set
	if ($Reboot -eq $true) {
		$global:DSCMachineStatus = 1
	} else {
		Set-Notification -Notifies $Notifies -NotifiesServicePath $NotifiesServicePath
	}
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Message,

		[System.String]
		$Providers,

		[System.String]
		$Level,

		[System.String[]]
		$Notifies,

		[System.String]
		$NotifiesServicePath,

		[System.Boolean]
		$Reboot
	)

	# The message always needs to be output, so always return false
	return $false
}


