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


function Get-Notifications {

	<#

	.SYNOPSIS
	Analyses the notifications that have been set during the run

	.DESCRIPTION
	The function looks at the notifications area of POSHChef and determines whether any services need to
	restarted or if the server needs to be rebooted

	If any services are listed then they are restarted if they are already running

	#>

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	Write-Log -Message " "
	Write-Log -EventId PC_INFO_0033
	Write-Log -EventId PC_MISC_0001 -extra "Services"

	# Determine if the services.txt file exists in the notifications
	$notify_services_file = "{0}\services.txt" -f $Script:session.config.paths.notifications

	if (Test-Path -Path $notify_services_file) {
		
		# read in the contents of the file
		$notify_services = @(Get-Content -Path $notify_services_file)

		# Delete the file so that it can be created on the next run
		Remove-Item -Path $notify_services_file | Out-Null

		# Ensure that there is only one of each service
		# This mimics chef in that if a service is already scheduled to be notified then the others will be ignored
		$notify_services = $notify_services | Select -Unique

		foreach ($notify_service in $notify_services) {
			Write-Log -EventId PC_MISC_0002 -extra $notify_service

			# get the service
			$service = Get-Service -Name $notify_service -ErrorAction SilentlyContinue

			# if the service is not null, e.g. it valid check the status of it
			if (![String]::IsNullOrEmpty($service)) {
				if ($service.Status -ieq "running") {
					Write-Log -EventId PC_MISC_0003 -extra "restarting" 

					# only restart the service if the skip array does not contain notifications or notify
					if ([String]::IsNullOrEmpty($script:session.skip -match "notif[y|ies|ications]")) {
						Restart-Service -Name $service.name
					} else {
						Write-Log -EventId PC_INFO_0060
					}
				} else {
					Write-Log -EventId PC_MISC_0003 -extra "not running"
				}
			} else {
				Write-Log -EventId PC_INFO_0061
			}
		}
	} else {
		Write-Log -EventId PC_INFO_0034
	}
}
