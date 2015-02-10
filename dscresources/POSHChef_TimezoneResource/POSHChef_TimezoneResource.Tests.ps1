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
		Pester tests file to test the Timezone Resource for DSC

	.DESCRIPTION
		The few tests in this resource will test to ensure that an incorrect timezone would be modified

#>

# Source the necessary files
$TestsPath = $MyInvocation.MyCommand.Path
$script = (Split-Path -Leaf $TestsPath).Replace(".Tests.ps1", ".psm1")
$module = "{0}\{1}" -f (Split-Path -Parent -Path $TestsPath), $script
$code = Get-Content $module | Out-String
Invoke-Expression $code

Describe "POSHChef_TemplateResource" {

	# Set the psdrive
	$PSDriveName = "TestDrive"
	$PSDrive = Get-PSDrive $PSDriveName

	# name of the service to restart
	$service_name = "MyTimeApp"

	# Set the notificationsservicepath file
	$services_notifications_file = "{0}\service.txt" -f $PSDrive.Root

	# Get the current timezone of the machine so that a no change can be tested
	$current_timezone = (& tzutil.exe /g).Trim()

	it ("will not change the timezone if it is already correctly set: {0}" -f $current_timezone) {

		Test-TargetResource -timezone $current_timezone | Should be $true
	}

	$new_timezone = "Samoa Standard Time"
	it ("the time zone will be modified if it to be set to a different zone: {0}" -f $new_timezone) {

		Test-TargetResource -timezone $new_timezone | Should be $false
	}

	it ("will notify a service to be restarted if the timezone changes") {

		Set-TargetResource -timezone $new_timezone -notifies @($service_name) -notifiesservicepath $services_notifications_file

		$services = (Get-Content -Path $services_notifications_file -Raw).Trim()

		$service_name -eq $services | Should be $true

		Set-TargetResource -timezone $current_timezone
	}

}
