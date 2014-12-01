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



# Get a list of the functions that need to be sourced
$Functions = Get-ChildItem -Recurse "$PSScriptRoot\functions" -Include *.ps1 | Where-Object { $_ -notmatch "Providers" -and $_ -notmatch ".Tests.ps1" }

# source each of the individual scripts
foreach ($function in $functions) {
	. $function.FullName
}

# get a list of the functions that need to be expotred
$functions_to_export = $Functions | Where-Object { $_.FullName -match "Exported"} | ForEach-Object { $_.BaseName }

# Decalre the session variable which will be scoped to the module
$Session = @{"fred" = "bloggs"}

# Set aliases for the two most used commands
Set-Alias -Name POSHChef -Value Invoke-POSHChef
Set-Alias -Name POSHKnife -Value Invoke-POSHKnife

# Export the accessible functions
Export-ModuleMember -function ( $functions_to_export )
Export-ModuleMember -Alias "*"

