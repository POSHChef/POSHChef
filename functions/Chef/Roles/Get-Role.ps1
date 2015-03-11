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


function Get-Role {

    <#

    .SYNOPSIS
      Get all roles or a named one from the Chef server

    #>

    [CmdletBinding()]
    param (

      [string]
      # Name of the role to retrieve
      $name
    )

    # If in debug mode, show the function currently in
    Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

    # Start to build up the uri that is required to pass to chef
    $uri_parts = new-Object System.Collections.ArrayList
    $uri_parts.Add("/roles") | Out-Null

    # if the name has been specified add it to the array
    if (![String]::IsNullOrEmpty($name)) {
      # build up the path to desired item
      $uri_parts.Add($name) | Out-Null
    }

    # Call the ChefQuery to get the runlist for the role
    $uri = $uri_parts -join "/"
    $role = Invoke-ChefQuery -path $uri

    # return the role to the calling function
    $role
}
