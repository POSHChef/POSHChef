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


function Set-Nodename {

	<#

	.SYNOPSIS
	Set the name of the node for the chef serve

	.DESCRIPTION
	Chef the chefconfig object and check that a nodename is present, if not then]
	set it based on the FQDN of the server

	#>

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	# loop around the attributes that need to be set
	foreach ($attr in @("client", "node", "key")) {

		# Determine if nodename exists in the configuration
	    # Get-Member -InputObject $global:chef_config -MemberType NoteProperty -Name $attr

		if ([string]::IsNullOrEmpty($script:session.config.$attr)) {

			# determine the node name to be added
			if ($attr -eq "key") {
				$value = "client.pem"
			} else {
				$value = ("{0}.{1}" -f $env:COMPUTERNAME, $env:USERDNSDOMAIN).tolower()
			}

			# as the property does not exist, add it now
			Write-Log -IfDebug -EventId PC_DEBUG_0001 -extra $attr

			# add a new noteproperty to the object
			Add-Member -InputObject $script:session.config -MemberType NoteProperty -Name $attr -Value $value

		}
	}

}
