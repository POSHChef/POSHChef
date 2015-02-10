function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Destination
	)

	# Define the hashtable to return to the calling function
	$returnValue = @{}

	$returnValue
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Destination,

		[System.String]
		$Mask,

		[System.String]
		$Gateway,

		[System.String]
		$Metric,

		[System.Boolean]
		$Persistent = $true,

		[System.String]
		$Name,

		[System.String]
		$Description,

		[System.String]
		$Ensure
	)

	# Create an ArrayList to add the necessary command arguments
	$parts = New-Object System.Collections.ArrayList
	$parts.Add("C:\Windows\system32\route.exe") | Out-Null

	# Switch on the Ensure string so the route is added or removed as defined by
	# the recipe
	switch ($Ensure) {

		"Present" {

			# The route does not exist so add it
			# This will use the route add command from Windows

			Write-Verbose ("Adding new route for '{0}'" -f $Name)

			# Add the operation to the command
			$parts.Add("add") | Out-Null

			# If this is a persistent route add if it is specified
			if ($Persistent) {
				$parts.Add("-p") | Out-Null
			}

			# Add in the rest of the arguments thar are required
			# Destination
			$parts.Add($Destination) | Out-Null

			# Subnet Mask
			$parts.Add(("MASK {0}" -f $Mask)) | Out-Null

			# Gateway
			$parts.Add($Gateway) | Out-Null

			# Add in a metric if it has been specified
			if (![String]::IsNullOrEmpty($Metric)) {
				$parts.Add(("METRIC {0}" -f $Metric)) | Out-Null
			}

		}

		"Absent" {

			Write-Verbose ("Removing route '{0}'" -f $Name)

			# Add the operation to the command
			$parts.Add("delete") | Out-Null

			# Add the detsination to the arraylist
			$parts.Add($Destination) | Out-Null

		}

	}

	# Join all the parts of the array together to get the command
	$cmd = $parts -join " "

	# Add the route command to the output of the function
	Write-Verbose ("Command: {0}" -f $cmd)

	# Execute the route command
	Invoke-Expression $cmd
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Destination,

		[System.String]
		$Mask,

		[System.String]
		$Gateway,

		[System.String]
		$Metric,

		[System.Boolean]
		$Persistent = $true,

		[System.String]
		$Name,

		[System.String]
		$Description,

		[System.String]
		$Ensure
	)

	# set the test value
	$test = $true

	# Select the Wmi class to use based on whether this is to be a persisted route or not
	if ($Persistent -eq $true) {
		$wmiclass = "Win32_IP4PersistedRouteTable"
	} else {
		$wmiclass = "Win32_IP4RouteTable"
	}

	# Build up the agrument hashtable to pass to the Get-WMIObject
	$splat = @{
		class = $wmiclass
	}

	# If the destination has been set then add in a query to see if a route to it exists
	if (![String]::IsNullOrEmpty($Destination)) {
		$splat.filter = 'Destination="{0}"' -f $Destination
	}

	# Obtain a list of the routes on the machine
	$routes = Get-WmiObject @splat

	# Determine if the route exists
	$exists = ![String]::IsNullOrEmpty($routes)

  # Switch on the Ensure string to determine the correct state
	switch ($Ensure) {
		"Present" {
			if ($exists -eq $false) {
				$test = $false
			} else {
				Write-Verbose ("Route '{0}' already exists" -f $Name)
			}
		}

		"Absent" {
			if ($exists -eq $false) {
				$test = $false
			} else {
				Write-Verbose ("Route '{0}' does not exist" -f $Name)
			}
		}
	}

	# return the test boolean
	return $test
}
