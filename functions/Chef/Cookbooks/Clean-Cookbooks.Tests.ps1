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

# Test script for Clean-Cookbooks
# Ensures that obsolete files are removed as well as empty directories

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

# Only functions that already exist can be Mocked
# Stub out Write-Log function so that it can be mocked
function Write-Log(){}

# Source the file under test
. "$here\$sut"

Describe "Clean-Cookbooks" {

	# Define the session variable with the path the cache path
	# As well as a list of the cookbooks that should be in the run
	$script:session = @{
		config = @{
			paths = @{
				file_cache_path = $TestDrive
			}
		}

		cookbooks = @{
			IIS = "latest"
			DNS = "latest"
		}
	}

	it "Removes cached cookbooks not in the list - Base" {

		# Create directories to represent cached cookbooks
		$folders = @(
			join-path $TestDrive "cookbooks\IIS"
			join-path $TestDrive "cookbooks\DNS"
			join-path $TestDrive "cookbooks\Base"
		)

		New-Item -type directory -Path $folders | Out-Null

		Clean-Cookbooks

		# Write out several tests to make sure that IIS and DNS exist but Base does not
		Test-Path -Path (Join-Path $TestDrive "cookbooks\Base") | Should Be $false

	}


	
	it "Removes files that are now not part of the cookbook" {

		# Configure some files in the TestDrive to check that the obsolete one is removed
		Setup -File "cookbooks\IIS\metadata.psd1" `
@"
Metadata
"@
		Setup -File "cookbooks\IIS\shouldnotexist.ps1" `
@"
This file should not exist
"@
		
		# Create directories to represent cached cookbooks
		$folders = @(
			join-path $TestDrive "cookbooks\DNS"
			join-path $TestDrive "cookbooks\Base"
		)

		New-Item -type directory -Path $folders -Force | Out-Null

		gci -Recurse -path $TestDrive

		# Build up list of files that should exist in the IIS cookbook
		$files = @{
			IIS = @(
				join-Path $TestDrive "cookbooks\IIS\metadata.psd1"
			)
		}

		# Clean the cookbooks
		Clean-Cookbooks -files $files

		Test-Path -Path (join-Path $TestDrive "cookbook\IIS\shouldnotexist.ps1") | Should Be $false
	}

}
