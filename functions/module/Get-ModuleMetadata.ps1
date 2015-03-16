
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


function Get-ModuleMetadata {

  <#

  .SYNOPSIS
    Function to set the module information in the session

  .DESCRIPTION
    This function is designed to be called by the PowerSHell module file

    All it will do is set the module metadata data in the session variable so that it
    can be used elsehwere in the module

    The items set by this function are

    - Name
    - Version

    The Path has already been set by the module file

  #>

  # Set the name of the module
  $script:session.module.name = $MyInvocation.MyCommand.ModuleName

  # Work out the path to the PSD1 file and if it exists set the version number
  $datafile = Join-Path $script:session.module.path ("{0}.psd1" -f $script:session.module.name)

  if (Test-Path -Path $datafile) {

    # read in the contents of the datafile
    $module_data = Invoke-Expression (Get-COntent -Path $datafile -Raw)

    # if the version is not null set it
    if (![String]::IsNullOrEMpty($module_data.ModuleVersion)) {
      $script:session.module.version = $module_data.ModuleVersion
    } else {
      $script:session.module.version = "0.0.0"
    }

  } else {

    # no file can be found so set a default version
    $script:session.module.version = "Not Versioned"
  }

}
