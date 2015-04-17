
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

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

function Write-Log(){}

# Include functions that are required for the succesful operation of the test
. "$PSScriptRoot\..\Configuration\Get-ConfigurationHelp.ps1"
. "$PSScriptRoot\..\Exported\Get-Checksum.ps1"
. "$PSScriptRoot\..\Miscellaneous\Get-Base64.ps1"
. "$PSScriptRoot\..\Miscellaneous\Get-AbsoluteKeys.ps1"
. "$PSScriptRoot\..\Miscellaneous\ConvertTo-PSON.ps1"

. "$here\$sut"

Describe "Setup-ConfigFiles" {

  # Mock the Write-Log function and do nothing
  # This is in case the Logging module is not vailable
  Mock Write-Log -MockWith { }

  # Create a file that will act as an attribute file
  # Setup -File "cache\attributes.psd1" `
  # Get the PSDrive and therefore the root so that the full path can be used
  $PSDriveName = "TestDrive"
  $PSDrive = Get-PSDrive -Name $PSDriveName

  # Set the configuration directory
  $script:session = @{
    config = @{
      paths = @{
        conf = Join-Path $PSDrive.Root "conf"
      }
    }
  }

  # Create a file to represent the client_key
  $client_key = Join-Path $PSDrive.Root "client.pem"
  Set-Content -Path $client_key -Value "This is the client key for Chef"

  $target_client_key = "{0}\{1}" -f $script:session.config.paths.conf, (Split-Path -Path $client_key -Leaf)

  New-Item -type directory -path $script:session.config.paths.conf | out-null

  # build up the user config
  $userconfig =  @{
    server = "https://manage.chef.io/organizations/acme"
    node = "tests"
    client_key = $client_key
    logs = @{
      keep = 20
    }
    environment = "_default"
    apiversion = "12.0.2"
  }

  # Create the hashtable of arguments to pass to the script
  $splat = @{
    type = "client"
    userconfig = $userconfig
  }

  # Set the path to the target configuration file
  $target_config_file = "{0}\client.psd1" -f $script:session.config.paths.conf

  Setup-ConfigFiles @splat

  It "Given a Chef configuration will create a file" {

    Test-Path -Path $target_config_file | Should be $true

  }

  It "Generates the file correctly" {

    # Get the contents of the generated file and turn into JSON so that the
    # objects can be easily compared
    $content = Get-Content -Path $target_config_file -Raw
    $generated = Invoke-Expression $content | ConvertTo-Json

    # Build up the expected object
    $expected = [ordered] @{
      client_key = $target_client_key
      server = $userconfig.server
      logs = @{
        keep = $userconfig.logs.keep
      }
      environment = $userconfig.environment
      node = $userconfig.node
      apiversion = $userconfig.apiversion
    } | ConvertTo-Json

    # Now compare the two objects
    $generated -eq $expected | Should be $true

  }

  It ("Copies the client key to the correct location - {0}" -f $target_client_key) {

    (Test-Path -Path $target_client_key) -and (Test-Path -Path $client_key) | Should be $true

  }


}
