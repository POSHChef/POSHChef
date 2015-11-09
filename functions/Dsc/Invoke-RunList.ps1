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
		$runList = @(),

    [string]
		[Parameter(Mandatory=$true)]
		$nodeName,

    [hashtable]
		$configuration = @{AllNodes = @()},

    $outputPath = "$pwd\RunList",

		$cachePath = $false
	)

	# If in debug mode, show the function currently in
  Write-Log -LogLevel DEBUG -EventId PC_DEBUG_0000 -extra $MyInvocation.MyCommand

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

	# Import all the recipes in the cache directory
	# The following functionc all returns all the recipes in the cookbook cache directory
	# They are sourced here due to scoping problems.  Please refer the comments in 'Get-Recipes' for
	# more information
	$recipes = Get-Recipes -CachePath $CachePath
	
	# Recipes have been found so source them so they can be used
	Write-Log -EventId PC_INFO_0068 
	Write-Log -EventId PC_DEBUG_0033 -LogLevel DEBUG -extra @($CachePath, $recipes.count)
	
	# iterate around each of the recipes and source them
	foreach ($recipe in $recipes) {
		Write-Log $recipe.fullname -foregroundColor cyan -loglevel debug

		. ($recipe.FullName)
	}

	# Decalre the main Configuration block for the node and iterate around all of the recipes
	# that are declared in the run list
  Configuration DSCRunList {

    Node $nodeName {

			foreach ($recipeName in $runList) {
	  
		    Write-Log -EventId PC_MISC_0001 -extra $recipeName

				# Turn the call to the recipe to use an argument hashtable
				$splat = @{
					RecipeName = $recipeName
					Parameters = $configuration.allnodes[0]
					CachePath = $cachepath
				}

				Write-Log -LogLevel Debug -EventId PC_DEBUG_0031 -extra "Invoke-Recipe"
				Write-Log -LogLevel Debug -Message $splat -asJson -jsonDepth 99

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
	Write-Log -LogLevel Debug -Message $splat -asJson -jsonDepth 99

	# Excute the runlist and generate the MOF file
  DSCRunList @splat

}
