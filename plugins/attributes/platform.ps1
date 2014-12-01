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
	Provides platform attributes retrieved from the Win32_OperatingSystem WMI Class

	.DESCRIPTION
	Many attributes are retrieved by this script such as the versions of the OS, the service pack,
	uptime etc.

	The script will attempt to determine the friendly name of windows based on the version number
	
	.OUTPUTS
	System.Hashtable. Hashtable representing the attributes that have been retrived from the system

	.LINK
	http://www.nogeekleftbehind.com/2013/09/10/updated-list-of-os-version-queries-for-wmi-filters/
#>

# set the blank $attrs hashtable
$attrs = @{}

# Get inforamtion about the operating system
$os = gwmi Win32_OperatingSystem

# Work out the uptime of the server, both in human readale format and in seconds
[TimeSpan] $uptime = New-TimeSpan ($os.ConvertToDateTime($os.Lastbootuptime).touniversaltime()) 
$attrs.uptime = "{0,3} Days {1,2} Hours {2,2} Minutes {3,2} Seconds" -f `
			$uptime.days, `
			$uptime.hours, `
			$uptime.minutes, `
			$uptime.seconds

# Get the uptime in seconds
$attrs.uptime_seconds = [int] $uptime.TotalSeconds

# Set the OS version
# When chef runs on Linux this is the Kernel version, here it is subsitiuted with the
# build number of windows
$attrs.os_version = $os.BuildNumber

# Set the OS to be Windows
$attrs.os = "windows"

# Set the platform_family and version
$attrs.platform_family = "windows"
$attrs.platform_version = $os.version

# Set the platform
# Work out a friendly name based on the platform_version, e.g. windows_2008
# This is a long if statement as we need to check two parameters

# Windows 7
if ($attrs.platform_version -match "6\.1.*" -and $os.producttype -eq 1) {
	$friendly_name = "windows_7"
}

# Windows 8
if ($attrs.platform_version -match "6\.2.*" -and $os.producttype -eq 1) {
	$friendly_name = "windows_8"
}

# Windows 8.1
if ($attrs.platform_version -match "6\.3.*" -and $os.producttype -eq 1) {
	$friendly_name = "windows_8.1"
}

# Windows 2008
if ($attrs.platform_version -match "6\.0.*" -and $os.producttype -eq 2) {
	$friendly_name = "windows_2008"
}

# Windows 2008 R2
if ($attrs.platform_version -match "6\.1.*" -and ($os.producttype -eq 2 -or $os.producttype -eq 3)) {
	$friendly_name = "windows_2008_r2"
}

# Windows 2012
if ($attrs.platform_version -match "6\.3.*" -and ($os.producttype -eq 2 -or $os.producttype -eq 3)) {
	$friendly_name = "windows_2012"
}

# set the platform attribute
$attrs.platform = $friendly_name

# Set the service pack version
$attrs.platform_service_pack = $os.ServicePackMajorVersion

# Return / output the gathered attributes
$attrs
