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

# Test script for Clean-Cookbooks
# Ensures that obsolete files are removed as well as empty directories

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

# Only functions that already exist can be Mocked
# Stub out Write-Log function so that it can be mocked
function Write-Log(){}

# Source the file under test
. "$here\$sut"

# Create a temporary cookbook for testing


Describe "Get-CookbookFiles" {

  # Define the session variable with the path the cache path
  $script:session = @{
    config = @{
      paths = @{
        file_cache_path = $TestDrive
      }
    }
  }

  # Build up an array of the files that should be in the cookbook directory
  $files = @(
    "{0}\cookbooks\FooBar\metadata.rb" -f $TestDrive
    "{0}\cookbooks\FooBar\.gitignore" -f $TestDrive
    "{0}\cookbooks\FooBar\recipes\default.rb" -f $TestDrive
    "{0}\cookbooks\FooBar\files\default\POSHChef\FooBar\metadata.psd1" -f $TestDrive
  )

  # Craete the files
  foreach ($file in $files) {

    $parent = Split-Path -Path $file -Parent
    if (!(Test-Path -Path $parent)) {
      new-Item -type directory -path $parent | Out-Null
    }

    New-Item -type file -path $file | Out-Null
  }

  # Copy the poshchefignore file from the skeleton directory
  $poshchefifgnore_file = "{0}\..\..\..\skeleton\cookbook\poshchefignore" -f $here
  $destination = "{0}\cookbooks\FooBar\poshchefignore" -f $TestDrive
  Copy-Item -Path $poshchefifgnore_file -Destination $destination

  # set the expected count of files
  $expected = 3

  it ("will only find {0} files the rest are ignored" -f $expected) {

    $files = Get-CookbookFiles -path ("{0}\cookbooks\FooBar" -f $TestDrive)

    $files.count -eq $expected | should be $true
  }


}
