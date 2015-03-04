
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

data LocalizedData {

  ConvertFrom-StringData @'
Server=The Chef server to connect to when using POSHChef or POSHKnife
Node=Name of the node that is connecting to the server.  If using POSHKnife this is the client name
chef_repo=Path to the chef repository on the local filesystem.  This is where the cookbooks, roles, environments and databags are stored
apiversion=The version of the API to use when communicating with the Chef server
logs.keep=The number of POSHChef client run log directories to keep
client_key=Path to the client key that permits access to the Chef server
environment=Environment that this node belongs to.  This will override the setting on the server
mof.keep=Number of MOF files to keep if archiving is turned on
mof.archive=Boolean value to state if the MOF files should be archived at all
skip=String array of operations that should be skipped when running POSHChef
'@
}


function Get-ConfigurationHelp {

  <#

  .SYNOPSIS
    Returns a header block of help about the coniguration items

  .DESCRIPTION
    Given the list of options that are being set int he configuration file, return
    a string of text that will be placed the comments in the configuration file

  #>

  [CmdletBinding()]
  param (

    [Parameter(Mandatory=$true)]
    [hashtable]
    # Hashtable containing the configuration that has been defined
    $config,

    [Parameter(Mandatory=$true)]
    [string]
    # Type of configuration file being created
    $type
  )

  # Create an array of the friendly names
  $friendly = @{
    client = "POSHChef"
    knife = "POSHKnife"
  }

  # create a string builder to add the information to
  $sb = New-Object System.Text.StringBuilder

  # add in the delimiters for the header
  $sb.AppendLine("<#") | Out-Null

  # Add in a title header to show that configuration file type
  $sb.AppendLine("") | Out-Null
  $sb.AppendLine(("{0} Configuration file") -f $friendly.$type) | Out-Null

  # Get the absolute keys for the hashtable
  $absolutekeys = Get-AbsoluteKeys -config $config

  # Iterate around the keys so that the help can be built up
  foreach ($key in $absolutekeys) {

    # get the help
    $help = $LocalizedData.$key

    # continue onto the next loop if it is empty
    if ([String]::IsNullOrEmpty($help)) {
      continue
    }

    # Write out the key and then the help for the key
    $sb.AppendLine("") | Out-Null
    $sb.AppendLine($key) | Out-Null
    $sb.AppendLine(($LocalizedData.$key)) | Out-Null

  }

  # Ensure that the help is delimited
  $sb.AppendLine("#>") | Out-Null
  $sb.AppendLine("") | Out-Null

  # Return the string to the calling function
  $sb.ToString()

}
