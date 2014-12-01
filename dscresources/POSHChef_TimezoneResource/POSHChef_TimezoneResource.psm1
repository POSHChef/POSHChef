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
    param 
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$timezone        
    )

    $currentTimezone = & tzutil.exe /g

    return @{ Timezone = $currentTimezone }
}

function Test-TargetResource 
{
    [CmdletBinding()]
    param 
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$timezone,
		
		[System.String[]]
		$Notifies,

		[System.String]
		$NotifiesServicePath,

		[System.Boolean]
		$Reboot = $false

    )

    [bool]$result = (& tzutil.exe /g).Trim() -ieq $timezone
    return $result
}

function Set-TargetResource 
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param 
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$timezone,
		
		[System.String[]]
		$Notifies,

		[System.String]
		$NotifiesServicePath,

		[System.Boolean]
		$Reboot = $false         
    )

    if ($pscmdlet.ShouldProcess("Setting the specified Timezone"))
    {
        & tzutil.exe /s "$timezone"
    }
	
	# Notify any services of this change
	# Set the DSC resource to reboot the machine if set
	if ($Reboot -eq $true) {
		$global:DSCMachineStatus = 1
	} else {
		Set-Notification -Notifies $Notifies -NotifiesServicePath $NotifiesServicePath
	}
}





