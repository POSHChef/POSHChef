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


function role_show {


  <#

  .SYNOPSIS
    Gets the named role from the chef server

  .DESCRIPTION
    Retrieves the named role from the Chef server
    Items are passed back as an object or optionally saved to the filesystem

  .NOTES
    Care must taken when getting roles from the chef server as they may overwrite
    role files that are maintained in source control.

  .EXAMPLE

    PS C:\> Invoke-POSHKnife role show -name foo -save

    Will save the role named 'foo' in the default directory which is <BASEDIR>\chefitems\role

  #>

  [CmdletBinding()]
  param (

    [string]
    # Name of role to show
    $name,

    [switch]
    # Specify if the node should be saved to a file
    $save,

    [string]
    # Directory that the file should be saved in.
    # This is applicable when the filename is not an absolute path
    # The default for this is the <BASEDIR>\nodes directory
    $folder = [String]::Empty,

    [string]
    # Filename that contents should be saved in
    # By default this will be the name of the node with JSON extension
    $filename = [String]::Empty,

    [string]
    # The format that the file should be written out as
    # By default this is as a PSON object
    $format = "json"


  )

  # Setup the mandatory parameters
  $mandatory = @{
    name = "Name of role to display (-name)"
  }

  Confirm-Parameters -Parameters $PSBoundParameters -mandatory $mandatory

  Write-Log -Message " "
  Write-Log -EVentId PC_INFO_0031 -extra ("Display", "Role")

  # Call the POSHChef function to get the node
  $role = Get-Role -name $name

  # Depending on whether a file has been specified save the contents to it
  # or output them to the pipeline
  if (!$save) {
    $role
  } else {

    # Build up the argument hashtable to pass to the Save-ChefItem
    $splat = @{
      folder = $folder
      filename = $filename
      format = $format
    }
    $role | Save-ChefItem @splat

  }

}
