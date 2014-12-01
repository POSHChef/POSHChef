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
		$Attributes,

		[System.String]
		$Variables,

		[System.String]
		$CacheDir,

		[System.String[]]
		$Notifies,

		[System.String]
		$NotifiesServicePath,

		[System.String]
		$BeginTag = "[[",

		[System.String]
		$EndTag = "]]"
	)

	# Use the Get-TargetResource to determine if the file exists
	$status = Get-TargetResource -Destination $Destination -Source $Source

	# Switch on the Ensure parameter
	switch ($Ensure) {

		"Present" {

			# Using the exported function from POSHChef turn the JSON object into a Hashtable for the
			# attributes and the variables
			$attrs = $Attributes | ConvertFrom-JsonToHashtable
			if (![String]::IsNullOrEmpty($Variables)) {
				$vars = $Variables | ConvertFrom-JsonToHashtable
			}
			
			# Get the source path for the specified source
			$SourcePath = Get-SourcePath -Source $Source -CacheDir $CacheDir -Cookbook $cookbook -Type template

			# Build up the argument list to pass to the Patch Template so that it can be put in place
			# Patch the template file
			$splat = @{
				path = $SourcePath
				BeginTag = $BeginTag
				EndTag = $EndTag
				node = $attrs
				variables = $vars
			}
			$patched = _Patch-Template @splat

			# Write out the patched variable to the Destination file
			Write-Verbose ("Writing patched template: {0}" -f $Destination)
			
			# Ensure the parent path to the destination exists
			$parent = Split-Path -Path $Destination -Parent
			if (!(Test-Path -Path $Parent)) {
				Write-Verbose ("Creating parent directory for file")
				New-Item -Type Directory -Path $parent | Out-String
			}

			# Use the WriteAllText to write out the contents of the file, this is so that no carriage returns are
			# added to the end of thefile, as is the case with Set-Content
			[System.IO.File]::WriteAllText($Destination, $patched)

		}

		"Absent" {

			# The destination file exists, but it should not so remove it
			Remove-Item -Path $Destination -Force | Out-Null

		}
	}

	# Notify any services of this change
	# Set the DSC resource to reboot the machine if set
	if ($Reboot -eq $true) {
		$global:DSCMachineStatus = 1
	} else {
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
		$Attributes,

		[System.String]
		$Variables,

		[System.String]
		$CacheDir,

		[System.String[]]
		$Notifies,

		[System.String]
		$NotifiesServicePath,

		[System.String]
		$BeginTag = "[[",

		[System.String]
		$EndTag = "]]"
	)

	# Define test variable that will be used to return boolean for the test
	# By default this is set to 'true', e.g. assumes that everything is OK
	$test = $true

	# Use the Get-TargetResource to determine if the file exists
	$status = Get-TargetResource -Destination $Destination -Source $Source
	
	# Switch on the Ensure parameter
	switch ($Ensure) {

		"Present" {

			# Using the exported function from POSHChef turn the JSON object into a Hashtable for the
			# attributes and the variables
			$attrs = $Attributes | ConvertFrom-JsonToHashtable
			if (![String]::IsNullOrEmpty($Variables)) {
				$vars = $Variables | ConvertFrom-JsonToHashtable
			}

			# Get the source path for the specified source
			$SourcePath = Get-SourcePath -Source $Source -CacheDir $CacheDir -Cookbook $cookbook -Type template

			# Determine if the SourcePath exists
			if ($SourcePath -eq $false) {
				throw ("Source file does not exist: {0}" -f $SourcePath)
			} else {

				# Write out information to show the file that is being used as the template
				Write-Verbose ("Using template file: {0}" -f $SourcePath)

				# Does the destination file exist
				if ($Status.Ensure -ieq "present") {

					# Define a hashtable to hold the checksums for the files that are tested
					$checksum = @{
						patched = ""
						exisitng = ""
					}

					# As the file exists it needs to be compared against the patched version of the file
					# Patch the template file
					$splat = @{
						path = $SourcePath
						BeginTag = $BeginTag
						EndTag = $EndTag
						node = $attrs
						variables = $vars
					}
					$patched = _Patch-Template @splat

					# Get the checksum for the patched template
					Write-Verbose "Getting checksum for patched template"
					$checksum.patched = Get-Checksum -string $patched
					Write-Verbose $checksum.patched

					# Get the checksum for the existing file
					Write-Verbose ("Getting checksum for existing file: {0}" -f $Destination)
					$checksum.existing = Get-Checksum -path $Destination
					Write-Verbose $checksum.existing

					# Now perform a test on the checksums to determine if the file should be copied to the destination
					# Set the $test to false if they differ
					if ($checksum.patched -ne $checksum.existing) {
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


#### PRIVATE Functions
function _Patch-Template {

	<#

	.SYNOPSIS
		Patch the template file with the variables and node attributes

	#>

	[CmdletBinding()]
	param (

		[Parameter(Mandatory=$true)]
		[string]
		# Path to the template file
		$path,

		[Parameter(Mandatory=$true)]
		[string]
		# Tag in the text denoting the code to render
		$BeginTag,

		[Parameter(Mandatory=$true)]
		[string]
		# Tag in the text denoting the code to render
		$EndTag,

		[alias('attributes')]
		# Hashtable of attributes to be replaced in the file
		$node,

		# Hashtable of variables that have been specified 
		$variables
	)

	# Get the contents of the template file
	$template = Get-Content -Path $path

	# The begin and end tags may contain characters that have special meaning to RegEx
	# So ensure they are escaped
	$BeginTag = [Regex]::Escape($BeginTag)
	$EndTag = [Regex]::Escape($EndTag)

	# Ensure the output variable is empty
	$output = ""
	
	# Ensure each line of the template is terminated with a line feed
	$template | Foreach-Object { $text += [String] $_ + "`r"}

	# Iterate ariound the template looking for the patterns
	while ($text -match "(?m)(?<pre>.*?)$BeginTag(?<exp>.*?)$EndTag(?<post>.*)") { 
		$text = $matches.post
		$output += $matches.pre
		$output += (Invoke-Expression $matches.exp)
	}

	# Finish off the render and return the result to the calling function
	$output += $text
	$output -replace "`r", [Environment]::NewLine

}



