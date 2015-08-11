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

function Get-RoleAttributes {

  <#

  .SYNOPSIS
    Using the role list get the attributes

  .DESCRIPTION
    Function to reverse the order of the roles so that the attributes are resolved in such
    a way that the last role wins.

  #>

  # If in debug mode, show the function currently in
  Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

  # Get the list of roles from the session and reverse it
  $roles = $script:session.roles
  [array]::Reverse($roles)

  # Remove duplicates in the roles array
  $roles = $roles | Select -Unique

  # Iterate around the roles
  foreach ($role in $roles) {

    if ($role -match "(.*)?\[(.*)\]") {

      # get the run list type and the name of the item
      $role_name = $matches[2]

      # Call the function to get the named role
      $role = Get-Role -name $role_name

      # if the role is false do not merge
      if ($role -ne $false) {

        # The attributes for the role need to be merged with the ones already retrieved
        # these are currently in the session object
        # Attributes of the same name in different roles will be overridden
        # The last role to have the same setting will win
        $merged = Merge-Hashtables -primary $role.default_attributes -secondary $script:session.attributes.roles
        $script:session.attributes.roles = $merged
      }
    }
  }

  # Set the list of roles in the session
  $script:session.roles = $roles

}
