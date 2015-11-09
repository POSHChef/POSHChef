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
        Pester tests file to test the CookbookFile Resource for DSC

    .DESCRIPTION
        The tests in this file will test to check that a file is written out if it:

        1. Does not exist
        2. Has been modified

        If the file has changed then it must set a notification on a named service

        The file can be removed

#>

# Source the necessary files
$TestsPath = $MyInvocation.MyCommand.Path
$script = (Split-Path -Leaf $TestsPath).Replace(".Tests.ps1", ".psm1")
$module = "{0}\{1}" -f (Split-Path -Parent -Path $TestsPath), $script
$code = Get-Content $module | Out-String
Invoke-Expression $code

# Mock functions that come from other modules
function Write-Log(){}
function Update-Session(){}
function Get-Configuration(){}
function Set-LogParameters(){}

# Ensure required functions are available
. "$PSScriptRoot\..\..\functions\exported\Get-CheckSum.ps1"
. "$PSScriptRoot\..\..\functions\exported\Get-SourcePath.ps1"
. "$PSScriptRoot\..\..\functions\exported\Set-Notification.ps1"

Describe "POSHChef_CookbookFileResource" {

  # Set the PSDrive, this is because .NET class methods do not understand the PSDrive notation so this
  # this needs to be passed as a valid file path
  $PSDriveName = "TestDrive"
  $PSDrive = Get-PSDrive $PSDriveName

  # Set the source and the destination
  $source = "{0}\licence.key" -f $PSDrive.Root
  $destination = "{0}\pester\licence.key" -f $PSDrive.Root

	$licence_data = @"
    Licenced Until: 01/01/1970
"@

  Set-Content -Path $source -Value $licence_data

	# Define a source file that will not exist
	$noexist = "{0}\updated.key" -f $PSDrive.Root

  # Set the name of a serice to restart
  $service_name = "MyApp"

  # Set the notificationsservicepath file
  $services_notifications_file = "{0}\service.txt" -f $PSDrive.Root

  Context "Source is a file" {

  	# Create the splat argument hash
    $splat = @{
      Ensure = "Present"
      Source = $source
      Destination = $destination
      Cookbook = "Pester"
  		Notifies = @($service_name)
  		NotifiesServicePath = $services_notifications_file
  		Reboot = $false
    }

    it "is created" {

        Set-TargetResource @splat

        Test-Path -Path $destination | Should Be $true

    }

		it "has the correct content" {

			# get the contents of the destination file for comparison
			$content = Get-Content -Path $Destination

			$licence_data -eq $content | Should Be $true

		}

		it ("sets a notification for the '{0}' service to be restarted" -f $service_name) {

			# Get the contents of the notifications file
			$services = (Get-Content -Path $services_notifications_file -Raw).Trim()

			$service_name -eq $services | Should be $true

		}

		it ("it copies the file, and a reboot is requested") {

			# set the flag to reboot the machine
			$splat.Reboot = $true

			# ensure the destination is removed
			Remove-Item -Path $destination -Force | Out-Null

			Set-TargetResource @splat

			$global:DSCMachineStatus -eq 1 | Should be $true

			# reset the reboot flag
			$global:DSCMachineStatus = 0
		}

		it "is overwritten if the source file changes" {

			# Set the new content for the original file
			$original = @"
Licenced Until: 01/01/2070
"@
			# Set the new content of the file
			[System.IO.File]::WriteAllText($source, $original)

			$splat.reboot = $false

			Set-TargetResource @splat

			# get the contents of the destination file for comparison
			$content = Get-Content -Path $Destination

			$original -eq $content | Should Be $true

		}

		it "file can be removed" {

            # Set the argument splat for the resource
            $splat.Ensure = "Absent"

            Set-TargetResource @splat

            Test-Path -Path $destination | Should Be $false

		}
  }

	Context "File does not exist, but neither does the source" {

		# Create the splat argument hash
        $splat = @{
            Ensure = "Present"
            Source = $noexist
            Destination = $destination
            Cookbook = "Pester"
			Notifies = @($service_name)
			NotifiesServicePath = $services_notifications_file
        }

		it "should throw error" {

			{ Test-TargetResource @splat } | Should throw

		}
	}
  
  Context "Source is a string" {
    
    $content = "This is a test"
    
    # Create the splat argument hash
    $splat = @{
      Ensure = "Present"
      Source = $content
      IsContent = $true
      WithBOM = $false
      Destination = $destination
      Cookbook = "Pester"
      Notifies = @($service_name)
      NotifiesServicePath = $services_notifications_file
      Reboot = $false
    }
    
    it "creates the desination file and has the correct content" {

        Set-TargetResource @splat

        Test-Path -Path $destination | Should Be $true
        
        # get the contents of the destination file for comparison
        $ondisk = Get-Content -Path $Destination
  
        $content -eq $ondisk | Should Be $true

    }
  }
}
