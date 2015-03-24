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


function cookbook_extend {

  <#

  .SYNOPSIS
    Extends an existing cookbook by adding the POSHChef file structure

  .DESCRIPTION
    POSHChef can be used within an existing cookbook, but the file structure
    needs to be in place to support it

    This plugin will ensure that an existing cookbook has the correct structure in place


  #>

  [CmdletBinding()]
  param (

    [string[]]
    # Name(s) of the cookbooks that should be extended
    $name,

    [string]
    # Path to where the specified cookbooks are located
    $path = [String]::Empty

  )

  Write-log -message " "

  # Setup the mandatory parameters
  $mandatory = @{
    name = "String array of cookbooks to extend (-name)"
  }

  Confirm-Parameters -Parameters $PSBoundParameters -mandatory $mandatory

  # iterate around the names of the cookbooks
  foreach ($id in $name) {

    # Check to see if the id is a relative or absolute path
    $uri = $id -as [System.Uri]
    if ($uri.IsAbsoluteUri -eq $true) {
      $cbpath = $id

    }  else {

      # determine the parent path to use, depending on whether the path has been
      # passed to the plugin or not
      $parent = "{0}\cookbooks" -f $script:session.config.chef_repo
      if (![String]::IsNullOrEmpty($path)) {
        $parent = $path
      }

      $cbpath = "{0}\{1}" -f $parent, $id
    }

    # Determine that the cookbook path exists
    if (!(Test-Path -Path $cbpath)) {
      Write-Log -EventId PC_WARN_0016 -extra @($id, $cbpath)
      continue
    }

    # as the path is absolute we need the name of the cookbooko
    $id = Split-Path -Leaf -Path $cbpath

    Write-Log -Eventid PC_INFO_0063 -extra $id

    Write-Log -EventId PC_INFO_0024
    Write-Log -Eventid PC_MISC_0001 -extra $cbpath

    # Build up the list of directories and files that are required in the extension
    $items = @{
      directories = @(
        "files\default\POSHChef\{0}\files\default\tests" -f $id
        "files\default\POSHChef\{0}\templates\default" -f $id
        "files\default\POSHChef\{0}\attributes" -f $id
        "files\default\POSHChef\{0}\resources" -f $id
        "files\default\POSHChef\{0}\recipes" -f $id
      )
      files = @(
        "files\default\POSHChef\{0}\attributes\default.psd1" -f $id
        "files\default\POSHChef\{0}\recipes\default.ps1" -f $id
        "files\default\POSHChef\{0}\metadata.psd1" -f $id
      )
    }

    # iterate around the directories and make sure they all exist
    foreach ($dir in $items.directories) {

      # build up the full path to the directory
      $fullpath = "{0}\{1}" -f $cbpath, $dir

      # if the path does not exist then create it
      if (!(Test-Path -Path $fullpath)) {
        New-Item -type directory -Path $fullpath | Out-Null
      }
    }

    # now ensure that the files exist
    foreach ($file in $items.files) {

      # build up the full path to the file
      $filepath = "{0}\{1}" -f $cbpath, $file

      # Work out the path to the skeleton file
      $skeleton_file = "{0}\skeleton\cookbook\{1}" -f ($script:session.module.path), (Split-Path -Leaf $filepath)

      # If the file does not exist then create it using the skeleton file
      if (!(Test-Path -Path $filepath) -and (Test-Path -Path $skeleton_file)) {

        # get the contents of the skeleton file
        $contents = Get-Content -Path $skeleton_file -raw

        # Write out evaluated contents to the required file
        $cookbook_name = $id
        Set-Content -Path $filepath -Value ($ExecutionContext.InvokeCommand.ExpandString($contents))
      }
    }
  }

}
