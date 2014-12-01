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

Function Invoke-Recipe {
    <#
        Credit: Based on Invoke-Splat -> http://theessentialexchange.com/blogs/michael/archive/2013/03/08/powershell-quick-script-invoke-splat.aspx

        This gives us a terse way of calling the recipe functions that wrap our
        DSC resources.
    #>
    [CmdletBinding()]    
    param(
        [Parameter(ValueFromPipeline=$true, Mandatory=$true, Position=0)]
        [string]
        $RecipeName,

        [Parameter(ValueFromPipeline=$true, Mandatory=$true, Position=1)]
        [hashtable]
        $Parameters,

        [Parameter(ValueFromPipeline=$true, Mandatory=$false, Position=2)]
        [hashtable]
        $AdditionalParameters,

		[Parameter(ValueFromPipeline=$true, Mandatory=$false, Position=3)]
		[string]
		$CachePath
    )
	
	# Split the recipe name up so that it contains the consituent parts
	$cookbook, $recipe = $RecipeName -split "_"
	
	# Check that the specified recipe exists in the file_cache_path
	# if it does source the file, if not output message
	# build up the pattern to match against the files
	$pattern = "{0}\\recipes\\{1}.ps1" -f $cookbook, $recipe

	Write-Log -IfDebug -EventId PC_DEBUG_0015 -extra ("{0} - {1}" -f $CachePath, $pattern)

	# attempt to find the file
	$recipe_exists = Get-ChildItem -Path ("{0}" -f $CachePath) `
								   -Recurse `
								   -Include "*.ps1" | Where-Object { $_.FullName -match $pattern }

	# check the $recipe_exists variable
	if ([String]::IsNullOrEmpty($recipe_exists)) {

		Write-Log -LogLevel Warn -EventId PC_WARN_0006 -extra $recipeName

	} else {

		# Source the recipe file so that the function can be executed
		. ($recipe_exists.FullName)

		# define the splat hashtable that will be used to add necessary arguments
		$splat = @{}

		# Get the parameters that the recipe accepts
		$recipe_params = (Get-Command -Name $RecipeName).Parameters.Keys

		# if the recipe_params contain a key called node then add to the splat
		if ($recipe_params -contains ("node")) {
			$splat.node = $Parameters
		}

		# if in debug mode write out the parameters
		Write-Log -LogLevel Debug -EventId PC_DEBUG_0031 -extra $RecipeName
		Write-Log -LogLevel Debug -Message ($splat | ConvertTo-Json -Depth 99 | Out-String)

		# Execute the recipe by passing the splat
		& $RecipeName @splat
		
					
	}
		
}
