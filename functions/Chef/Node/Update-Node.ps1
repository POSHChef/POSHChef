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


function Update-Node {

	<#

	.SYNOPSIS
	Determines if a node needs to be udpated with new information, e.g. runlist

	#>

	[CmdletBinding()]
	param (

		[Hashtable]
		# Node attributes to send to the Chef server
		$attrs = @{},
		
		[string]
		$name = [String]::Empty
	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	# Firstly determine if the node exists
	$node = Get-Node -name $name

	# If the node is false then run the fucntion to register the node
	if ($node -eq $false) {
		$node = New-Node
	}

	# Update the node with the specifc information from the command line
	$splat = @{
		node = $node
		attrs = $attrs
	}
	
	if (![String]::IsNullOrEmpty($name)) {
		$splat.name = $name
	}

	Set-Node @splat
	



}
