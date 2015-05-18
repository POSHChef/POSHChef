
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

function Get-CookbookFiles {

  <#

  .SYNOPSIS
    Retrieve the files for the cookbook and remove ignored files

  .DESCRIPTION
    There can be a lot of files in a cookbook that do not need to be uplaoded to the chef server
    This is because of the various testing frameworks (Test-Kitchen) and management systems (Berkshelf)
    but they do not do anything once on the server.  This function will use the 'poshchefignore' file,
    if it exists, to return a list of files to the calling function which should be uploaded

  #>

  [Cmdletbinding()]
  param (

    [Parameter(Mandatory=$true)]
    [string]
    # Path to the cookbook that is to be uploaded
    $path
  )

  # If in debug mode, show the function currently in
  Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

  $files = Get-ChildItem -Path $path -Recurse | Where-Object { $_.PSISContainer -eq $false }

  # Determine if a poshchefignore file exists
  $poshchefignore_file = Join-Path $path "poshchefignore"
  if (Test-Path -Path $poshchefignore_file) {

    $poshchefignore = Get-Content -Path $poshchefignore_file | Where-Object { $_ }

    # iterate around the chefignore array removing anything beginning with a #
    # and prepend the pattern with the beginning of line character for Regex
    $poshchefignore = $poshchefignore | Foreach-Object {
      if ($_ -notmatch "^#") {
        "^{0}" -f $_
      }
    }

    # Ensure the path ends in a \ so that the replacement works
    if (!$path.EndsWith("\")) {
      $path += "\"
    }

    # Escape the path so that it can be used to remove that part of the file from the full path of the file
    # this is so that the pattern can be matched against the entries in the poshchefignore file
    $pattern_escaped = [System.Text.RegularExpressions.Regex]::Escape($path)

    # Create an array to hold the files that are eligible for upload
    $eligible_files = New-Object System.Collections.ArrayList

    foreach ($file in $files) {

      # Set flag to denote if the file should be ignored
      $skip_file = $false

      # Set the phrase which should be tried against the patterns in the poshchefignore file
      $phrase = $file.FullName -replace $pattern_escaped, ""

      # iterate around the entries being ignored
      foreach ($ignore in $poshchefignore) {

        # perform a test to see if the phrase matches the ignore pattern
        if ($phrase -match $ignore) {
          $skip_file = $true

          # break out of the loop because the first match has been found
          break
        }
      }

      # if the skip_file is false add to the eligible files
      if (!$skip_file) {
        $eligible_files.Add($file) | Out-Null
      }

    }

    # Output information about the files that have been ignored
    Write-Log -EventId PC_INFO_0067 -Extra @($files.count, ($files.count - $eligible_files.count))

    # set the value to return
    $return = $eligible_files
  } else {
    $return = $files
  }

  # return the list of files to the calling function
  return $return
}
