
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

<#

  .SYNOPSIS
  Pester test file to test the RemoteFile Resource for DSC

  .DESCRIPTION
  The tests will ensure that an item of each different type, e.g. local, UNC, HTTP and FTP can be copied
  Where appropriate credentials will be provided to test this side of things as well


#>

# Source the module file and read in the functions
$TestsPath = $MyInvocation.MyCommand.Path
$script = (Split-Path -Leaf $TestsPath).Replace(".Tests.ps1", ".psm1")
$module = "{0}\{1}" -f (Split-Path -Parent -Path $TestsPath), $script
$code = Get-Content $module -raw
Invoke-Expression $code

# Mock functions that come from other modules
function Write-Log(){}
function Update-Session(){}
function Get-Configuration(){}
function Set-LogParameters(){}

# Ensure required functions are available
. "$PSScriptRoot\..\..\functions\exported\Set-Notification.ps1"

# Set the network target and the subnet mask for which the new route will be added
$target = "192.168.122.0"
$mask = "255.255.255.0"

# Get the current default gateway which routes will be added
$dgw = (Get-wmiObject Win32_networkAdapterConfiguration | ?{$_.IPEnabled}).DefaultIPGateway | Out-String

Describe 'POSHChef_NetworkRouteResource' {

  Context 'route does not exist' {

    it "tests the route does not exist" {

      $result = (Test-TargetResource -Destination $target -Mask $mask -Gateway $dgw -Ensure "Present")

      $result | Should be $false
    }

    it "adds the route" {

      Set-TargetResource -Destination $target -Mask $mask -Gateway $dgw -Ensure "Present"

      $result = (Test-TargetResource -Destination $target -Mask $mask -Gateway $dgw -Ensure "Present")

      $result | Should be $true
    }

  }

  Context "route does exist" {

    it "tests the route does exist" {

      $result = (Test-TargetResource -Destination $target -Mask $mask -Gateway $dgw -Ensure "Absent")

      $result | Should be $true

    }

    it "removes the route" {

      Set-TargetResource -Destination $target -Mask $mask -Gateway $dgw -Ensure "Absent"

      $result = (Test-TargetResource -Destination $target -Mask $mask -Gateway $dgw -Ensure "Absent")

      $result | Should be $false

    }
  }
}
