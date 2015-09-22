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
. "$here\Invoke-Recipe.ps1"
. "$here\Get-Recipes.ps1"

Describe "Invoke-RunList" {

	# Mock the Write-Log function and do nothing
	# This is in case the Logging module is not vailable
	Mock Write-Log -MockWith {}

	# create the file that will be used as the recipe
	Setup -File "cookbooks\Base\recipes\ExecutionPolicy.ps1" `
@'
Configuration Base_ExecutionPolicy {

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateScript({
				$_.contains("Base") -and
                $_.Base.contains("ExecutionPolicy") -and 
                @("Unrestricted","RemoteSigned","AllSigned","Restricted") -contains $_.Base.ExecutionPolicy
            })]
        [hashtable]
        # name of hashtable to use from the attributes
        $node
    )

	$Base = $node.Base

    Script SetExecutionPolicy {
        GetScript = { return @{ExecutionPolicy = Get-ExecutionPolicy} }
        TestScript = { $current = Get-ExecutionPolicy; return ($current -ieq $using:Base.ExecutionPolicy) }
        SetScript = { Set-ExecutionPolicy $using:Base.ExecutionPolicy  }
    }
}
'@

	# work out the name of the machine the test is being run on
	$nodename = "{0}.{1}" -f $env:COMPUTERNAME, $env:env:USERDNSDOMAIN

	# Build a configuration hashtable to pass to the run list
	$configuration = @{
					AllNodes = @(
						@{
							NodeName = $nodename
							Base = @{
								ExecutionPolicy = "RemoteSigned"
							}
						}
					)
				  }

	Context "A POSHChef RunList" {

		# build up hashtable of arguments to pass to the function
		$splat = @{
			runlist = "Base_ExecutionPolicy"
			nodename = $nodename
			configuration = $configuration
			cachepath = "TestDrive:"
			outputpath = "TestDrive:"
		}

		# Invoke the runlist and return a MOF file object
		$mof = Invoke-RunList @splat

		it "generates a MOF file" {

			$mof | Should Not BeNullOrEmpty
		}
	}
}
