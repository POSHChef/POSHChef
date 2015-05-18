
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


function Extend-Cookbook {

  <#

  .SYNOPSIS
    Function to extend a coookbook to support POSHChef structure

  .DESCRIPTION
    This function is designed to be called by the cookbook knife plugins, create and
    download.  It ensures that a cookbook is configured properly to support a
    POSHChef cookbook.

  #>

  [CmdletBinding()]
  param (

    [Parameter(Mandatory=$true)]
    [string]
    # Name of the cookbook being updated
    $name,

    [Parameter(Mandatory=$true)]
    [string]
    # Path to the cookbook to extend
    $path
  )

  # Build up the list of directories and files that are required in the extension
  $items = @{
    directories = @(
      "files\default\POSHChef\{0}\files\default\tests" -f $name
      "files\default\POSHChef\{0}\templates\default" -f $name
      "files\default\POSHChef\{0}\attributes" -f $name
      "files\default\POSHChef\{0}\resources" -f $name
      "files\default\POSHChef\{0}\recipes" -f $name
    )
    files = @(
      "files\default\POSHChef\{0}\attributes\default.psd1" -f $name
      "files\default\POSHChef\{0}\recipes\default.ps1" -f $name
      "files\default\POSHChef\{0}\metadata.psd1" -f $name
      "poshchefignore"
    )
  }

  # iterate around the directories and make sure they all exist
  foreach ($dir in $items.directories) {

    # build up the full path to the directory
    $fullpath = "{0}\{1}" -f $path, $dir

    # if the path does not exist then create it
    if (!(Test-Path -Path $fullpath)) {
      New-Item -type directory -Path $fullpath | Out-Null
    }
  }

  # now ensure that the files exist
  foreach ($file in $items.files) {

    # build up the full path to the file
    $filepath = "{0}\{1}" -f $path, $file

    # Work out the path to the skeleton file
    $skeleton_file = "{0}\skeleton\cookbook\{1}" -f ($script:session.module.path), (Split-Path -Leaf $filepath)

    # If the file does not exist then create it using the skeleton file
    if (!(Test-Path -Path $filepath) -and (Test-Path -Path $skeleton_file)) {

      # get the contents of the skeleton file
      $contents = Get-Content -Path $skeleton_file -raw

      # Write out evaluated contents to the required file
      $cookbook_name = $name
      Set-Content -Path $filepath -Value ($ExecutionContext.InvokeCommand.ExpandString($contents))
    }
  }
}
