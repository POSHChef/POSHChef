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

function Invoke-RunList {
	[CmdletBinding()]
	param
	(
		#[hashtable] $runList,
		[string[]]
		$runList = @("Base_Timezone"),

        [string]
		[Parameter(Mandatory=$true)]
		$nodeName,

        [hashtable]
		$configuration = @{AllNodes = @()},

        $outputPath = "$pwd\RunList",

		$cachePath = $false
	)

	# ensure that the supplied $nodename is the same as the local FQDN
	# if not then ensure the nodename is set to the localhost so that the mof
	# file is generated with the correct filename
	$local_nodename = "{0}.{1}" -f $env:COMPUTERNAME, $env:USERDNSDOMAIN
	if ($local_nodename -ne $nodename) {
		$nodeName = $local_nodename.trim(".")
	}

	# override the nodename to be the hostnameof the machine
	$nodeName = hostname

	if ($cachePath -eq $false) {
		$cachePath = $script:Session.config.paths.file_cache_path
	}

    Configuration DSCRunList {

        Node $nodeName {

			foreach ($recipeName in $runList) {
                Write-Log -EventId PC_MISC_0001 -extra $recipeName

				# Turn the call to the recipe to use an argument hashtable
				$splat = @{
					RecipeName = $recipeName
					Parameters = $configuration.allnodes[0]
					AdditionalParameters = @{}
					CachePath = $cachepath
				}

				Write-Log -LogLevel Debug -EventId PC_DEBUG_0031 -extra "Invoke-Recipe"
				Write-Log -LogLevel Debug -Message ($splat | ConvertTo-Json -Depth 99 | Out-String)

                Invoke-Recipe @splat
            }
        }
    }

	# Build up the argument list to send to the RunList configuration object
	$splat = @{
		ConfigurationData = $configuration
		outputpath = $outputpath
		verbose = $true
	}

	Write-Log -LogLevel Debug -EventId PC_DEBUG_0031 -extra "RunList"
	Write-Log -LogLevel Debug -Message ($splat | ConvertTo-Json -Depth 99 | Out-String)

	# Excute the runlist and generate the MOF file
    DSCRunList @splat

}

