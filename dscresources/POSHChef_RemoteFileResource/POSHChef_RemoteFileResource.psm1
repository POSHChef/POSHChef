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
		$Source,

		[parameter(Mandatory = $true)]
		[System.String]
		$Target
	)

	# Define the hashtable to return to the calling function
	$returnValue = @{}

	# Determine if the destination path exists, this will set the Ensure parameter in the
	# return value
	if (Test-Path -Path $Target) {
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
		$Source,

		[parameter(Mandatory = $true)]
		[System.String]
		$Target,

		[System.String]
		$Checksum,

		[ValidateSet("MD5","SHA1")]
		[System.String]
		$Algorithm = "MD5",

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

		[System.Boolean]
		$Reboot = $false,

		[System.Management.Automation.PSCredential]
		$Credential,

		[System.String]
		$Proxy,

		[System.Management.Automation.PSCredential]
		$ProxyCredential,

		[System.String[]]
		$Notifies,

		[System.String]
		$NotifiesServicePath
	)
	
	# Use the Get-TargetResource to determine if the file exists
	$status = Get-TargetResource -Target $Target -Source $Source
	
	# Switch on the Ensure parameter
	switch ($Ensure) {

		"Present" {

			# if the source is not empty determine where it is coming from
			if (![String]::IsNullOrEmpty($Source)) {

				# Turn the source into a URI so that the scheme can be checked
				$uri = $Source -as [System.URI]

				# Select based on the scheme
				# Ensure wildcard is used so that https will be picked up
				switch -Wildcard ($uri.scheme) {

					"file" {
					
						# If the source file exists, copy it to the target
						if (Test-Path -Path $Source) {

							# Determine the type of the source so that the target directory can be created accordingly
							$source_type = Get-Item -Path $source
					
							# if the source is a directory then the target must be as well so make sure it exists
							# if it is a file then ensure the parent dir exists
							if ($source_type.PSISContainer -eq $true) {
								$parent = $target
								$Source = "{0}\*" -f $Source 
							} else {
								$parent = Split-Path -Parent -Path $target
							}

							# Ensure the parent path exists so that the file(s) can be copied to it
							if (!(Test-Path -Path $parent)) {
								# State that the parent directory is being created
								Write-Verbose ("Creating target directory: {0}" -f $parent) 

								New-Item -Type Directory -Path $parent | out-null
							}

							# build up the argument splat for the command
							$splat = @{
								Path = $Source
								Destination = $Target
								Recurse = $true
							}

							Copy-Item @splat
						} else {
							throw ("Source file does not exist: {0}" -f $source)
						}

					}

					"http*" {

						# Build up the argument hash that needs to be configured for the Invoke-WebRequest
						$splat = @{
							Uri = $source
							OutFile = $Target
							UseBasicParsing = $true
						}
						
						# if a credential has been specified add it here
						if (![String]::IsNullOrEmpty($credential)) {
							$splat.credential = $credential
						}

						# if a proxy server has been specified add it to the arguments
						if ($Proxy -ne $false -and ![String]::IsNullOrEmpty($proxy)) {
							$splat.proxy = $proxy

							# check to see if any proxy credentials have been specified
							if (![String]::IsNullOrEmpty($ProxyCredential)) {
								$splat.proxycredential = $proxycredential
							}
						}

						# Call the invoke-webrequest method to download the source file
						Invoke-WebRequest @splat
					}
				}
			}

		}

		"Absent" {

			# The destination file exists, but it should not so remove it
			Remove-Item -Path $Target -Force | Out-Null

		}

	}

	# Set the DSC resource to reboot the machine if set
	if ($Reboot -eq $true) {
		$global:DSCMachineStatus = 1
	} else {
		# Notify any services of this change
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
		$Source,

		[parameter(Mandatory = $true)]
		[System.String]
		$Target,

		[System.String]
		$Checksum,

		[ValidateSet("MD5","SHA1", "SHA256")]
		[System.String]
		$Algorithm = "MD5",		

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

		[System.Boolean]
		$Reboot = $false,

		[System.Management.Automation.PSCredential]
		$Credential,

		[System.String]
		$Proxy,

		[System.Management.Automation.PSCredential]
		$ProxyCredential,

		[System.String[]]
		$Notifies,

		[System.String]
		$NotifiesServicePath
	)

	# Define test variable that will be used to return boolean for the test
	# By default this is set to 'true', e.g. assumes that everything is OK
	$test = $true

	# Use the Get-TargetResource to determine if the file exists
	$status = Get-TargetResource -Target $Target -Source $Source

		# Switch on the Ensure parameter
	switch ($Ensure) {

		"Present" {

			# check the status to see if the file should be downloaded or not
			if ($Status.Ensure -ieq "present") {

				# Get the source to determine if it is a file or a directory
				# If it is a directory then the system must make sure that a similar one exists in the target
				# If it is a file then it needs to get the checksum
				$source_type = Get-Item -Path $source

				# if the source is a directory then the target must be as well so make sure it exists
				# if it is a file then ensure the parent dir exists
				if ($source_type.PSISContainer -eq $true) {

					# Test to see if the target exists
					if (!(Test-Path -Path $target)) {
						$test = $false
					}

				} else {

					# The source is a file so get the checksum of the source and, if it is exists the local one and compare

					$checksums = @{
						proposed = $Checksum
						existing = ""
					}

					# The local file exists, so get its checksum and compare against the one that has been supplied
					$checksums.existing = Get-Checksum -Path $Target -Algorithm $Algorithm

					# Compare the two checksums to detrmine if the local resource needs updating
					if ($checksums.proposed -ne $checksums.existing) {
						$test = $false
					}
				}

			} else {

				# The local file does not exist so ensure that it is created
				$test = $false

			}

			if ($test -eq $false) {
				Write-Verbose ("Target does not exist or is out of date: {0}" -f $destination)
			}
		}

		"Absent" {

			# The filw should not exist, but if the status says it does then set the test flag to false
			if ($Status.Ensure -ieq "present") {
				Write-Verbose ("Target '{0}' exists, it will be removed" -f $Destination)
				$test = $false
			}
		}
	}

	return $test
}



