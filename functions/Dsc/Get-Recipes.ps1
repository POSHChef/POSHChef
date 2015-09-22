
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

function Get-Recipes {
  
  <#
  
  .SYNOPSIS
    Source the recipes that are in the cookbook cache directory
    
  .DESCRIPTION
    In order to allow configuration recipes to be able call other Configurations, ala include_recipe
    they need to be loaded up before the Invoke-Recipe is called.
    
    This function finds all the recipes and passes them back to the calling function.  This is so that
    the Invoke-RunList can source the files which will then call the Invoke-Recipe.  This is to avoid
    a scoping issue.  If the recipes are sourced here they would not be available to the 'Invoke-Recipe' 
    function.  However if they are passed back to the Invoke-Recipe and they are soiurce from there
    the call to Invoke-Recipe is after (and a child) to the Invoke-Runlist thus the recipes can be found
  
  #>
  
  param (
  
      [string]
      # Path to the POSHChef cache where the recipe files are downloaded to
      $CachePath
  )
  
  # If in debug mode, show the function currently in
  Write-Log -LogLevel DEBUG -EventId PC_DEBUG_0000 -extra $MyInvocation.MyCommand
  
  # Configure the pattern to use to find all the recipes in the cache
  $pattern = "cookbooks.*recipes"
  
  # Get all the recipes
  $splat = @{
    Path = $CachePath
    Include = "*.ps1"
    Recurse = $true
  }
  
  $recipes = Get-ChildItem @splat | Where-Object { $_ -match $pattern }
  
  # Check to see if there are some recipes
  if ($recipes.count -eq 0) {
    
    # No recipes have been found to throw out an error
    Write-Log -EventId PC_ERROR_0037 -extra $CachePath -stop -LogLevel Error
    
  } else {
    
    return $recipes
    
  }
}
