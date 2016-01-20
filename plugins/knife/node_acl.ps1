
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


function node_acl {
  
  <#
  
  .SYNOPSIS
    Plugin to allow the ACL of a node to be updated in a Chef 12 environment
    
  .DESCRIPTION 
    When a node is created in Chef 12 clients do not have access to it for updates.  This means
    that at the end of a POSHChef it is not possible to update the node attributes on the server.
    
    This plugin will allows the modification of the acl on the named node
  
  #>

  [CmdletBinding()]
  param (

    [string[]]
    # Name of the node(s) to create
    $name,
    
    [string]
    # Name of the group that needs to have its ACL updated on the node
    $groupname = 'clients', 
    
    [string[]]
    # Permissions that this group should have on the named node
    $permissions,

    [string]
    # The operation to be performed.  Add or remove the specified settings to the node
    # Default: add
    $operation = 'add'
  )
  
  # Setup the mandatory parameters
  $mandatory = @{
    name = 'Node that needs to have its ACL updated (-name)'
    groupname = 'Name of the group that will have the permission modified (-groupname)'
    permissions = 'String array of permissions that should be applied to the group (-permissions)'
  }

  	# Ensure that the default values for the parameters have been set
	foreach ($param in @('groupname')) {
		if (!$PSBoundParameters.ContainsKey($param)) {
			$PSBoundParameters.$param = (Get-Variable -Name $param).Value
		}
	}

  Confirm-Parameters -Parameters $PSBoundParameters -mandatory $mandatory
  
  # Check that the operation is add or remove
  if (@('add', 'remove') -notcontains $operation) {
    Write-Log -EventId PC_ERROR_0039 -LogLevel ERROR -stop
  }

  Write-Log -Message ' '
  Write-Log -EVentId PC_INFO_0031 -extra ('Node', 'ACL')
  
  # Iterate around the names that have been supplied for the nodes that need to be updated
  foreach ($id in $name) {
    
    Write-Log -EventId PC_MISC_0000 -extra $id

    # Build up the URL to call to get the current ACL list for the node
    $splat = @{
      uri = '/nodes/{0}/_acl' -f $id
    }
    
    $acl = Invoke-ChefQuery @splat

    # continue onto the next iteration if an error has occurred
    if ($acl.containskey('error')) {
        continue
    }

    # Set the hashtable up for the data to be sent back to the server
    $data = @{}

    # Modify the ACL, if so required, based on the passed parameters
    foreach ($permission in $permissions) {
    
        # set a flag to state if the permission has changed
        $modified = $false

        $actors = [System.Collections.ArrayList] $acl.$permission.actors
        $groups = [System.Collections.ArrayList] $acl.$permission.groups

        # Based on the operation determine if the group should be added or removed
        switch ($operation) {
            'add' {
                if ($groups -notcontains $groupname) {
                    $groups.Add($groupname) | Out-Null
                    $modified = $true
                    Write-Log -EventId PC_MISC_0001 -extra ('Adding {0} permission to group: {1}' -f $permission, $groupname)
                }
            }

            'remove' {
                if ($groups -contains $groupname) {
                    $groups.Remove($groupname) | Out-Null
                    $modified = $true
                    Write-Log -EventId PC_MISC_0001 -extra ('Removing {0} permission from group: {1}' -f $permission, $groupname)
                }
            }
        }

        if ($modified) {
            $data.$permission = @{
                actors = $actors
                groups = $groups
            }
        }
    }


    # Prepare the hashtable to update the permissions on the server
    $splat = @{
      uri = '/nodes/{0}/_acl/update' -f $id
      method = 'PUT'
      data = $data
    }

    $response = Invoke-ChefQuery @splat
  }
}
