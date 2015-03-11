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

function Upload-ChefItem {

  <#

    .SYNOPSIS
      Given an object or the name of an object upload to the chef server

    .DESCRIPTION
      This function is responsible for uploading items to the chef server, whether
      it is from a file or from an object.

    .NOTES
      This function is not used to upload a cookbook to the server as that has
      many more parts.

  #>

  [CmdletBinding()]
  param (

    [Parameter(ParameterSetName="object")]
    # Chef item object to upload to the server
    $InputObject,

    [Parameter(ParameterSetName="file")]
    [string]
    # Name of the item being uploaded
    $name,

    [Parameter(ParameterSetName="file")]
    [ValidateSet("environment", "role")]
    [string]
    # Type of item that is being upload, this is so that the
    # correct URI can be generated
    $chef_type,

    [Parameter(ParameterSetName="file")]
    [string]
    # Directory that the file should be saved in.
    # This is applicable when the filename is not an absolute path
    $folder = [String]::Empty,

    [Parameter(ParameterSetName="file")]
    [string]
    # Filename that contents should be saved in
    # By default this will be the name of the node with JSON extension
    $filename = [String]::Empty,

    [Parameter(ParameterSetName="file")]
    [string]
    # The format that the file should be written out as
    # By default this is as a PSON object
    $format,

    [string[]]
    # String array of items that already exist on the server
    $list

  )

  # If in debug mode, show the function currently in
  Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

  # Determine how update the item whether it is from the inputobject or the file
  switch ($PSCmdlet.ParameterSetName) {
    "object" {
      $chef_item = $InputObject
      $chef_type = $chef_item.chef_type
      $id = $chef_item.name
      $filename = "object"
    }

    "file" {

      if ([String]::IsNullOrEmpty($format)) {
        $format = "json"
      }

      # determine if the filename is empty, if it is then add the node name to it
      if ([String]::IsNullOrEmpty($filename)) {
        $filename = $name
      }

      if (!$filename.endswith((".{0}" -f $format))) {
        $filename = "{0}.{1}" -f $filename, $format
      }

      # if the folder is empty then use the one from the configuration
      if ([String]::IsNullOrEmpty($folder)) {
        $folder = "{0}\{1}s" -f $script:session.config.chef_repo, $chef_type
      }

      # Determine if the $filename is absolute
      $uri = $filename -as [system.uri]
      if (!$uri.IsAbsoluteUri) {
        $filename = "{0}\{1}" -f $folder, $filename
      }

      # Check that the filename exists, if it does not return to the calling function
      if (!(Test-Path -Path $filename)) {
        Write-Log -EventId PC_WARN_0015 -LogLevel Warn -extra ($name, $filename)
        return
      }

      # Read in the file
      $chef_item = Get-Content -Path $filename -Raw

      # Determine the id of the item as it might be a filename
      $id = [System.IO.Path]::GetFileNameWithoutExtension($filename)
    }
  }

  # Build up the hashtable of arguments so that the item can be updated
  $splat = @{
    method = "POST"
    uri = "/{0}s" -f $chef_type
    data = $chef_item
  }

  # Determine if the item exists on the server or not as this affects the
  # HTTP METHOD and the URI
  $action = "Adding"
  if ($list -ccontains $id) {
    # it already exists so this is an update
    $splat.method = "PUT"
    $splat.uri = "{0}/{1}" -f $splat.uri, $id
    $action = "Updating"
  }

  Write-Log -EventId PC_MISC_0000 -extra $id
  Write-Log -EventId PC_INFO_0030 -extra ($action, $chef_type, $filename)

  # Perform the action of updatung the server
  $result = Invoke-ChefQuery @splat

}
