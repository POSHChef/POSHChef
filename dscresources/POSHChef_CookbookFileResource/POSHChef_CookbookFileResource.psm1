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
		$Destination
	)

	# Define the hashtable to return to the calling function
	$returnValue = @{}

	# Determine if the destination path exists, this will set the Ensure parameter in the
	# return value
	if (Test-Path -Path $destination) {
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
		$Destination,

		[System.String]
		$Cookbook,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

		[System.Boolean]
		$Reboot = $false,

		[System.String]
		$CacheDir,

		[System.String[]]
		$Notifies,

		[System.String]
		$NotifiesServicePath
	)
	
	# Use the Get-TargetResource to determine if the file exists
	$status = Get-TargetResource -Destination $Destination -Source $Source

	# Switch on the Ensure parameter
	switch ($Ensure) {

		"Present" {
		
			# Get the source path for the specified source
			$SourcePath = Get-SourcePath -Source $Source -CacheDir $CacheDir -Cookbook $cookbook -Type file

			# Ensure the parent directory of the file exists
			$parent = Split-Path -Parent -Path $Destination
			if (!(Test-Path -Path $parent)) {
				New-Item -type directory -Path $parent | Out-Null
			}

			# Copy the source path to the destination
			Write-Verbose ("Copying file from '{0}' to '{1}'" -f $SourcePath, $Destination)
			Copy-Item -Path $SourcePath -Destination $Destination -Force | Out-Null

		}

		"Absent" {

			# The destination file exists, but it should not so remove it
			Remove-Item -Path $Destination -Force | Out-Null

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
		$Destination,

		[System.String]
		$Cookbook,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

		[System.Boolean]
		$Reboot = $false,

		[System.String]
		$CacheDir,

		[System.String[]]
		$Notifies,

		[System.String]
		$NotifiesServicePath
	)

	# Define test variable that will be used to return boolean for the test
	# By default this is set to 'true', e.g. assumes that everything is OK
	$test = $true

	# Use the Get-TargetResource to determine if the file exists
	$status = Get-TargetResource -Destination $Destination -Source $Source
	
	# Switch on the Ensure parameter
	switch ($Ensure) {

		"Present" {

			# Get the source path for the specified source
			$SourcePath = Get-SourcePath -Source $Source -CacheDir $CacheDir -Cookbook $cookbook -Type file

			# Determine if the SourcePath exists
			if ($SourcePath -eq $false) {
				throw ("Source file does not exist: {0}" -f $Source)
			} else {

				# Write out information to show the file that is being used as the template
				Write-Verbose ("Using cookbook file: {0}" -f $SourcePath)

				# Does the destination file exist
				if ($Status.Ensure -ieq "present") {

					# Define a hashtable to hold the checksums for the files that are tested
					$checksum = @{
						file = ""
						existing = ""
					}

					# Get the checksum for the patched template
					Write-Verbose "Getting checksum for cookbook file"
					$checksum.file = Get-Checksum -path $SourcePath
					Write-Verbose $checksum.file

					# Get the checksum for the existing file
					Write-Verbose ("Getting checksum for existing file: {0}" -f $Destination)
					$checksum.existing = Get-Checksum -path $Destination
					Write-Verbose $checksum.existing

					# Now perform a test on the checksums to determine if the file should be copied to the destination
					# Set the $test to false if they differ
					if ($checksum.file -ne $checksum.existing) {
						$test = $false
					}

				} else {

					# The file does not exist so it needs to be written out
					# Set the test flag to false
					$test = $false		
				}
			}
		}

		"Absent" {

			# The filw should not exist, but if the status says it does then set the test flag to false
			if ($Status.Ensure -ieq "present") {
				Write-Verbose ("File '{0}' exists, it will be removed" -f $Destination)
				$test = $false
			}
		}
	}

	return $test
}





