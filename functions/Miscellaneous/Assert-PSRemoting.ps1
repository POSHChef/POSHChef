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

function Assert-PSRemoting {

	<#

		.SYNOPSIS
		Checks to see if PSRemoting is enabled and if not enables it

	#>

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	Write-Log " "
	Write-Log -EventId PC_INFO_0037

	# Attempt a remote connection to the local machine, if it does not succeed enable PSRemoting
	$enabled = [boolean] (Invoke-Command -computername localhost {1} -erroraction SilentlyContinue)

	if ($enabled -eq $false) {
		
		Write-Log -EventId PC_MISC_0001 -extra "Enabling"

		Enable-PSRemoting -Force -SkipNetworkProfileCheck
	} else {

		Write-Log -EventId PC_MISC_0001 -extra "Enabled" -fgcolour darkgreen
	}
}
