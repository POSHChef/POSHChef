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
. "$here\$sut"

Describe "Sort-Hashtable" {

	Context "Given a nested hashtable" {

	# Build up the hashtable to pass to the function that neesd to be sorted
	$hash = @{
				b = "B"
				a = "A"
				c = @{
					m = "M"
					d = "D"
					z = "Z"
				}
			}

		It "should alphabetically sort throughout the hashtable" {
			
			# defined the expected hash
			# this needs to use the ordered type
			$expected = [Ordered] @{
							a = "A"
							b = "B"
							c = [Ordered] @{
								d = "D"
								m = "M"
								z = "Z"
							}
						}

			# call the function to sort the hash
			$sorted_hash = Sort-Hashtable -hash $hash

			# test the returned variable
			$result = ($sorted_hash | ConvertTo-Json -Depth 3) -eq ($expected | ConvertTo-Json -Depth 3)

			$result | Should Be $true

		}
	}
}


