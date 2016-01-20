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

function server_version {
  
  <#
  
  .SYNOPSIS
    Return information about the server such as the version
    
  .DESCRIPTION
    When working with different chef servers it is sometimes necessary to understand the version
    of the server and other information such as the API version.
    
    This plugin returns the information about the server that it has been configured to use
  
  #>
  
  Write-Log -Message ' '
  Write-Log -EVentId PC_INFO_0031 -extra ('Server', 'Version')
  
  # Make a call to the server so that the headers can be sought
  $response = Invoke-ChefQuery -uri '/data'

  # Return the version of the API as an object
  $major, $minor, $build = $script:session.apiversion -split "\."
  $version = New-Object PSObject -Property @{
    major = $major
    minor = $minor
    build = $build
  }
  
  # Add a ToString method so that the it is displayed properly in a console or when explicity called
  $version | Add-Member -MemberType ScriptMethod -Name ToString -Value { "{0}.{1}.{2}" -f $major, $minor, $build } -Force
  
  # Determne if the output of this is to be sent to the console or the pipeline
  if ($PSCmdlet.MyInvocation.Line.Trim().startswith('$')) {
    $version
  } else {
    $version.ToString()
  }
}
