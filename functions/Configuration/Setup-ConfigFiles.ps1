
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

function Setup-ConfigFiles {

  <#

  .SYNOPSIS
    Function to create the necessary configuration files for POSHChef or POSHKnife

  .DESCRIPTION
    The exported cmdlets that use this function, Intialize-POSHChef and Initialize-POSHKnife,
    are the useable commands from the module.

    This cmdlet is the engine that generates the necssary files.  By stating the context of the
    file that is being created, or modified it will manage the configuration information

  #>

  [CmdletBinding()]
  param (

    [Parameter(Mandatory=$true)]
    [ValidateSet("client", "knife")]
    [string]
    # Type of configuration file being managed
    $type,

    [string]
    # Name of the configuration file to create
    $name = [String]::Empty,

    [hashtable]
    # Hashtable of configuration that has been set by the public function
    $userconfig,

    [string]
    # Sub folder for keys to be stored in
    $keydir,

    [switch]
    # Force the overwriting of an existing file
    $force,

    [switch]
    # If specified the key is not copied anywehere and the path is set to the same
    # as the source
    $nocopykey,

    [switch]
    # Specify if the configuration file should be written out in Strict
    # mode.  This adds type hintng to the data file
    $strict,

    [string]
    # Url of the supermarket URL to use
    $supermarket_url

  )

  # If in debug mode, show the function currently in
  Write-Log -IfDebug -EventId PC_DEBUG_0017 -extra $MyInvocation.MyCommand

  # Determine if the name of the configuration file has been set
  # If not base it off the type of the file that is being managed
  if ([String]::IsNullOrEmpty($name)) {
    $name = $type
  }

  # Ensure that the the name ends in .psd1
  if (!$name.EndsWith(".psd1")) {
    $name = "{0}.psd1" -f $name
  }

  # Now build up the full path to the configuration file
  $config_filepath = Join-Path $script:session.config.paths.conf $name

  # Determine if the file already exists
  $exists = Test-Path -Path $config_filepath

  # if the path does exist then ask the operator if the file should be overwritten or not
  if ($exists -and !$force) {
    $question = "File '{0}' already exists, do you wish to overwrite it? (Yes/No)" -f $config_filepath
    [ValidateSet('Yes','No')] $Answer = Read-Host $question

    # if the answer is not then exit
    if ($answer -ieq "no") {
      Write-Log -EventId PC_MISC_0001 -Extra "Not overwriting existing file" -stop
    }
  }

  # determine the key type that has been passed, e.g. client or validation
  # and then copy it to the correct location
  if (![String]::IsNullOrEmpty($userconfig.client_key)) {
    $key_type = "client_key"
    $source = $userconfig.client_key
  } else {
    $key_type = "validation_key"
    $source = $userconfig.validation_key
  }

  # Check that the source is a valid path, if not throw an error
  if ([String]::IsNullOrEmpty($source)) {
    Write-Log -Error -EventId PC_ERROR_0028 -Stop
  }

  # Based on the scheme of the source copy it to a temporary locaton
  # This is so that the checksum can be checked to determine if the file is different
  # from one that already exists
  $uri = $source -as [System.URI]
  switch -Wildcard ($uri.scheme) {
    "http*" {

      # Determien the path that the file will be donlowad to
      $source = "{0}\{1}" -f $script:session.config.paths.file_cache_path, (Split-Path -Leaf -Path $source)
      Invoke-WebRequest -uri $uri -outfile $source -usebasicparsing

    }
  }

  # Get the checksum of the source and the target to test if the files are the same or not
  $checksums = @{
    source = Get-Checksum -path $source
    target = [String]::Empty
  }

  # copy the key from its present location, unless already in the correct path, to where
  # it shuld be stored
  # determine the target location
  if ($nocopykey) {
    $target = $source
  } else {
    $target = [System.IO.Path]::Combine($script:session.config.paths.conf, $keydir, (Split-Path -Leaf -Path $source))
  }

  # check to see if the target already exists, if it is does and not running force ask the
  # operator for a descion
  $key_exists = Test-Path -Path $target
  if ($key_exists -and !$force -and !$nocopykey) {

    # Set the target chefksum
    $checksums.target = Get-Checksum -path $target

    # if the files are not the same then ask the question if they should be overwritten
    if ($checksums.source -ne $checksums.target) {

      $question = "Key file '{0}' already exists, do you wish to overwrite it? (Yes/No)" -f $target
      [ValidateSet('Yes','No')] $Answer = Read-Host $question

      if ($answer -ieq "no") {
        Write-Log -EventId PC_MISC_0001 -Extra "Not overwriting existing key file" -stop
      }
    }
  }

  # Copy the source file to the target if the checksums are different
  if ($checksums.source -ne $checksums.target -and !$nocopykey) {

    # Ensure the parent of the target exists
    $parent = Split-Path -Parent -Path $target
    if (!(Test-Path -Path $parent)) {
      New-Item -type directory -Path $parent | Out-Null
    }

    Write-Log -EventId PC_INFO_0027 -Extra $target
    Copy-Item -Path $source -Destination $target -Force
  }


  # create the hashtable that will be written out to disk
  # set the common parameters that both knife and chef have
  $configuration = @{
    server = $userconfig.server
    apiversion = $userconfig.apiversion
    node = $userconfig.node
    logs = @{
      keep = $userconfig.logs.keep
    }
    $key_type = $target
  }

  # switch on the type of file that is being generated so that the extra information
  # can be added if it has been specified
  switch ($type) {

    "client" {

      # Set the environment for the machine
      $configuration.environment = $userconfig.environment

      # add in the nuget source if it has been specified
      if (![String]::IsNullOrEmpty($userconfig.nugetsource)) {
        $configuration.nugetsource = $userconfig.nugetsource
      }

      # determine if there are any parts of the POSHChef that should be skipped
      if (![String]::IsNullOrEmpty($userconfig.skip)) {
        if ($userconfig.skip.count -gt 0) {
          $configuration.skip = @($userconfig.skip)
        }
      }

      # add in the mof file settings if they have been specified
      if (![String]::IsNullOrEmpty($userconfig.mof)) {
        $configuration.mof = @{}

        # now add in the values if they are specified
        if (![String]::IsNullOrEmpty($userconfig.mof.keep)) {
          $configuration.mof.keep = $userconfig.mof.keep
        }

        if (![String]::IsNullOrEmpty($userconfig.mof.archive)) {
          $configuration.mof.archive = $userconfig.mof.archive
        }
      }
    }

    "knife" {

      # Set the path to the chefrepo
      $configuration.chef_repo = $userconfig.chef_repo

      # Set the URl to use for the supermarket URL
      $configuration.supermarket_url = $userconfig.supermarket_url

    }
  }

  # create an array for the objects
  $contents = New-Object System.Collections.ArrayList

  # Get the help for the configuration file
  $help_header = Get-Configurationhelp -config $configuration -type $type
  $contents.Add($help_header) | Out-Null

  # Get the configuration object as a string that can be written out to a file
  $config_psd1 = ConvertTo-PSON -Object $configuration -Layers 5 -Depth 10 -Strict:$strict
  $contents.Add($config_psd1) | Out-Null

  # Write out the configuration to the file
  Set-Content -Path $config_filepath -Value ($contents -join "`n") | Out-Null
}
