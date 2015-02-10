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
        Pester tests file to test the Registry resource for DSC

    .DESCRIPTION
        This test suit will add and remove items from the local registry
		It will also test to ensure that services can be notified and that the machine can be reboots

#>

# Source the necessary files
$TestsPath = $MyInvocation.MyCommand.Path
$script = (Split-Path -Leaf $TestsPath).Replace(".Tests.ps1", ".psm1")
$module = "{0}\{1}" -f (Split-Path -Parent -Path $TestsPath), $script
$code = Get-Content $module | Out-String
Invoke-Expression $code

# Mock functions that come from other modules
function Write-Log(){}

Describe "POSHChef_RegistryResource" {

	# Set the psdrive
	$PSDriveName = "TestDrive"
	$PSDrive = Get-PSDrive $PSDriveName

	# name of the service to restart
	$service_name = "MyRegistryApp"

	# Set the notificationsservicepath file
	$services_notifications_file = "{0}\service.txt" -f $PSDrive.Root

	# Create a hashtable for the arguments
	$splat = @{
		key = "HKEY_LOCAL_MACHINE\SOFTWARE\PesterTests"
		ensure = "Present"
		valuename = "TestValue"
		valuedata = "TestData"
		reboot = $false
		notifies = @($service_name)
		notifiesservicepath = $services_notifications_file
	}

	it "will test that a key needs to be added if it does not exist" {

		# Call the test-target resource to check the result is false
		$result = Test-TargetResource @splat

		$result | should be $false
	}

	it "will perform the creation" {

		Set-TargetResource @splat

		# get the item property from the registry
		$result = Get-ItemProperty -Path "hklm:software\pestertests"

		$result.$($splat.valuename) -eq $splat.valuedata | should be $true

	}

	it ("notifies the service for a restart: {0}" -f $service_name) {

		# Get the contents of the notifications file
		$services = (Get-Content -Path $services_notifications_file -Raw).Trim()

		$service_name -eq $services | Should be $true

		Remove-Item $services_notifications_file -Force
	}

	it ("will not make a change if the information is the same") {

		$result = Test-TargetResource @splat

		$result | should be $true
	}

	it ("will make a change if the key value is modified") {

		$splat.valuedata = "Modified to something else"

		$result = Test-TargetResource @splat

		$result | should be $false
	}

	it ("will request a reboot if the value has changed") {

		$splat.reboot = $true

		Set-TargetResource @splat

		$global:DSCMachineStatus -eq 1 | Should be $true

		# reset
		$global:DSCMachineStatus = 0
		$splat.reboot = $false

	}

	it "the key is removed" {

		# set the splat to remove the new registry entry
		$splat.ensure = "Absent"
		$splat.valuename = ""
		$splat.Remove("valuedata")
		$splat.force = $true

		Set-TargetResource @splat

		# Test that the key has been removed
		Test-Path -Path "hklm:SOFTWARE\PesterTests" | Should be $false
	}
	
	it ("notifies the service for a restart: {0}" -f $service_name) {

		# Get the contents of the notifications file
		$services = (Get-Content -Path $services_notifications_file -Raw).Trim()

		$service_name -eq $services | Should be $true

		Remove-Item $services_notifications_file -Force
	}


}
