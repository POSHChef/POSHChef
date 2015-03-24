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

function node_runlist {

  <#

  .SYNOPSIS
    Adds ar removes items from the runlist of a node

  .DESCRIPTION
    This plugin allows the run list of the selected node to be updated using
    POSHKnife.

    The name of the node must be specified.
    An array list of items to add to the run list must also be specified
    By default the operation is to add the items to the list

    Before updating the runlist the plugin will check that the items exist on the
    server.  If such a thing occurs then a rollup of all the items that could not
    be found is displayed.

  .NOTES

    Although POSHChef is not case sensitive the Chef server is.  This means that 'role[Base]'
    will not be found if 'role[base]' is specified.  This is only for when things are
    being downloaded from the Chef server by POSHChef or POSHKnife but as it is the
    runlist that governs what is to be downloaded this is very important.

  .EXAMPLE

    PS C:\> Invoke-POSHKnife node runlist -name server-01.poshchef.com -items @("role[base]")

    This will attempt to add the base role to the node 'server-01.poshchef.com'
  #>

  [CmdletBinding()]
  param (

    [string]
    # Name of the node to update the runlist on
    $name,

    [string[]]
    # String array of items to add to the runlist on the node
    $items,

    [string]
    # Type of operation being performed
    # Default operation is Add
    $operation = "add"

  )

  Write-Log -Message " "
  Write-Log -EVentId PC_INFO_0031 -extra ("Updating", "RunList")

  # Check that the mandatory parameters have been set
  $mandatory = @{
    name = "Name of node (-name)"
    items = "Array of items to add to the runlist (-items)"
    operation = "Operation to perform, 'add' or 'remove' (-operation)"
  }

  # Ensure that the default values for the parameters have been set
  foreach ($param in $mandatory.keys) {
    if (!$PSBoundParameters.ContainsKey($param)) {
      $PSBoundParameters.$param = (Get-Variable -Name $param).Value
    }
  }

  Confirm-Parameters -parameters $PSBoundParameters -mandatory $mandatory

  # define an array to hold the list of missing item
  $missing = @{
    cookbooks = New-Object System.Collections.ArrayList
    roles = New-Object System.Collections.ArrayList
  }

  if ([String]::IsNullOrEmpty($operation)) {
    $operation = "add"
  }

  # check that the operation is valid
  if (@("add", "remove") -notcontains $operation) {
    Write-Log -EventId PC_ERROR_0033 -extra $operation -loglevel Error
    return
  }

  # Ensure that the specified items have the correct format
  $incorrect = $items | Where-Object { $_ -notmatch "(role|recipe)\[.*\]" }
  if (![String]::IsNullOrEmpty($incorrect)) {
    Write-Log -LogLevel Error -EventId PC_ERROR_0036 -extra $incorrect
    return
  }

  # Get the node that need to be worked on
  $node = Get-Node -name $name

  # only proceed if the node is not false
  if ($node -ne $false) {

    # get the list of roles that are known to the system
    $roles = Get-Role

    # get the list of cookbooks that are known to the system
    $cookbooks = Get-CookbookList

    # now check that the items spcified are known to the system,
    # otherwise add them to the missing list
    # iterate around the items

    foreach ($item in @($items)) {

      switch ($operation) {
        "add" {
          # determine the type the item that has been spcified
          $status = $item -match "(?:(?!\[).)*"
          $chef_type = $matches[0]

          # switch on the type so that it can be checked against the appropriate list
          switch ($chef_type) {
            "recipe" {

              # Get the name of the cookbook from the recipe
              $status = $item -match "\[(.*?)[\]|:]"
              $cookbook = $matches[1]

              # determine if the cookbook is in the list
              # This must be a case sensitve check
              if ($cookbooks.keys -cnotcontains $cookbook) {
                $missing.cookbooks.Add($cookbook) | Out-Null
              }

            }

            "role" {

              # Get the name of the role from the item
              $status = $item -match "\[(.*?)\]"
              $role = $matches[1]

              # determine if the role is in the list
              if ($roles.keys -cnotcontains $role) {
                $missing.roles.Add($role) | Out-Null
              }

            }
          }
        }

        "remove" {

          # remove the item from the node run_list
          $run_list = [System.Collections.ArrayList] $node.run_list
          $run_list.remove($item)
          $node.run_list = $run_list.ToArray()
        }
      }
    }

    if ($operation -eq "add") {
      # Determine if there are any items the missing arrays
      if ($missing.cookbooks.count -gt 0 -or $missing.roles.count -gt 0) {
        Write-Log -EventId PC_ERROR_0032 -loglevel error

        if ($missing.cookbooks.count -gt 0) {
          Write-Log -EventId PC_MISC_0001 -extra "Cookbooks"

          foreach ($name in $missing.cookbooks) {
              Write-Log -EventId PC_MISC_0002 -extra $name
          }
        }

        if ($missing.roles.count -gt 0) {
          Write-Log -EventId PC_MISC_0001 -extra "Roles"

          foreach ($name in $missing.roles) {
            Write-Log -EventId PC_MISC_0002 -extra $name
          }
        }

        # there are errors do not continue
        return
      }
    }

    # based on the operation add or remove the necesary items from the tunlust
    if ($operation -eq "add") {

      # append the items onto the runlust of the node
      $node.run_list += @($items)

    }

    Write-Log -EventId PC_MISC_0000 -extra $node.name

    # Now that the runlist has been modified send the modified information to the server
    # set the argument information
    $splat = @{
      node = $node
      update = $true
    }

    Set-Node @splat

  }
}
