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


function databag_delete {

  <#

  .SYNOPSIS
    Delete a databag or specific items from the chef server

  .DESCRIPTION
    This plugin removes databags or items within databags.

  .EXAMPLE

    PS C:\> Invoke-POSHKnife databag delete -bags acme,kitchen

    This will remove the two databags 'acme' and 'kitchen' from the Chef server if they exist

  .EXAMPLE

    PS C:\> Invoke-POSHKnife databag delete -name acme -items roadrunner

    This will remove the 'roadrunner' item from the 'acme' databag

  #>

  [CmdletBinding()]
  param (

    [Parameter(ParameterSetName="databag")]
    [string[]]
    # String array of databags to remove from the chef server
    $bags,

    [Parameter(ParameterSetname="item")]
    [string]
    # Name of the databag from which items will be removed
    $name,

    [Parameter(ParameterSetName="item")]
    [string[]]
    # String array of items to be removed
    $items

  )

  # Setup the mandatory parameters
  switch ($PSCmdlet.ParameterSetName) {
    "databag" {

      # Set the mandatory parameters
      $mandatory = @{
        bags = "String array of databags to remove (-bags)"
      }

      $extra = "Databags"

    }
    "item" {

      # Set the mandatory parameters
      $mandatory = @{
        name = "Name of databag that items will be removed from (-name)"
        items = "Items to be removed from the specified databag (-items)"
      }

      $extra = "Databag Items"
    }
  }

  Confirm-Parameters -Parameters $PSBoundParameters -mandatory $mandatory

  # determine the mapping for the chef query
  $mapping = "{0}s" -f $chef_type

  Write-Log -Message " "
  Write-Log -EventId PC_INFO_0031 -extra ("Deleting", $extra)

  # based on the parametersetname work out the things that need iterating over
  $uri_parts = New-Object System.Collections.ArrayList
  # Set the base uri to be used on when deleting
  $uri_parts.Add("/data") | Out-Null

  switch ($PSCmdlet.ParameterSetname) {
    "databag" {

      # Set the things that need to be iterated over
      $things = $bags

      # get a list of things that already exist on the server
      $exists = Get-Databag

      $eventid = "PC_WARN_0020"
    }

    "item" {

      # Set the things that need to be iterated over
      $things = $items

      # Set the base uri to be used on when deleting
      $uri_parts.Add($name) | Out-Null

      $exists = Get-Databag -name $name

      $eventid = "PC_WARN_0021"
    }
  }

  # iterate around the things that need to be removed
  foreach ($thing in $things) {

    # Check that the thing already exists on the server
    if (!$exists.containskey($thing)) {
      Write-Log -LogLevel Warn -EventId $eventid -extra $thing
      continue
    }

    Write-Log -EventId PC_MISC_0001 -extra $thing

    # add the name of the thing to the url_parts
    $uri_parts.Add($thing) | Out-Null

    # Build up the argument hashtable
    $splat = @{
      method = "DELETE"
      path = ($uri_parts -join "/")
    }

    $results = Invoke-ChefQuery @splat
  }
}
