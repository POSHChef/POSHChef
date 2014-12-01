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
		Pester tests file to test the Template Resource for DSC

	.DESCRIPTION
		The tests in this file will test to see if the a dummy template is patched
		properly

#>

# Source the necessary files
$TestsPath = $MyInvocation.MyCommand.Path
$script = (Split-Path -Leaf $TestsPath).Replace(".Tests.ps1", ".psm1")
$module = "{0}\{1}" -f (Split-Path -Parent -Path $TestsPath), $script
$code = Get-Content $module | Out-String
Invoke-Expression $code

# Mock functions that come from other modules
function Write-Log(){}
function Initialize-Session(){}
function Get-Configuration(){}

# Ensure required functions are available
. "$PSScriptRoot\..\..\functions\exported\ConvertFrom-JsonToHashtable.ps1"
. "$PSScriptRoot\..\..\functions\exported\Get-CheckSum.ps1"
. "$PSScriptRoot\..\..\functions\exported\Get-SourcePath.ps1"
. "$PSScriptRoot\..\..\functions\exported\Set-Notification.ps1"
. "$PSScriptRoot\..\..\functions\Miscellaneous\Get-Base64.ps1"

Describe "POSHChef_TemplateResource" {

	# Build up the attributes to use
	$attributes = @{
		default = @{
			ElasticSearch = @{
				cluster_name = "pester_tests"
				paths = @{
					data = "D:\ElasticSearch\data"
				}
			}
		}
	}

	# Set the psdrive
	$PSDriveName = "TestDrive"
	$PSDrive = Get-PSDrive $PSDriveName

	# Build up the source and destination
	$source = "{0}\template.yml.tmpl" -f $PSDrive.Root
	$destination = "{0}\dummy\template.yml" -f $PSDrive.Root
	
	# Ensure the source file has the correct information
	Set-Content -Path $source -Value `
@'
cluster.name: [[ $node.ElasticSearch.cluster_name ]]
path.data: [[ $node.ElasticSearch.paths.data ]]
'@

	# Define a source file that will not exist
	$noexist = "{0}\updated.yml.tmpl" -f $PSDrive.Root

	# name of the service to restart
	$service_name = "MSDTC"

	# Set the notificationsservicepath file
	$services_notifications_file = "{0}\service.txt" -f $PSDrive.Root

	Context "File does not exist" {
		
		# set the expected string
		$expected = @"
cluster.name: {0}
path.data: {1}
"@ -f $attributes.default.ElasticSearch.cluster_name, $attributes.default.ElasticSearch.paths.data

		# set the expected contents of the services notification file
		$expected_services = $service_name

		# Run the function to find and patch the template file
		$splat = @{
			Ensure = "Present"
			Source = $source
			Destination = $destination
			Cookbook = "Pester"
			Attributes = ($attributes.default | ConvertTo-Json -Depth 99)
			Notifies = @($service_name)
			NotifiesServicePath = $services_notifications_file
			Reboot = $false
		}

		Set-TargetResource @splat
		
		it "creates the destination file" {
			Test-Path -Path $Destination | Should Be $true
		}

		it "generated file is the same as expected" {

			# get the contents of the destination file
			$content = (Get-Content -Path $destination -Raw).Trim()

			$content -eq $expected | Should Be $true
		}

		it ("sets a notification for the '{0}' service to be restarted" -f $service_name) {

			# Get the contents of the notifications file
			$services = (Get-Content -Path $services_notifications_file -Raw).Trim()

			$service_name -eq $services | Should be $true
			
			Remove-Item $services_notifications_file -Force
		}

		it "does not update the file if the attributes are the same" {

			Test-TargetResource -Source $source -Destination $destination -Ensure "Present" -Cookbook "Pester" -attributes ($attributes.default | ConvertTo-Json -Depth 99) | Should be $true
		}

		it "if new attributes are set then the file should be updated" {

			# set the name of the cluster to test
			$attributes.default.ElasticSearch.cluster_name = "pester_cluster"

			# check the file should be patched
			Test-TargetResource -Source $source -Destination $destination -Ensure "Present" -Cookbook "Pester" -attributes ($attributes.default | ConvertTo-Json -Depth 99) | Should be $false
		}

		it "overwrites the file when the attributes are different" {

			# set the name of the cluster to test
			$attributes.default.ElasticSearch.cluster_name = "pester_cluster"

			# set the expected string
			$expected = @"
cluster.name: {0}
path.data: {1}
"@ -f $attributes.default.ElasticSearch.cluster_name, $attributes.default.ElasticSearch.paths.data

			Set-TargetResource -Ensure "Present" -Cookbook "Pester" -Source $source -Destination $destination -attributes ($attributes.default | ConvertTo-Json -Depth 99)

			# get the contents of the destination file
			$content = (Get-Content -Path $destination -Raw).Trim()

			$content -eq $expected | Should Be $true
		}
		
		it ("requests a reboot if the file is new") {

			# set the flag to reboot the machine
			$splat.Reboot = $true

			# ensure the destination is removed
			Remove-Item -Path $destination -Force | Out-Null

			Set-TargetResource @splat

			$global:DSCMachineStatus -eq 1 | Should be $true

			# reset the reboot flag
			$global:DSCMachineStatus = 0
		}

		it "file can be removed" {

            # Set the argument splat for the resource
            $splat.Ensure = "Absent"

            Set-TargetResource @splat

            Test-Path -Path $destination | Should Be $false

		}

	}

	Context "File does not exist, but neither does the source" {

		# Create the splat argument hash
		$splat = @{
			Ensure = "Present"
			Source = $noexist
			Destination = $destination
			Cookbook = "Pester"
			Attributes = ($attributes.default | ConvertTo-Json -Depth 99)
			Notifies = @($service_name)
			NotifiesServicePath = $services_notifications_file
		}

		it "should throw error" {

			{ Test-TargetResource @splat } | Should throw

		}
	}
}
