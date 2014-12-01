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
	Provides network attributes to the Chef run using WMI

	.DESCRIPTION
	This plugin is evaluated at runtime and must return a hashtable of attributes at the correct level
	These will be combined with the main node_attributes

	There are some toplevel attributes that Chef expects, such as IPAddress, fqdn and domain.  These are taken from the first
	network card in a machine.  In *NIX land this is easy as they are numbered 'eth0', 'eth1' etc - however Windows does not
	have this convention.  So the script will use the 'first' network adapater as defined by the index

	Where possible the additional information, such as the address family, has been added to the addresses to maintain as much
	compatibility with chef as possible

	This script is not able to determine whether the NIC is a virtual or physical adapter

#>

# Craete function to return the broadcast address of an IP address given the 
# subnet mask
function Get-BroadcastAddress {

	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true)]
		[string]
		# Ip address to use to determine broadcast
		$ipaddress,
		
		[string]
		# Subnet of this IP address
		$subnetmask = "255.255.255.0"
		
	)

	filter Convert-IPtoDecimal {
		([Net.IPAddress][String]([Net.IPAddress]$_)).Address
	}

	filter Convert-DecimalToIp {
		([Net.IPAddress]$_).IPAddressToString
	}
	
	[UInt32] $ip = $ipaddress | Convert-IPtoDecimal
	[UInt32] $subnet = $subnetmask | Convert-IPtoDecimal
	[UInt32] $broadcast = $ip -band $subnet
	$broadcast -bor -bnot $subnet | Convert-DecimalToIp
}

# Define a mapping hashtable that maps names given by Windows
# to thost that are given by OHAI.  This is to maintain compatibility with Chef-client
$mapping = @{
	InterNetwork = "inet"
	InterNetworkV6 = "inet6"
	"Ethernet 802.3" = "eth"
}

# Define a hashtable that will be used to hold the gathered data
$attrs = @{
			network = @{
				interfaces = @{
				}
			}
		}

# Get all of the IpEnabled network cards in the machine
$networks = gwmi Win32_NetworkAdapterConfiguration -Filter "IpEnabled=$true" | Sort-Object -Property index

# create loop counter to determine if this is the first nic in the machine
$loop = 0
foreach ($network in $networks) {

	# using the network index get the network adapter for this IpEnabled network
	$nic = gwmi win32_networkadapter -Filter ("index = {0}" -f $network.index)

	$interface = @{
		addresses = @{}
		type = $mapping.$($nic.AdapterType)
		number = $nic.index
	}
	
	# get hostname and domain for the machine
	$hostname, $domain = ([system.net.dns]::GetHostByName("localhost")).hostname.tolower() -split "\.", 2

	# if the current network DNS is null then use the one from the local suystem
	if (![String]::isNullOrEmpty($network.DnsDomain)) {
		$domain = $network.DNSDomain
	}

	# iterate around the IP addresses on the NIC
	# this is so that they can be added to the addresses property of the interface
	foreach ($ipaddress in $network.IPAddress) {
	
		# determine the family of the ip address
		$family = ([Net.IPAddress] $ipaddress).AddressFamily.ToString()

		$interface.addresses.$ipaddress = @{
			netmask = $network.IPSubnet[0]
			broadcast = Get-BroadcastAddress -ipaddress $ipaddress -subnetmask $network.IPSubnet[0]
			family = $mapping.$family
		}
	}
	
	# Add in the Mac address to the addresses and set the type accordingly
	$mac = $nic.MACAddress
	$interface.addresses.$mac = @{
		type = "lladdr"
	}

	# get the values from the nic and network at add them to the interface array
	$interface.domain = $network.DNSDomain
	$interface.hostname = $hostname
		
	# add this interface to the main attrs if it does not already exist
	if (!$attrs.network.interfaces.ContainsKey($nic.NetConnectionId)) {
		$attrs.network.interfaces.($nic.NetConnectionId) = $interface
	}

	# set the toplevel attributes, if this is the first NIC in the list
	if ($loop -eq 0) {
		
		# set the similar toplevel attributes
		$attrs.ipaddress = $network.IPAddress[0]
		$attrs.macaddress = $network.MacAddress
		$attrs.domain = $domain
		$attrs.hostname = $hostname
		$attrs.fqdn = "{0}.{1}" -f $attrs.hostname, $attrs.domain
		
	}

	# increment the loop counter
	$loop ++
}

# Ensure that the attrs are output so they are recieved by the calling function
$attrs
