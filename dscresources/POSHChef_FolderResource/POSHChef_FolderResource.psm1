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

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$path
	)

	# Define the hashtable to return to the calling function
	$returnValue = @{}

	# Determine if the destination path exists, this will set the Ensure parameter in the
	# return value
	if (Test-Path -Path (_Manage-Folder -path $path -test)) {
		$returnValue.Ensure = "Present"
	} else {
		$returnValue.Ensure = "Absent"
	}

	# return the hashtable to the calling function
	$returnValue

}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$path,

		[System.String]
		$permissions,

		[System.String]
		$share,

		[System.String]
		$acl,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

		[System.String[]]
		$Notifies,

		[System.String]
		$NotifiesServicePath,

		[System.Boolean]
		$Reboot = $false
	)

	# If the ensure is "present" then make sure that the folder exists
	if ($Ensure -ieq "present") {

		# Call function to make sure that the folder exists
		$path_exists = _Manage-Folder -path $path | Out-Null

		# If there are permissions set then call the folder permissions
		if (![String]::IsNullOrEmpty($permissions) -and $path_exists -ne $false) {
			_Manage-FolderACL -path $path -permissions ($permissions | ConvertFrom-JsonToHashtable)
		}

		# If the share is not null or empty then add the share
		if (![String]::IsNullOrEmpty($share) -and $path_exists -ne $false) {
			_Manage-FolderShare -path $path -name $share
		}

		# If there is an acl passed to the function then set the folder share permissions
		if (![String]::IsNullOrEmpty($acl) -and $path_exists -ne $false) {
			_Manage-FolderShareACL -name $share -permissions ($acl | ConvertFrom-JsonToHashtable)
		}
	}

	if ($Ensure -ieq "absent") {

		# Before the directory is removed, if it is exists, check to see if there
		# are any shares associated with it
		_Manage-FolderShare -path $path -remove | Out-Null

		_Manage-Folder -path $path -remove | out-null
	}

	# Notify any services of this change
	# Set the DSC resource to reboot the machine if set
	if ($Reboot -eq $true) {
		$global:DSCMachineStatus = 1
	} else {
		Set-Notification -Notifies $Notifies -NotifiesServicePath $NotifiesServicePath
	}

}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$path,

		[System.String]
		$permissions,

		[System.String]
		$share,

		[System.String]
		$acl,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

		[System.String[]]
		$Notifies,

		[System.String]
		$NotifiesServicePath,

		[System.Boolean]
		$Reboot = $false
	)

	# Determine if the path exists or not
	if (!(Test-Path -Path $path)) {
		return $false
	}

	# if there are permissions to set then check them
	if (![String]::IsNullOrEmpty($permissions)) {
		# if the test on the Manage-FolderACl comes back false then return false
		$perms = _Manage-FolderAcl -path $path -permissions ($permissions | ConvertFrom-JsonToHashtable) -test
		if ($perms -eq $false) {
			return $false
		}
	}

	# if the path is to be shared, check that it is
	if (![String]::IsNullOrEmpty($share)) {
		$shared = _Manage-FolderShare -path $path -name $share -test
		if ($shared -eq $false) {
			return $false
		}
	}

	# finally if there are share acls to set then check them
	if (![String]::IsNullOrEmpty($acl)) {
		$share_acl = _Manage-FolderShareACL -name $share -permissions ($acl | ConvertFrom-JsonToHashtable) -test
		if ($share_acl -eq $false) {
			return $true
		}
	}

	# if jere then all the tests have passed so return true
	return $true

}

function _Manage-Folder {

    <#

    .SYNOPSIS
    Helper function to check if the folder exists, and if it should be created or not

    #>

    [CmdletBinding()]
    param (

        [Parameter(Mandatory=$true)]
        [string]
        # Name of folder to check
        $path,

        [switch]
        # Whether to test for the existence
        $test,

        [switch]
        # Delete the folder if this switch is specified
        $remove
    )

	Write-Verbose $MyInvocation.MyCommand

    # If the function has been called with the switch 'test' specified then perform the test
    # and return the boolean value
    if ($test -eq $true) {

        if (Test-Path -Path $path) {
			$return = $path
		} else {
			$return = $false
		}

		Write-Verbose ("Testing if '{0}' exists [{1}]" -f $path, $return)

        return $return
    }

	# determine if the drive for the path exists
	# only do this for non-unc paths
	$isunc = ([System.URI] $path).IsUnc

	# Get the drive from the path using the split-path cmdlet
	$drive = Split-Path -Path $path -Qualifier

	# if it is a local path and the drive does not exist return
	if ($isunc -eq $false -and (Test-Path -Path $drive) -eq $false) {
		Write-Verbose ("Drive '{0}' does not exist, directory '{1}' not created.  The remaining operations for this path will be skipped" -f $drive, $path)
		return $false
	}

    # If the remove switch has been sepcified and the directory exists, remove it
    if ($remove -eq $true -and (Test-Path -path $path) -eq $true) {
        Remove-Item -path $path -force -recurse | out-null
        return
    }

    # If the system has got here then the folder should be crated, if it does not already exist
    if (!(Test-Path -path $path)) {
        New-Item -type directory -path $path | Out-null
        return $path
    }

	# if there then return true as the path exists
	$true
}

function _Manage-FolderACL {

    <#

    .SYNOPSIS
    Helper function to manage the ACL that is applied to the folder

    #>

    [CmdletBinding()]
    param (

        [Parameter(Mandatory=$true)]
        [string]
        # Path to the folder on which to set permissions
        $path,

        [object[]]
        # Hashtable with the permissions that should be set on the folder
        $permissions,

        [switch]
        # Switch to specify if an evaluation of the permissions should be done
        # and a boolean of whether it is correct or not should be performed
        $test
    )

	Write-Verbose $MyInvocation.MyCommand

    # If the path does not exist then return false
    if (!(Test-Path -Path $path)) {
        return $false
    }

    # Get the current ACL for the folder
    $acl = Get-Acl -Path $path

    # if the ACL is required then just return it
    if ($test -eq $true) {

        # set the default value for the return
        $return = $true

        # iterate around the permissions that have been passed and check to see
        # if each one is present and correct in the acl
        foreach ($account in $permissions.keys) {

            # attempt to the find the current permission item
            $exists = $acl.Access | Where-Object { $_.IdentityReference -eq $account -and $_.FilesystemRights -contains $permissions.$account }

            # if the exists is empty or null then the permissions are not correct
            if ([String]::IsNullOrEmpty($exists)) {
                $return = $false
				break
            }
        }

        # Return the analysis of the ACL for the folder
        return $return
    }

    # return to the calling function if no permissions have been specified
    # if ()

    # Determine if the required permissions are set on the folder or not
    # Iterate around the permissions
    foreach ($account in $permissions.keys) {

        # Check to see if the permission for the user already exists on the folder
        $exists = $acl.Access | Where-Object {$_.IdentityReference -eq $account}

        # If $exists is not null, make sure that the permission that exists has the correct AccessRights
        # Otherwise remove it from the acl
        if (![String]::IsNullOrEmpty($exists) -and ([String]::IsNullOrEmpty(($exists | Where-Object { $_.FilesystemRights -eq $permissions.$account} )))) {

            Write-Verbose "User is in ACL but does not have correct rights"

            # Remove the current setting for this user
            # create an access rights object
            $acl.RemoveAccessRuleAll($exists)

            # Now that the user has been removed, set the $exists to empty so the correct rule can be added
            $exists = [String]::Empty
        }

        # if the exists is false then add the user to the folder
        if ([String]::IsNullOrEmpty($exists)) {

            # Create the new access rule for the entity
            $rights = [System.Security.AccessControl.FilesystemRights] $permissions.$account
            $inheritance = [System.Security.AccessControl.InheritanceFlags] "ContainerInherit, ObjectInherit"
            $propagation = [System.Security.AccessControl.PropagationFlags]::None
            $control_type = [System.Security.AccessControl.AccessControlType]::Allow
            $user = New-Object System.Security.Principal.NTAccount($account)

            # craete the rule using the items that have been set above
            $ar = New-Object System.Security.AccessControl.FilesystemAccessRule($user, $rights, $inheritance, $propagation, $control_type)

            # Set the new rule on the object
            $acl.SetAccessRule($ar)

        }

    }

    # Apply the permissions
    Set-Acl -Path $path -aclObject $acl
}

function _Manage-FolderShare {

    <#

    .SYNOPSIS
    Helper function to see if the share exists, and if it should be created or not

    #>

    [CmdletBinding()]
    param (

        [AllowNull()]
        [string]
        # Path to the folder
        $path,

        [string]
        # Name of the share to create
        $name,

        [switch]
        # Return true or false as to whether the share exists or not
        $test,

        [switch]
        # remove the share
        $remove
    )

		Write-Verbose $MyInvocation.MyCommand

		# if the path does not exist then retutn to the calling function
		if (!(Test-Path -Path $path)) {
			return
		}

    # If the name of the share is empty then return to the calling function
    if ([String]::IsNullOrEmpty($name) -and $remove -eq $false) {
        return
    }

    # If the function has been called with the 'test' switch then check to see if the share
    # exists and return a boolean value
    if ($test -eq $true) {

        $share_exists = _GetShare -name $name #Get-WmiObject -class Win32_Share -Filter ("Name='{0}'" -f $name)

        if (![String]::IsNullOrEmpty($share_exists)) {
           return $true
        } else {
           return $false
        }
    }

    # If the function has been called with the 'remove' switch then remove the share from the folder
    if ($remove -eq $true) {

			# As the path exists check to see if there are any shares that need to be removed
			# build up the filter to use
			$split_path = $path -split "\\"
			$filter = "Path='{0}'" -f ($split_path -join "\\")

			# run WMI query to get the shares for the path
			$shares_on_folder = @(Get-WmiObject -class Win32_Share -Filter $filter)

			# if the shares_on_folder is not empty then iterate around and remove the shares
			foreach ($share in $shares_on_folder) {

				# create the filter for the share
				$filter = "Name='{0}'" -f $share.name

				# run another wmi query to remove the share
				Get-WmiObject -Class Win32_Share -Filter $filter | Remove-WmiObject
			}

      return
    }

    # If here then the share needs to be created
		_CreateShare -path $path -name $name


}

function _Manage-FolderShareACL {

    <#

    .SYNOPSIS
    Sets the ACL on the share

    #>

    [CmdletBinding()]
    param (

        [Parameter(Mandatory=$true)]
        [AllowNull()]
        [string]
        # name of the share
        $name,

        [Parameter(Mandatory=$true)]
        [AllowNull()]
        # Permissiions that should be applied to the share
        $permissions,

		[switch]
		# Specify if the system should return a boolen regarding the state of the acl on the share
		$test

    )



    # If the share is empty then return to the calling funcyion
    if ([String]::IsNullOrEmpty($name)) {
		Write-Verbose "No share name has been specified"
        return
    }

    # If the permissions is empty then return
    if ([String]::IsNullOrEmpty($permissions)) {
		Write-verbose "No ACL has been provided for the share"
        return
    } else {
		Write-Verbose ("{0} ACL items need to be checked" -f $permissions.count)
	}

    # Get the permissions that already exist on the share
    # Set the Filter
    $filter = "Name='{0}'" -f $name

    $descriptor = @(_GetSecurityDescriptors -filter $filter)

    # Iterate around the share permissions that have been passed
    foreach ($account in $permissions.keys) {

        # Turn the username into a domain and user object
        $identity = _Get-Identity -user $account

        # determine if an permissions already exists on the share for this user
        $exists = $descriptor | Where-Object { $_.DACL.trustee.name -eq $identity.user -and $_.DACL.Trustee.Domain -eq $identity.domain }

        # Get the numerical value for the rights that are to be assigned to the share
        $mask = _Translate-AccessMask -name $permissions.$account

        # Translate the access mask integer to a string so that it can be compared with what has been specified
        # for this share
        # $mask = _Translate-AccessMask -val $exists.DACL.AccessMask

        # If the acl exists for the user then check that the rights are correct
        if (![String]::IsNullOrEmpty($exists) -and ([String]::IsNullOrEmpty(($exists | Where-Object { $_.DACL.AccessMask -eq $mask })))) {

					 # if the function is in test mode then set false for the return value
						if ($test -eq $true) {
							return $false
						} else {

						  # The user exists on the share, but the acl is wrong, so remove the user so they can be added with
							# the correct permissions
							$descriptor = _Remove-SharePermission -domain $identity.domain -user $identity.user -name $name

							# Set exists to be empty so that the permissions are added
							$exists = $null
						}

				}

        # If the exists is empty then add the permissions
        if ([String]::IsNullOrEmpty($exists)) {

						if ($test -eq $true) {
							return $false
						}

            # Create the new ACE trustee for the share
            $user = new-Object System.Security.Principal.NTAccount($account)
            $sid_string = $user.Translate([System.Security.Principal.SecurityIdentifier])
            $sid = New-Object System.Security.Principal.SecurityIdentifier($sid_string)

            # turn the SID into a byte array
            [byte[]] $ba = ,0 * $sid.BinaryLength
            [void] $sid.GetBinaryForm($ba, 0)

            # Create a a new trustee object
            $trustee = ([WMIClass] "Win32_trustee").CreateInstance()
            $trustee.sid = $ba
            $trustee.domain = $identity.domain
            $trustee.name = $identity.user

            # Create the ACE object to apply to the share
            $ace = ([WMIClass] "Win32_ace").CreateInstance()
            $ace.AccessMask = [System.Security.AccessControl.FilesystemRights] $permissions.$account
            $ace.AceFlags = 0
            $ace.AceType = 0
            $ace.Trustee = $trustee

            # append the new ACE to the descriptor
            $descriptor.DACL += @($ace.psobject.baseobject)

        }

        # Set the access on the share
        _Set-Share -name $name -descriptor $descriptor

    }
}

function _Remove-SharePermission {


    <#

    .SYNOPSIS
    Removes the specified user from the share permissions

    #>

    [CmdletBinding()]
    param (

        # User domain
        $domain,

        [string]
        # User to remove
        $user,

        [string]
        # Name of the share
        $name
    )

    # Build up the filter to get the correct share from WmiClass
    $filter = "Name='{0}'" -f $name

    # Get the security descriptor for the named share
    $descriptor = Get-WmiObject -Class "Win32_LogicalShareSecuritySetting" -Filter $filter | Foreach-Object {
                        $_.GetSecurityDescriptor().Descriptor
                  }

    # Attempt to get the DACL
    $DACLs = $descriptor.DACL

    # if the dacl is null then return to the calling function
    if ([String]::IsNullOrEmpty($DACLs)) {
        return
    }

    # Get the index of the current user in the ACL
    $index = _Get-ShareACLIndex -dacl $DACLs -domain $domain -user $user

    # Check that the index is not -1 otherwise this means that the user is not set ont he share
    if ($index -eq -1) {
        Write-Verbose ("User {0}\{1} cannot be found on share {2}" -f $domain, $user, $name)
        return
    }

	Write-Verbose ("Index of ACL to remove - {0}" -f $index)

    # Call the Remove-DACL function to return a list of the DACL that should be set
    $required_dacls = _Remove-DACL -dacl $DACLs -index $index

    # Now set the security descriptoe with the correct DACL
    $descriptor.DACL = $required_dacls

    # Return the descriptor to the calling function so it can be added to
    $descriptor
}

function _Get-ShareACLIndex {

    <#

    .SYNOPSIS
    Return the index of the specified user in the share ACl

    #>

    [CmdletBinding()]
    param (

        [Parameter(Mandatory=$true)]
        $DACLs,

        # Domain
        $domain,

        [string]
        # User
        $user
    )

    # Set a default value for the index
    $index = -1

    # iterate around the DACL until the one with the specified username and domain has been found
    for ($i = 0; $i -le ($DACLs.count - 1); $i += 1) {

        # Test to see if the specified domain and user is in the current trustee
        if (($DACLs[$i].Trustee.Domain -eq $domain) -and ($DACLs[$i].Trustee.Name -eq $user)) {
            $index = $i
        }
    }

    # return the index value to the calling function
    $index
}

function _Remove-DACL {

    <#

    .SYNOPSIS
    Remove the specified index from the DACL

    #>

    [CmdletBinding()]
    param (

        # The current list of DACL
        $DACLs,

        [int]
        # Index number of the item to be deleted
        $index
    )

    # Check that the function has the necessary informaiton to work with
    if (($DACLs.Count -eq 1) -and ($index -eq 0)) {

        # return null to the calling function
        return $null
    }

    # return a list of the DACLs that should be set on the share
    if ($index -eq 0) {

        # If the ACL to remove is the first item then set the required DACLs to be
        # from the 2nd element to the end
        $required_dacls = $DACLs[1..($DACLs.Count - 1)]

    } elseif ($index -eq ($DACLs.Count - 1)) {

        # if the ACL to remove is at the end, get the acls from the beginning to penultimate
        $required_dacls = $DACLs[0..($DACLs.Count - 2)]

    } else {

        # if the item to remove is in the middle then take everything up to the element before
        # and everything from the elemtn after
        $required_dacls = $DACLs[0..($index - 1) + ($index + 1)..($DACLs.Count - 1)]

    }

    # return the list
    return $required_dacls
}

function _Set-Share {

    <#

    .SYNOPSIS
    Set the necessary access permissions ont he sahre

    #>

    [CmdletBinding()]
    param (

        [Parameter(Mandatory=$true)]
        [string]
        # Name of the share to work with
        $name,

        # Security descriptor to apply to the share
        $descriptor
    )

    # set the filter to use in the WMI query
    $filter = "Name='{0}'" -f $name

    # Get an instance of the share
    $share = Get-WmiObject -Class "Win32_Share" -Filter $filter

    # Set the share informaiton
    $result = $share.SetShareInfo([System.Uint32]::MaximumAllowed, "DSC set Permissions", $descriptor)


}

function _Get-Identity {

    <#

    .SYNOPSIS
    Given a user return the domain and user parts

    #>

    [CmdletBinding()]
    param (

        [Parameter(Mandatory=$true)]
        [string]
        # Username to analyse
        $user
    )

    # Build up the identity object to return
    $identity = @{domain = $null
                  user = [String]::Empty}

    # Determine if the user has a '@' or a '\' in the name
    # as these are delimiters for domain
    if ($user -notcontains "@" -and $user -notcontains "\") {
        $identity.user = $user
    } else {

        # if the user contains a \ or a @ means that the domain is at different locations
        # in any array that is split
        if ($user -contains "@") {
            $identity.user, $identity.domain = $user -split "@"
        }

        if ($user -contains "\") {
            $identity.domain, $identity.user = $user -split "\"
        }
    }

    # return the identity object
    $identity
}

function _Translate-AccessMask {

    <#

    .SYNOPSIS
    Translates the AccessMask value into Human readable format

    #>

    [CmdletBinding()]
    param (

        [Parameter(ParameterSetName="value")]
        [int]
        $val,

        [Parameter(ParameterSetName="name")]
        [string]
        $name

    )

    # Build up hash table of the masks values and the name
    $mask = @{
        2032127 = "FullControl"
        1179785 = "Read"
        1180063 = "Read, Write"
        1179817 = "ReadAndExecute"
        -1610612736 = "ReadAndExecuteExtended"
        1245631 = "ReadAndExecute, Modify, Write"
        1180095 = "ReadAndExecute, Write"
        268435456 = "FullControl (Sub Only)"
    }

    # perform the appropriate action based on the parameter set
    switch ($PSCmdlet.ParameterSetName) {

        "value" {
            $return = $mask.$val
        }

        "name" {

            $am = $mask.GetEnumerator() | ? { $_.Value -eq $name }

            $return = [int] $am.name
        }
    }

    # return the value to the calling function
    return $return

}

function _CreateShare {

	<#

	.SYNOPSIS
		Function to perform the action of creating the share

	#>
	[CmdletBinding()]
	param (

		# Path to the directory to be shared
		$path,

		# Name of the share to create
		$name
	)

	$share = [WmiClass] "win32_share"
	$status = $share.Create($path, $name, 0)

}

function _GetShare {

	param (
		$name
	)

	return Get-WmiObject -class Win32_Share -Filter ("Name='{0}'" -f $name)
}

function _GetSecurityDescriptors {
	param (
		$filter
	)

	$descriptor = Get-WmiObject -Class "Win32_LogicalShareSecuritySetting" -Filter $filter | Foreach-Object {
		$_.GetSecurityDescriptor().Descriptor
	}

	return $descriptor
}
