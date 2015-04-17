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
    Pester test file to test the Directory Resource for DSC

    .DESCRIPTION
    The tests here will check that a directory is created, it has the correct permissions
    applied and if specified a share is created.

    After doing this directly it will then test the Test-TargetResource to make sure that the internal Test function works as
    expected

#>

# Source the module file and read in the functions
$TestsPath = $MyInvocation.MyCommand.Path
$script = (Split-Path -Leaf $TestsPath).Replace(".Tests.ps1", ".psm1")
$module = "{0}\{1}" -f (Split-Path -Parent -Path $TestsPath), $script
$code = Get-Content $module | Out-String
Invoke-Expression $code

function Write-Log(){}
function Update-Session(){}
function Get-Configuration(){}
function Set-LogParameters(){}

# Include required functions
. "$PSScriptRoot\..\..\functions\exported\Set-Notification.ps1"
. "$PSScriptRoot\..\..\functions\exported\ConvertFrom-JSONToHashtable.ps1"

Describe "POSHChef_FolderResource" {

	# Create a simple hash with one folder to be created
	$folder = "{0}\temp\pester_test_1" -f $env:windir
	$folders = @{
					$folder = @{}
				}

	# Iterate around the keys in the hash table to make sure that the folder is created
	foreach ($folder in $folders.keys) {

		Context ("Create and delete the directory '{0}'" -f $folder) {

			Set-TargetResource -ensure "Present" -path $folder

			it "creates the directory" {
				Test-Path -Path $folder | Should Be $true
			}

			it "runs the Test-TargetResource to check folder exists" {
				Test-TargetResource -path $folder | Should Be $true
			}

			Set-TargetResource -ensure "Absent" -path $folder

			it "deletes the directory" {
				Test-Path -Path $folder | Should Be $false
			}

			it "runs the Test-TargetResource to check the folder does not exist" {
				Test-TargetResource -path $folder | Should Be $false
			}
		}
	}


	# Add permissions to the hash table to check that they are added
	$folders.$folder.permissions = @{Everyone = "FullControl"} | ConvertTo-Json

	# Iterate around the keys in the hash table to make sure that the folder is created with the correct permissions
	foreach ($folder in $folders.keys) {

		Context ("Create and delete the directory '{0}' with permissions" -f $folder) {

			Set-TargetResource -ensure "Present" -path $folder -permissions $folders.$folder.permissions

			it "creates the directory" {
				Test-Path -Path $folder | Should Be $true
			}

			# iterate around the permissions
			foreach ($account in $folders.$folder.permissions.keys) {
				it ("sets the permissions for '{0}' to '{1}'" -f $account, $folders.$folder.permissions.$account) {

					# set default value for $result
					$result = $true

					# Use the Get-Acl cmdlet to retrieve the permissions that have been set on the folder
					# and check that they are as specified
					$acl = Get-Acl -Path $folder

					# Get the access for the user
					$user = $acl.Access | Where-Object { $_.IdentityReference -eq $account }

					# Work out the result so that is can be tested
					if ([String]::IsNullOrEmpty($user)) {
						$result = $false
					} else {

						# Determine if the rights has been set properly
						$rights = $user | Where-Object { $_.FilesystemRights -eq $folders.$folder.permissions.$account}

						if ([String]::IsNullOrEmpty($rights)) {
							$result = $false
						}
					}

					# Test the result to make sure it is not false
					$result | Should Not Be $false
				}
			}

			it "runs the Test-TargetResource to check all 'true'" {
				Test-TargetResource -path $folder -permissions $folders.$folder.permissions | Should Be $true
			}

			Set-TargetResource -ensure "Absent" -path $folder

			it "deletes the directory" {
				Test-Path -Path $folder | Should Be $false
			}
		}
	}


	# Now add a share name to the hash table
	$share_name = "pester_test"
	$folders.$folder.share = @{
								 name = $share_name
							  }

	# create filter to be used to check for the share
	$filter = "Name='{0}'" -f $share_name

	# Iterate around the keys in the hash table to make sure that the folder is created with the correct permissions
	# and a share
	foreach ($folder in $folders.keys) {

		Context ("Create and delete the directory '{0}' with permissions and is shared out as '{1}'" -f $folder, $folders.$folder.share.name) {

			Set-TargetResource -ensure "Present" -path $folder -permissions $folders.$folder.permissions -share $folders.$folder.share.name

			it "creates the directory" {
				Test-Path -Path $folder | Should Be $true
			}

			# iterate around the permissions
			foreach ($account in $folders.$folder.permissions.keys) {
				it ("sets the permissions for '{0}' to '{1}'" -f $account, $folders.$folder.permissions.$account) {

					# set default value for $result
					$result = $true

					# Use the Get-Acl cmdlet to retrieve the permissions that have been set on the folder
					# and check that they are as specified
					$acl = Get-Acl -Path $folder

					# Get the access for the user
					$user = $acl.Access | Where-Object { $_.IdentityReference -eq $account }

					# Work out the result so that is can be tested
					if ([String]::IsNullOrEmpty($user)) {
						$result = $false
					} else {

						# Determine if the rights has been set properly
						$rights = $user | Where-Object { $_.FilesystemRights -eq $folders.$folder.permissions.$account}

						if ([String]::IsNullOrEmpty($rights)) {
							$result = $false
						}
					}

					# Test the result to make sure it is not false
					$result | Should Not Be $false
				}

			}

			it "shares out the folder" {
				Get-WmiObject -Class Win32_Share -Filter $filter | Should Not BeNullOrEmpty
			}

			it "runs the Test-TargetResource to check all 'true'" {
				Test-TargetResource -path $folder -permissions $folders.$folder.permissions -share $folders.$folder.share.name | Should Be $true
			}

			Set-TargetResource -ensure "Absent" -path $folder

			it "removes the share from the system" {

				Get-WmiObject -Class Win32_Share -Filter $filter | Should BeNullOrEmpty
			}

			it "deletes the directory" {
				Test-Path -Path $folder | Should Be $false
			}

		}

	}

	# Finally add some share permissions to the share
	$folders.$folder.share.acl = @{ Everyone = "FullControl" } | ConvertTo-Json

	# Iterate around the keys in the hash table to make sure that the folder is created with the correct permissions
	# and a share
	foreach ($folder in $folders.keys) {

		Context ("Create and delete the directory '{0}' with permissions and is shared out as '{1}' with acl" -f $folder, $folders.$folder.share.name) {

			Set-TargetResource -ensure "Present" -path $folder -permissions $folders.$folder.permissions -share $folders.$folder.share.name -acl $folders.$folder.share.acl

			it "creates the directory" {
				Test-Path -Path $folder | Should Be $true
			}

			# iterate around the permissions
			foreach ($account in $folders.$folder.permissions.keys) {
				it ("sets the permissions for '{0}' to '{1}'" -f $account, $folders.$folder.permissions.$account) {

					# set default value for $result
					$result = $true

					# Use the Get-Acl cmdlet to retrieve the permissions that have been set on the folder
					# and check that they are as specified
					$acl = Get-Acl -Path $folder

					# Get the access for the user
					$user = $acl.Access | Where-Object { $_.IdentityReference -eq $account }

					# Work out the result so that is can be tested
					if ([String]::IsNullOrEmpty($user)) {
						$result = $false
					} else {

						# Determine if the rights has been set properly
						$rights = $user | Where-Object { $_.FilesystemRights -eq $folders.$folder.permissions.$account}

						if ([String]::IsNullOrEmpty($rights)) {
							$result = $false
						}
					}

					# Test the result to make sure it is not false
					$result | Should Not Be $false
				}

			}

			it "shares out the folder" {
				Get-WmiObject -Class Win32_Share -Filter $filter | Should Not BeNullOrEmpty
			}

			# get the acl that has been set on the sahre from WMI
			$dacl = @(Get-WmiObject -Class Win32_LogicalShareSecuritySetting -filter $filter | Foreach-Object {
							$_.GetSecurityDescriptor().Descriptor.DACL
						})

			# iterate around the acl that is mean to be set to ensure that it is indeed correct
			foreach ($account in $folders.$folder.share.acl.keys) {

				it ("sets the acl for '{0}' to '{1}'" -f $account, $folders.$folder.share.acl.$account) {

					# get a numerical value for the access that is required
					$mask = _Translate-AccessMask -name $folders.$folder.share.acl.$account

					# Get an object from the DACL for the specific user
					$dacl | Where-Object { $_.Trustee.Name -ieq $account -and $_.AccessMask -eq $mask} | Should Not BeNullOrEmpty

				}

			}

			it "runs the Test-TargetResource to check all 'true'" {
				Test-TargetResource -path $folder -permissions $folders.$folder.permissions -share $folders.$folder.share.name -acl $folders.$folder.share.acl | Should Be $true
			}

			Set-TargetResource -ensure "Absent" -path $folder

			it "removes the share from the system" {

				Get-WmiObject -Class Win32_Share -Filter $filter | Should BeNullOrEmpty
			}

			it "deletes the directory" {
				Test-Path -Path $folder | Should Be $false
			}

		}

	}
}
