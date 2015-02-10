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


function vault_show {

    <#

    .SYNOPSIS
        Shows the specified items from a vault

    .DESCRIPTION


    .LINK
        https://github.com/Nordstrom/chef-vault


    #>

    param (

        [string]
        # Name of the vault to access
        $vault,

        [string[]]
        # Arry of names to get from the specified vault
        $name,

        [string[]]
        # properties to retrieved for each name
        $properties

    )

    Write-Log -Message " "
    Write-log -EventId PC_INFO_0031 -extra ("Retrieving", "Credentials")

    # esnure error thrown if no names are specified

    # Create an encoding object
    $encoding = New-Object System.Text.ASCIIEncoding

    # determine the mapping for the chef query
    $mapping = "data"

    # get a list of all the items in the specified vault
    
    $ids = Get-VaultItem -vault $vault -name $name

    foreach ($id in $ids.keys) {
        Write-Log -EventId PC_MISC_0000 -extra $id
        Write-Log -Message ("Username: {0}" -f $ids.$id.username) -indent 3 -fgcolour gray
        Write-Log -Message ("Password: {0}" -f $ids.$id.password) -indent 3 -fgcolour gray
    }

}   
