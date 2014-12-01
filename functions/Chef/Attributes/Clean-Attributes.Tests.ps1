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

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

# Only functions that already exist can be Mocked
# Stub out Write-Log function so that it can be mocked
function Write-Log(){}

. "$here\$sut"

Describe "Clean-Attributes" {

	# Mock the Write-Log function and do nothing
	# This is in case the Logging module is not vailable
	Mock Write-Log -MockWith {}

	# Define a DSC configuration hash table
	$dsc_config = @{
					AllNodes = @(

						@{

							NodeName = "roadrunner.acme.com"

							Base = @{

								ExecutionPolicy = "Restricted"
							}
						}
					)
				  }

	Context "Given DSC Configuration data for the node" {

		It "returns a hash table to be sent to the Chef server" {

			# Define the expected poshchef_attr_hash
			$expected = @{
							Base = @{

								ExecutionPolicy = "Restricted"
							}
						
						}

			# Call the function to get the result
			$attrs = Clean-Attributes -configurationdata $dsc_config

			# Compare the JSON representation of the hash tables
			# This is so that a string comparison can be done
			# Compare-Object uses objects and will only look at one level, it will not recusrively look
			$result = ($expected | ConvertTo-Json) -eq ($attrs | ConvertTo-Json)

			# if the result is the same as the expected then all good
			$result | Should Be $true
		}
	}
}
