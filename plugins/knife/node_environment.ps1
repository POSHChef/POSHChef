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

function node_environment {

  <#

    .SYNOPSIS
      Sets the environment that a node is a member of

    .DESCRIPTION
      As environments can have different settings on them there are times when it is
      necessary to move a node to a new environment.  This plugin achieves that by
      modifying the environment setting of the node

      The names of the node and the environment and the environment are required.

    .NOTES
      The same action could be achieved by using the 'node show' and 'node edit' functions,
      however this method provides a quicker way of doing this and adds some validation
      checks to ensure that the specified environment exists.

    .EXAMPLE

      PS C:\> Invoke-POSHKnife node environment -name server-01.poshchef.com -env Oven

      This will attempt to move the specified node to the 'Oven' environment

  #>

  param (

    [string]
    # Name of the node that is being updated
    $name,

    [string]
    # Name of the environment the machine should be assigned to
    $environment
  )

  Write-Log -Message " "
  Write-Log -EVentId PC_INFO_0031 -extra ("Setting", "Node Environment")

  $required = New-Object System.Collections.ArrayList

  # check that the name and the environment have been set
  if ([String]::IsNullOrEmpty($name)) {
    $required.Add("name") | Out-Null
  }
  if ([String]::IsNullOrEmpty($environment)) {
    $required.Add("environment") | out-Null
  }

  # if the required array is not empty output an error message and return
  if ($required.count -gt 0) {
    Write-Log -LogLevel Error -EventId PC_ERROR_0034 -extra $required
    return
  }

  # Get the node that is being updated
  $node = Get-Node -name $name

  # continue if the node is not false
  if ($node -ne $false) {

    # check to see if the enviornment matches the one that is already set
    if ($node.chef_environment -ceq $environment) {
      Write-Log -EventId PC_WARN_0018 -extra @($name, $environment) -LogLevel Warn
      return
    }

    # Get a list of the environments to ensure that the one specified exists
    $environments = Get-Environment

    # perform a check to ensure that the named environment is known to the chef server
    # this must be a case sensitive check
    if ($environments.keys -cnotcontains $enviornment) {
      Write-Log -EventId PC_ERROR_0035 -extra $environment -LogLevel Error
      return
    }

    # As the environment is known modify the chef_environment in the node
    $node.chef_environment = $environment

    # Ensure the node is updated
    $splat = @{
      node = $node
      update = $true
    }

    Set-Node @splat
  }

}
