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


function node_edit {

    <#

    .SYNOPSIS
      Edit a node from an object or a file

    .DESCRIPTION
      When more than just the run list or the environment need to be modified
      this allows the modification of the noed using a file

      This plugin is intended to be used in conjunction with 'node show' which can, optionally,
      save a node to file.  The file would then be modified so that the correct
      attributes are assigned to it and this plugin used to upload the new information to
      the Chef server.

      If the node has been modified in memory and is an object this can be passed to the
      plugin as well.  This information will be used as is and uploaded to the chef server.

    .EXAMPLE

      PS C:\> Invoke-POSHKnife node edit -name base

      This will attempt to find the base role in the configured directory for roles in the chef-repo.
      It will automatically append the .json extension to the name so that the file can be found.
      By default the path would be '<CHEF_REPO>\roles\base.json'

    .EXAMPLE

      PS C:\> $node = POSHKnife node show -name server-01.poshchef.com
      PS C:\> $node.default.plugin = "node_edit"
      PS C:\> Invoke-POSHKnife node edit -name server-01.poshchef.com -node $node

      This uses the node show plugin to get the node fromt the server.  An attribute is then modified
      and this using this plugin the node is updated on the chef-server.


    #>

    [CmdletBinding()]
    param (

      [string]
      # Name of the node to update
      $name,

      [string]
      # Directory that the file should be located in.
      # This is applicable when the filename is not an absolute path
      # The default for this is the <BASEDIR>\nodes directory
      $folder = [String]::Empty,

      [string]
      # Filename of the role
      # By default this will be the name of the node with JSON extension
      $filename = [String]::Empty,

      [string]
      # The format of the file, by default this will be json
      $format = "json",

      # Ability to specify a node object which will allow the node to be updated
      # from a string or a hashtable
      $node = [String]::Empty

    )

    # Setup the mandatory parameters
    $mandatory = @{
      name = "Name of the node to update (-name)"
    }
    
    Confirm-Parameters -Parameters $PSBoundParameters -mandatory $mandatory

    if ([String]::IsNullOrEmpty($node)) {

      # if the filename is empty then set it to the name of the node
      if ([String]::IsNullOrEmpty($filename)) {
        $filename = "{0}.{1}" -f $name, $format
      }

      # check to see if the filename is absolute, if not prepend the nodes path
      $uri = $filename -as [System.Uri]
      if (!$uri.IsAbsoluteUri) {
        $filename = Join-path $script:session.config.paths.nodes $filename
      }

      # Now check to see if the file exists
      if (!(Test-path -Path $filename)) {
        Write-Log -EventId PC_ERROR_0029 -extra $filename -loglevel Error -stop
      }

      # read in the file as a raw string
      $data = Get-Content -Path $filename -Raw

      # build up the argument hash to pass to the function
      $splat = @{
          node = $data
          name = $name
          update = $true
      }

    } else {

      # set the argument information
      $splat = @{
        node = $node
        update = $true
      }

    }

    # Now call the set-node cmdlet to update the node on the server
    Set-Node @splat
}
