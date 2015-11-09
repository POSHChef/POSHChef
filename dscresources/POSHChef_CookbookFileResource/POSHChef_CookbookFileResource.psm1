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
		$NotifiesServicePath,
		
		[System.Boolean]
		# Specify whether the source that has been set is a string that needs to be
		# Written out to the file or if false it is a file that needs to be copied
		# from the coobook
		$IsContent = $false,
		
		[System.String]
		$Encoding = "UTF8",
		
		[System.Boolean]
		$WithBOM = $true
	)
	
	# Use the Get-TargetResource to determine if the file exists
	$status = Get-TargetResource -Destination $Destination -Source $Source

	# Switch on the Ensure parameter
	switch ($Ensure) {

		"Present" {
		
			# Get the source path for the specified source
			if ($IsContent -eq $false) {
				# Get the source path for the specified source
				$SourcePath = Get-SourcePath -Source $Source -CacheDir $CacheDir -Cookbook $cookbook -Type file

			} else {
				
				# Determine the path to the temporaty file based on the string, e.g. a hash
				# This is so that it can be resolved to the same name int eh Set-TargetResource
				$SourcePath = _GetFileName -contents $Source
				if (!(Test-Path -Path $SourcePath)) {
					_WriteStringToFile -contents $Source -Path $SourcePath -Encoding $Encoding -WithBOM $WithBOM
				}
			}

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
		$NotifiesServicePath,
		
		[System.Boolean]
		# Specify whether the source that has been set is a string that needs to be
		# Written out to the file or if false it is a file that needs to be copied
		# from the coobook
		$IsContent = $false,
		
		[System.String]
		$Encoding = "UTF8",
		
		[System.Boolean]
		$WithBOM = $true
	)

	# Define test variable that will be used to return boolean for the test
	# By default this is set to 'true', e.g. assumes that everything is OK
	$test = $true

	# Use the Get-TargetResource to determine if the file exists
	$status = Get-TargetResource -Destination $Destination -Source $Source
	
	# Switch on the Ensure parameter
	switch ($Ensure) {

		"Present" {

			# Work out if the Source is a file or content, if it is a file then check that
			# it exists in the cookbook
			if ($IsContent -eq $false) {
				# Get the source path for the specified source
				$SourcePath = Get-SourcePath -Source $Source -CacheDir $CacheDir -Cookbook $cookbook -Type file

			} else {
				
				# Determine the path to the temporaty file based on the string, e.g. a hash
				# This is so that it can be resolved to the same name int eh Set-TargetResource
				$SourcePath = _GetFileName -contents $Source
				write-host $sourcepath
				_WriteStringToFile -contents $Source -Path $SourcePath -Encoding $Encoding -WithBOM $WithBOM
				
			}

			# Determine if the SourcePath exists
			if ($SourcePath -eq $false) {
				throw ("Source file does not exist: {0}" -f $Source)
			} else {

				# Write out information to show the file that is being used as the template
				Write-Verbose ("Using file: {0}" -f $SourcePath)

				# Does the destination file exist
				if ($Status.Ensure -ieq "present") {

					# Define a hashtable to hold the checksums for the files that are tested
					$checksum = @{
						file = ""
						existing = ""
					}

					# Get the checksum for the patched template
					Write-Verbose "Getting checksum for file"
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

function _GetFilename {
	
	<#
	
	.SYNOPSIS
		Based on the content determine a filename to be used to save the content to
		
	.DESCRIPTION
		Due to the way in which DSC works it is not possible to pass things between resources.
		In order to test a string in a file against the one that needs to be set then a temporary
		file needs to be created.
		
		When this function is called by either function then the result should be the same
		as it is based on the temp directory of the user and a hash of the content.
	
	.NOTE
		The encoding of the string is not an issue here as it is just to get the filename 
	
	#>
	
	param (
		[String]
		# Contents that need to be written out
		$contents,
		
		[String]
		# Base path in which to save the file
		$Base = $env:TEMP
	)
	
	$StringBuilder = New-Object System.Text.StringBuilder 
	
	[System.Security.Cryptography.HashAlgorithm]::Create("MD5").ComputeHash([System.Text.Encoding]::UTF8.GetBytes($contents)) | Foreach-Object { 
		[Void] $StringBuilder.Append($_.ToString("x2")) 
	} 
	$hash = $StringBuilder.ToString() 
	
	# Work out the filename to use
	$filename = "{0}\{1}.tmp" -f $Base, $hash
	
	# Return the filename to the calling function
	return $filename
	
}

function _WriteStringToFile {
	
	param (
			[String]
			# Contents that have to ben written out to the file
			$contents,
			
			[String]
			# The file that should be written out to
			$path,
			
			[String]
			# Encoding that should be used on the file
			$Encoding,
			
			[Boolean]
			$WithBOM
	)
	
	# Build up the objecttype that is to be created
	$object_type = "System.Text.{0}Encoding" -f $Encoding
	
	# Instantiate the encoding object with or without BOM
	$enc = New-Object $object_type($WithBOM)
	
	# Use WriteAll text to write out the file
	[System.IO.File]::WriteAllText($path, $contents, $enc)
}
