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


function vault_create {

    <#

    .SYNOPSIS
        Creates a new vault and associated item

    #>

    param (

        [string]
        # Name of the vault
        $vault,

        [string]
        # Name of the item to create
        $name,

        [string]
        # Query to execute to find all the clients that are able to access the password
        $query,

        [string[]]
        # String array of administrators that are also able to see the password
        $administrators,

        [object]
        # Object containing the username and password that need to encrypted
        $item
    )

    Write-Log -Message " "
    Write-log -EventId PC_INFO_0031 -extra ("Creating Vault Item", "")

    # Check to see if the item already exists, if it does then exit and give meaningful information
    $exists = Invoke-ChefQuery -Path ("/data/{0}/{1}" -f $vault, $name) -Passthru

    # if the response is not 404 then output message
    if ($exists.statuscode -ne 404) {
        Write-Log -ErrorLevel -EventId PC_ERROR_0023 -extra ($vault, $name) -stop
    }

    # Perform a search against the Chef server using the query that has been supplied
    # This is to get the node public keys
    $path = "/search/node?q={0}" -f [System.URI]::EscapeDataString($query)
    $clients = Invoke-ChefQuery -Path $path

    # Determine how many results have been returned and throw warning if none
    if ($clients.total -eq 0) {
        Write-Log -WarnLevel -EventId PC_WARN_0010
    } else {
        Write-Log PC_MISC_0000 -extra ("{0} clients found" -f $clients.total)
    }

    # Iterate around the administrators that have been supplied and get their information
    $admins = @()
    foreach ($administrator in $administrators) {
        $admins += Invoke-ChefQuery -Path ("/users/{0}" -f $administrator)
    }

    Write-Log PC_MISC_0000 -extra ("{0} administrators found" -f $admins.count)

    # set the data that is to be encrypted
    # this needs to be set as a json string with the onject item json_wrapper, this is to maintain compatibilty
    # with chef-vault
    $username = @{json_wrapper = $item.username} | ConvertTo-Json | Out-String
    $password = @{json_wrapper = $item.password} | ConvertTo-Json | Out-String

    # perform the encyption on the data that has been supplied
    # the function will return an array of the encypted data in the same order that it was passed to the function
    # the key and the IV are passed back as well
    $encryption = Invoke-AESEncrypt -data @($username, $password)

    # a databag item for the keys now needs to be created
    # create the stub of a the keys item
    $keys_item = @{
        admins = @($admins | Foreach-Object { $_.name })
        clients = @($clients.rows | Foreach-Object { $_.name })
        id = "{0}_keys" -f $name
        search_query = $query
    } 

    # now iterate around the clients to get the RSA public key and use it to encrypt the AES key
    foreach ($client in $clients.rows) {

        # perform a chef query for the node to get the public key
        $client_detail = Invoke-ChefQuery -Path ("/clients/{0}" -f $client.name)

        # encrypt the data for this client using the public key and add to the keys_item
        $cypher = Invoke-Encrypt -pem $client_detail.public_key -data $encryption.key

        # set the cypher to contain line feeds so it is compatible with chef
        $keys_item.$($client.name) = ($cypher -split "(.{60})" | Where-Object {$_}) -join "`n"
    }

    # iterate around the admins and add each one of these to the object as well
    foreach ($admin in $admins) {

        # add the current admin and an encryption of the key
        $keys_item.$($admin.name) = Invoke-Encrypt -pem $admin.public_key -data $encryption.key
    }

    # craete the actual item containing the username and password information
    $vault_item = @{
        id = $name
        password = @{
            cipher = "aes-256-cbc"
            version = 1
            encrypted_data = [System.Convert]::ToBase64String($encryption.encrypted[1])
            iv = [System.Convert]::ToBase64String($encryption.iv)
        }
        username = @{
            cipher = "aes-256-cbc"
            version = 1
            encrypted_data = [System.Convert]::ToBase64String($encryption.encrypted[0])
            iv = [System.Convert]::ToBase64String($encryption.iv)
        }

    }

    $enc = new-object system.text.asciiencoding

    # Now upload both the databag items
    $result = Invoke-ChefQuery -Method POST -Path ("/data/{0}" -f $vault) -data $keys_item
    $result = Invoke-ChefQuery -Method POST -Path ("/data/{0}" -f $vault) -data $vault_item
}
