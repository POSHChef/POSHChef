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

function Save-ChefItem {

  <#

    .SYNOPSIS
      Given a chef item save it out to a file

    .DESCRIPTION
      Whether it is for backing up or to edit the attributes of a chef item
      it is sometimes necessary to write out the entity to a file.  This function
      performs this operation.

      It is primairly used in conjunction with a knife plugin, such as 'node_show'
      for example

  #>

  [CmdletBinding()]
  param (

    [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)]
    # Object that should be written out to disk
    $InputObject,

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
    $format

  )

  # If in debug mode, show the function currently in
  Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

  # If the inputobject is false return
  if (!$InputObject) {
    return
  }

  # Determine the chef type from the input object
  $chef_type = $InputObject.chef_type

  if ([String]::IsNullOrEmpty($format)) {
    $format = "json"
  }

  # determine if the filename is empty, if it is then add the node name to it
  if ([String]::IsNullOrEmpty($filename)) {
    $filename = "{0}.{1}" -f $InputObject.name, $format
  }

  # if the folder is empty then use the one from the configuration
  if ([String]::IsNullOrEmpty($folder)) {
    $folder = $script:session.config.paths.$chef_type
  }

  # Determine if the $filename is absolute
  $uri = $filename -as [system.uri]
  if (!$uri.IsAbsoluteUri) {
    $filename = Join-Path $folder $filename
  }

  # Depending on the format type convert the node accordinly
  switch ($format) {
    "pson" {
      $data = ConvertTo-PSON -Object $InputObject -Depth ([int]::MaxValue) -Layers 9
    }
    "json" {
      $data = ConvertTo-JSON -InputObject $InputObject -Depth ([int]::MaxValue)
    }
    default {
      Write-Log -EventId PC_MISC_0001 -extra "Unkown format, please state 'json' or 'pson'"
    }
  }

  # Write out the contents of the file
  if (![String]::IsNullOrEmpty($data)) {
    Set-Content -path $filename -value $data
  }

  # return the path of the file to the calling function
  $filename
}
