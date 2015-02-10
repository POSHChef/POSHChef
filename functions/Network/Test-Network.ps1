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

function Test-Network {

	<#

	.SYNOPSIS
	Check that the system is able to contact the Chef server

	.DESCRIPTION
	When POSHChef is run an a schedule there maybe times when the network is not available and the machine cannot
	contact the chef server.  This function checks for connectivity to the chef server at the start before
	any REST calls are made.

	The reason for this to fail gracefully at the beginning in a known way

	#>

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	Write-Log " "
	Write-Log -EventId PC_INFO_0044

	# get a uri object of the chef server so that it can be used by the sockets object
	$chef_uri = $script:session.config.server -as [System.Uri]

	# Create a sockets object to test the connecivity to the chef server
	$socket = new-Object Net.Sockets.TcpClient

	# attempt a connection to the chef server
	try {
		$socket.Connect($chef_uri.host, $chef_uri.port)
	} catch {
		
		# there has been a problem so halt the command
		Write-Log -EventId PC_ERROR_0017 -Error -extra $_.Exception.Message -stop
	}

	# If the system is here then the test passed
	Write-Log -EventId PC_MISC_0001 -extra "Passed" -fgcolour darkgreen


}
