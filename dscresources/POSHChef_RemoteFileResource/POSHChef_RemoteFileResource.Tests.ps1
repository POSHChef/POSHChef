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
    Pester test file to test the RemoteFile Resource for DSC

    .DESCRIPTION
    The tests will ensure that an item of each different type, e.g. local, UNC, HTTP and FTP can be copied
	Where appropriate credentials will be provided to test this side of things as well


#>

# Source the module file and read in the functions
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
. "$PSScriptRoot\..\..\functions\exported\Get-CheckSum.ps1"
. "$PSScriptRoot\..\..\functions\exported\Set-Notification.ps1"
. "$PSScriptRoot\..\..\functions\Miscellaneous\Get-Base64.ps1"

Describe "POSHChef_RemoteFileResource" {

	# Get the PSDrive and therefore the root so that the full path can be used
	$PSDriveName = "TestDrive"
	$PSDrive = Get-PSDrive -Name $PSDriveName

	# Create variables as shortcuts
	$src_folder = "{0}\src" -f $PSDrive.Root

	New-Item -Path $src_folder -Type directory | out-null

	$file1 = "{0}\file1.txt" -f $src_folder
	$file2 = "{0}\file2.txt" -f $src_folder
	$file3 = "{0}\file3.txt" -f $src_folder

	# Set the content of each of the files
	Set-Content -Path $file1 -Value @"
Contains 1 line
"@

	Set-Content -Path $file2 -Value @"
Contains 1 line
Contains 2 lines
"@

	Set-Content -Path $file3 -Value @"
Contains 1 line
Contains 2 lines
Contains 3 lines
"@

	# set a service name
	$service_name = "MyAppFiles"

    # Set the notificationsservicepath file
    $services_notifications_file = "{0}\service.txt" -f $PSDrive.Root

	Context ("Given a local file: {0}" -f $file1) {

		# set where the file should be copied to
		$target = "{0}\target\file1.txt" -f $PSDrive.Root

		it ("it should be copied to the target: {0}" -f $target) {

			$result = Test-TargetResource -Ensure "Present" -Source $file1 -Target $target

			# The file should be copied so the test will be false to tell DSC to perform the copy
			$result | Should be $false
		}

		it ("it is copied to the target location") {

			Set-TargetResource -Ensure "Present" -Source $file1 -Target $target -Notifies @($service_name) -NotifiesServicePath $services_notifications_file

			Test-Path -Path $target | Should be $true
		}

		it ("sets a notification for the '{0}' service to be restarted" -f $service_name) {

			# Get the contents of the notifications file
			$services = (Get-Content -Path $services_notifications_file -Raw).Trim()

			$service_name -eq $services | Should be $true

		}

		it ("it is copied to the target location, and a reboot is requested") {

			Set-TargetResource -Ensure "Present" -Source $file1 -Target $target -Reboot $true

			$global:DSCMachineStatus -eq 1 | Should be $true

			# ensure the flag is reset so it can be tested for in other scenarios
			$global:DSCMachineStatus -eq 0
		}

		it ("will not be overwritten if the file is the same, e.g. checksum is the same") {

			# Get the checksum of the file to be copied
			$checksum = Get-Checksum -Path $file1

			$result = Test-TargetResource -Ensure "Present" -Source $file1 -Target $target -Checksum $checksum

			# The file should be not be copied so the test will be true to tell DSC not to perform the copy
			$result | Should be $true
		}

		# Update the contents of file1
		Set-Content -Path $file1 -Value "Now for something completely different" | Out-Null

		it ("will overwrite the file if it is updated") {

			$result = Test-TargetResource -Ensure "Present" -Source $file1 -Target $target

			# The file should be copied so the test will be false to tell DSC to perform the copy
			$result | Should be $false
		}

	}

	Context ("Given a directory: {0}" -f $src_folder) {

		# set the target directory
		$target = "{0}\target2" -f$PSDrive.Root

		it ("it should copy all files") {

			$result = Test-TargetResource -Ensure "Present" -Source $src_folder -Target $target

			# The file should be copied so the test will be false to tell DSC to perform the copy
			$result | Should be $false
		}

		it ("will copy all the files") {

			$result = Set-TargetResource -Ensure "Present" -Source $src_folder -Target $target

			# count the files in the source directory and those in the target
			$count = @{
				source = (Get-ChildItem -Path $src_folder).Count
				target = (Get-ChildItem -Path $target).Count
			}

			$count.source -eq $count.target | Should be $true
		}
	}

	# set the source
	$source_file = "http://mirror.internode.on.net/pub/test/1meg.test"

	Context ("Given a URL: {0}" -f $source_file) {

		$target = "{0}\downloaded.test" -f $PSDrive.Root

		it ("it should test that the file should be downloaded: {0}" -f $target) {

			$result = Test-TargetResource -Ensure "Present" -Source $source_file -Target $target

			# The file should be copied so the test will be false to tell DSC to perform the copy
			$result | Should be $false
		}

		it ("will be downloaded") {

			Set-TargetResource -Ensure "Present" -Source $source_file -Target $target -Notifies @($service_name) -NotifiesServicePath $services_notifications_file

			Test-Path -Path $target | Should be $true
		}

		it ("and notifies the '{0}' service to be restarted" -f $service_name) {

			# Get the contents of the notifications file
			$services = (Get-Content -Path $services_notifications_file -Raw).Trim()

			$service_name -eq $services | Should be $true

		}

		it ("will not be downloaded if the checksum is the same") {

			$result = Test-TargetResource -Ensure "Present" -Source $source_file -Target $target -Checksum "uuu2pUHR98/CSbBbfXILFQ=="

			# The file should be copied so the test will be false to tell DSC to perform the copy
			$result | Should be $true
		}


	}
}
