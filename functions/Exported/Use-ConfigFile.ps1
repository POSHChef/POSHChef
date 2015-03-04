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

function Use-ConfigFile {

  <#

  .SYNOPSIS
    Helper function to set or remove the environment variable for POSHChef or POSHKnife

  .DESCRIPTION
    POSHChef and POSHKnife both support setting an environment variable with the
    path to the configuration file that should be used for that operation.

    This cmdlet provides a simple helper method to assist in this setup

  #>

  [CmdletBinding()]
  param (

    [Parameter(Mandatory=$true)]
    [ValidateSet("chef", "knife")]
    [string]
    # Denotes the operation that is being set and thus the relevant environment variable
    $type,

    [Parameter(Mandatory=$true)]
    [string]
    # Path to the configuration file to set in the environment variable
    $path,

    [switch]
    # Specify if the environment variable should be removed or not
    $remove

  )

  # Set the log parameters so that the system can find the help file
  Set-LogParameters -helpfile ("{0}\..\..\lib\POSHChef.resources" -f $PSScriptRoot)

  # Define a hashtable that contains the name of the environment variable to set
  $env_name = @{
    chef = "POSHCHEF_CONFIG_FILE"
    knife = "POSHKNIFE_CONFIG_FILE"
  }

  # Determne the path to the environment var
  $env_path = "Env:{0}" -f $env_name.$type

  # determine the operation to run based on whether remove has been set
  if ($remove) {

    Write-Log -EventId PC_INFO_0065 -extra $type

    # Determine if the environment variable exists
    if (Test-Path -Path $env_path) {
      Remove-Item -Path $env_path
    } else {
      Write-Log -LogLevel Warn -EventId PC_WARN_0017 -extra $env_name.$type
    }

  } else {

    Write-Log -EventId PC_INFO_0064 -extra $type

    # Check that the file that has been specified exists
    if (Test-Path -Path $path) {
      $expr = '${0} = "{1}"' -f $env_path, $path

      # Invoke the expression to set it
      Invoke-Expression $expr
    }

  }
}
