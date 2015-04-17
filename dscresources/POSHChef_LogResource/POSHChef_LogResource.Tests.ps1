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

<#

    .SYNOPSIS
        Pester tests file to test the Log Resource for DSC

    .DESCRIPTION
        This resource utilitises the Write-Log function from the Logging module
        This allows logs to be sent to different targets using the providers object

        The test itself will use a mocked version of the Write-Log function to make sure that it would be used

		It is therefore not possible to ensure that different providers work properly

#>

# Source the necessary files
$TestsPath = $MyInvocation.MyCommand.Path
$script = (Split-Path -Leaf $TestsPath).Replace(".Tests.ps1", ".psm1")
$module = "{0}\{1}" -f (Split-Path -Parent -Path $TestsPath), $script
$code = Get-Content $module | Out-String
Invoke-Expression $code

# Mock functions that come from other modules
function Write-Log(){}
function Update-Session(){}
function Get-Configuration(){}
function Set-LogParameters(){}

# Ensure required functions are available
. "$PSScriptRoot\..\..\functions\exported\ConvertFrom-JsonToHashtable.ps1"
. "$PSScriptRoot\..\..\functions\configuration\Update-Session.ps1"
. "$PSScriptRoot\..\..\functions\exported\Set-Notification.ps1"

Describe "POSHChef_LogResource" {

    # Mock write log so that the message is reported back as it is
    Mock -CommandName Write-Log -Verifiable -MockWith {
        param (
            [string]
            $message,

			[switch]
			$IfDebug
        )

		if (!$IfDebug) {
			return $message
		}
    }

    # Define the message to be output
    $message = "Hello World!"

	# Set the psdrive
	$PSDriveName = "TestDrive"
	$PSDrive = Get-PSDrive $PSDriveName

	# set the name of the service to notify
	$service_name = "MyAppWithOutput"

	# Set the notificationsservicepath file
	$services_notifications_file = "{0}\service.txt" -f $PSDrive.Root

    it "a message will always be written out" {
        Test-TargetResource -Message $message | Should be $false
    }

    it "in the test the same message will be returned" {

        $result = Set-TargetResource -Message $message -Notifies $service_name -NotifiesServicePath $services_notifications_file

        $message -eq $result | Should be $true
    }

	it "will restart the service after a message has been output" {

		# Get the contents of the notifications file
		$services = (Get-Content -Path $services_notifications_file -Raw).Trim()

		$service_name -eq $services | Should be $true

		Remove-Item $services_notifications_file -Force
	}

	it "but the machine will not reboot" {

		$global:DSCMachineStatus -eq 0 | should be $true
	}

	it "will reboot the machine if necessary" {

		$result = Set-TargetResource -Message $message -Reboot $true

		$global:DSCMachineStatus -eq 1 | should be $true

		$global:DSCMachineStatus = 0
	}

    it "invokes Write-Log" {
        Assert-VerifiableMocks
    }
}
