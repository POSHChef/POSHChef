
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

function Get-AbsoluteKeys {

  <#

  .SYNOPSIS
    Get an array of the the keys in a hashtable in dot notation

  .DESCRIPTION
    Given a hashtable, can be nested, return an array of the keys in dot notation.

    So given the following hashtable

      $table = @{
        fruit = @{
          apple = "green"
          banana = "yellow"
        }
        vegtable = @{
          brocolli = "green"
          carrot = @{
            colour = "orange"
          }
        }
      }

    This function would return an array of the keys, e.g.

      @(
        "fruit.apple"
        "fruit.banana"
        "vegatable.brocolli"
        "vegatable.carrot.colour"
      )

    This is used to determine the help text that needs to go into configuration files generated
    for POSHKNife and POSHChef

  #>

  [CmdletBinding()]
  param (

    [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)]
    [Hashtable]
    # The hashtable to analyse
    $config
  )

  # Create an array into which the keys will be added
  $reduced = New-Object System.Collections.ArrayList

  foreach ($key in $config.keys) {

    # if the current key is a hashtable then call the function again
    if ($config.$key -is [hashtable]) {
      $result = Get-AbsoluteKeys -config $config.$key

      foreach($item in $result) {
        $notation = "{0}.{1}" -f $key, $item
        $reduced.Add($notation) | Out-Null
      }


    } else {
      $reduced.add($key) | out-null
    }
  }

  # return the reduced keys to the calling function
  $reduced

}
